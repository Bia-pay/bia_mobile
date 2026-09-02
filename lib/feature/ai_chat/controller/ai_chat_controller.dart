import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:audioplayers/audioplayers.dart';

import '../../auth/data/api_data.dart';
import '../../dashboard/dashboardcontroller/dashboardcontroller.dart';
import '../../dashboard/model/bank_model.dart';
import '../../dashboard/model/data_model.dart';
import '../engine/beneficiary_resolver.dart';
import '../model/bia_strings.dart';
import '../model/chat_message.dart';
import '../service/eleven_labs_service.dart';
import '../service/llm_service.dart';
import '../service/ai_chat_persistence_service.dart';
import '../service/hausa_asr_service.dart';
import '../service/hausa_tts_service.dart';

// ── Conversation step ─────────────────────────────────────────────────────────
enum AiChatStep {
  idle,
  awaitingRecipientClarification,
  awaitingAccountNumber,
  awaitingBankAccountNumber,
  awaitingBankClarification,
  awaitingConfirmation,
}

// ── Pending transfer data ─────────────────────────────────────────────────────
class PendingTransfer {
  final String account;
  final String name;
  final double amount;
  final bool isBankTransfer;
  final String? bankCode;
  final String? bankName;

  const PendingTransfer({
    required this.account,
    required this.name,
    required this.amount,
    this.isBankTransfer = false,
    this.bankCode,
    this.bankName,
  });
}

// ── State ─────────────────────────────────────────────────────────────────────
class AiChatState {
  final List<ChatMessage> messages;
  final bool isProcessing;
  final AiChatStep step;
  final PendingTransfer? pending;
  final List<UnifiedContact> beneficiarySuggestions;
  final String selectedVoice;
  final String language;

  const AiChatState({
    this.messages = const [],
    this.isProcessing = false,
    this.step = AiChatStep.idle,
    this.pending,
    this.beneficiarySuggestions = const [],
    this.selectedVoice = 'V2D1qkaFj5NormT9yoaK', // Hoyeen (Nigerian)
    this.language = 'english',
  });

  AiChatState copyWith({
    List<ChatMessage>? messages,
    bool? isProcessing,
    AiChatStep? step,
    PendingTransfer? pending,
    bool clearPending = false,
    List<UnifiedContact>? beneficiarySuggestions,
    String? selectedVoice,
    String? language,
  }) {
    return AiChatState(
      messages: messages ?? this.messages,
      isProcessing: isProcessing ?? this.isProcessing,
      step: step ?? this.step,
      pending: clearPending ? null : (pending ?? this.pending),
      beneficiarySuggestions:
          beneficiarySuggestions ?? this.beneficiarySuggestions,
      selectedVoice: selectedVoice ?? this.selectedVoice,
      language: language ?? this.language,
    );
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────
final elevenLabsServiceProvider = Provider<ElevenLabsService>((ref) {
  const apiKey = String.fromEnvironment('ELEVEN_LABS_API_KEY');
  return ElevenLabsService(apiKey: apiKey);
});

final llmServiceProvider = Provider<LlmService>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return LlmService(apiClient: apiClient);
});


final aiChatPersistenceServiceProvider = Provider<AiChatPersistenceService>((ref) {
  return AiChatPersistenceService();
});

final hausaAsrServiceProvider = Provider<HausaAsrService>((ref) {
  return HausaAsrService();
});

final hausaTtsServiceProvider = Provider<HausaTtsService>((ref) {
  return HausaTtsService();
});

final aiChatControllerProvider =
    StateNotifierProvider<AiChatController, AiChatState>((ref) {
  final dashboardCtrl = ref.read(dashboardControllerProvider.notifier);
  final elevenLabsService = ref.read(elevenLabsServiceProvider);
  final llmService = ref.read(llmServiceProvider);
  final persistenceService = ref.read(aiChatPersistenceServiceProvider);
  final hausaAsrService = ref.read(hausaAsrServiceProvider);
  final hausaTtsService = ref.read(hausaTtsServiceProvider);
  return AiChatController(
    dashboardCtrl, 
    elevenLabsService, 
    llmService, 
    persistenceService,
    hausaAsrService,
    hausaTtsService
  );
});

// ── Controller ────────────────────────────────────────────────────────────────
class AiChatController extends StateNotifier<AiChatState> {
  final DashboardController _dashboard;
  final ElevenLabsService _elevenLabsService;
  final LlmService _llmService;
  final AiChatPersistenceService _persistence;
  final HausaAsrService _hausaAsrService;
  final HausaTtsService _hausaTtsService;
  final _resolver = BeneficiaryResolver();
  final AudioPlayer _audioPlayer = AudioPlayer();

  AiChatController(
    this._dashboard, 
    this._elevenLabsService, 
    this._llmService, 
    this._persistence,
    this._hausaAsrService,
    this._hausaTtsService,
  ) : super(const AiChatState()) {
    _init();
  }

  Future<void> _init() async {
    await _applyStoredLanguage();
  }

  Future<void> _applyStoredLanguage() async {
    try {
      final authBox = await Hive.openBox('authBox');
      final userId = authBox.get('userId')?.toString() ?? '';
      final phone = authBox.get('phone')?.toString() ?? '';
      final effectiveUserId = userId.isNotEmpty ? userId : phone;

      if (effectiveUserId.isNotEmpty) {
        // Load saved messages
        final messages = await _persistence.loadMessages(effectiveUserId);
        
        // Load saved language
        final lang = await _persistence.loadUserLanguage(effectiveUserId) ?? 'english';
        
        _llmService.updateLanguage(lang);
        state = state.copyWith(
          language: lang,
          messages: messages,
        );
      }
    } catch (_) {}
  }

  /// Explicitly initialize chat (called from UI when screen opens)
  Future<void> initializeChat() async {
    // 1. Ensure language is loaded
    await _applyStoredLanguage();
    
    // 2. If no messages, add welcome
    if (state.messages.isEmpty) {
      await _addWelcome();
    }
  }

  Future<void> updateLanguage(String language) async {
    final authBox = await Hive.openBox('authBox');
    final userId = authBox.get('userId')?.toString() ?? '';
    final phone = authBox.get('phone')?.toString() ?? '';
    final effectiveUserId = userId.isNotEmpty ? userId : phone;

    if (effectiveUserId.isNotEmpty) {
      await _persistence.saveUserLanguage(effectiveUserId, language);
      
      final box = await Hive.openBox('appPrefs');
      await box.put('biaAiLanguageSelected_$effectiveUserId', true);

      await _persistence.saveMessages(effectiveUserId, []);
    }

    _llmService.updateLanguage(language);
    
    state = state.copyWith(
      language: language,
      messages: [],
      step: AiChatStep.idle,
      clearPending: true,
    );

    await _addWelcome();
  }

  // Convenience getter
  String get _lang => state.language;

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  void setVoice(String voice) {
    state = state.copyWith(selectedVoice: voice);
  }

  Future<void> _playAudioBytes(List<int> bytes) async {
    try {
      // Determine file extension based on file header
      String ext = 'mp3';
      if (bytes.length > 4 &&
          bytes[0] == 0x52 && // R
          bytes[1] == 0x49 && // I
          bytes[2] == 0x46 && // F
          bytes[3] == 0x46) { // F
        ext = 'wav';
      }

      final dir = await Directory.systemTemp.createTemp();
      final file = File('${dir.path}/tts_temp.$ext');
      await file.writeAsBytes(bytes);
      await _audioPlayer.play(DeviceFileSource(file.path));
    } catch (e) {
      debugPrint('❌ Failed to play audio bytes via temp file: $e');
      // Fallback
      try {
        await _audioPlayer.play(BytesSource(Uint8List.fromList(bytes)));
      } catch (_) {}
    }
  }

  Future<void> _addWelcome() async {
    final aiMsg = await _llmService.sendContextualMessage(
      'The user has just opened the chat. Greet them warmly and tell them briefly what you can do '
      '(send money, check balance) in your chosen language personality.'
    );
    _addAssistant(aiMsg.chatResponse);
  }

  void _addUser(String text) {
    final updated = [
      ...state.messages,
      ChatMessage(role: MessageRole.user, text: text),
    ];
    state = state.copyWith(messages: updated);
    _persistState();
  }

  void _addAssistant(
    String text, {
    MessageType type = MessageType.text,
    Map<String, dynamic>? payload,
    bool playAudio = true,
  }) {
    final updated = [
      ...state.messages,
      ChatMessage(
        role: MessageRole.assistant,
        text: text,
        type: type,
        payload: payload,
      ),
    ];
    state = state.copyWith(messages: updated);
    _persistState();
  }

  Future<void> _persistState() async {
    try {
      final authBox = await Hive.openBox('authBox');
      final userId = authBox.get('userId')?.toString() ?? '';
      final phone = authBox.get('phone')?.toString() ?? '';
      final effectiveUserId = userId.isNotEmpty ? userId : phone;

      if (effectiveUserId.isNotEmpty) {
        await _persistence.saveMessages(effectiveUserId, state.messages);
      }
    } catch (_) {}
  }

  void _setProcessing(bool v) => state = state.copyWith(isProcessing: v);

  // ── Main entry point ─────────────────────────────────────────────────────

  Future<void> handleUserInput(BuildContext context, String input) async {
    final text = input.trim();
    if (text.isEmpty) return;

    _addUser(text);

    switch (state.step) {
      case AiChatStep.awaitingRecipientClarification:
        await _handleRecipientClarification(context, text);
        return;
      case AiChatStep.awaitingAccountNumber:
        await _handleTypedAccount(context, text);
        return;
      case AiChatStep.awaitingBankClarification:
        await _handleBankClarification(context, text);
        return;
      case AiChatStep.awaitingBankAccountNumber:
        await _handleBankAccountNumber(context, text);
        return;
      case AiChatStep.awaitingConfirmation:
        await _handleConfirmation(context, text);
        return;
      case AiChatStep.idle:
        break;
    }

    _setProcessing(true);
    
    // Call LLM
    final response = await _llmService.sendMessage(text);

    // Add assistant bubble first
    _addAssistant(
      response.chatResponse,
    );

    // Play base64 audio if present (shifted completely to backend)
    if (response.audioResponseBase64 != null && response.audioResponseBase64!.isNotEmpty) {
      try {
        final bytes = base64Decode(response.audioResponseBase64!);
        await _playAudioBytes(bytes);
      } catch (e) {
        debugPrint('❌ Failed to play base64 TTS audio: $e');
      }
    }

    // Route the intent action
    await _routeIntentAction(context, response);

    _setProcessing(false);
  }

  Future<void> processHausaAudio(BuildContext context, String filePath) async {
    await processAudio(context, filePath);
  }

  Future<void> processAudio(BuildContext context, String filePath) async {
    _setProcessing(true);
    
    // Send audio to unified AI Chat endpoint
    final response = await _llmService.sendVoiceMessage(filePath);
    
    // Add user message with transcription text if available
    if (response.transcribedText != null && response.transcribedText!.isNotEmpty) {
      _addUser(response.transcribedText!);
    } else {
      _addUser('[Voice Message]');
    }

    // Handle assistant response
    _addAssistant(
      response.chatResponse,
    );

    // Play base64 TTS response if available (shifted completely to backend)
    if (response.audioResponseBase64 != null && response.audioResponseBase64!.isNotEmpty) {
      try {
        final bytes = base64Decode(response.audioResponseBase64!);
        await _playAudioBytes(bytes);
      } catch (e) {
        debugPrint('❌ Failed to play base64 TTS audio: $e');
      }
    }

    // Route intent actions
    await _routeIntentAction(context, response);

    _setProcessing(false);
  }

  Future<void> _routeIntentAction(BuildContext context, LlmParsedResponse response) async {
    final action = response.intent;
    final details = response.details;

    switch (action) {
      case 'TRANSFER':
        await _handleIntentTransfer(context, details, response.chatResponse);
        break;
      case 'AIRTIME':
        await _handleIntentAirtime(context, details, response.chatResponse);
        break;
      case 'DATA':
        await _handleIntentData(context, details, response.chatResponse);
        break;
      case 'CABLE_TV':
        await _handleIntentCableTv(context, details, response.chatResponse);
        break;
      case 'ELECTRICITY':
        await _handleIntentElectricity(context, details, response.chatResponse);
        break;
      case 'NONE':
      default:
        state = state.copyWith(step: AiChatStep.idle);
        break;
    }
  }

  Future<void> _handleIntentTransfer(
      BuildContext context, Map<String, dynamic> details, String chatResponse) async {
    final amountVal = details['amount'];
    final double? amount = amountVal != null ? double.tryParse(amountVal.toString()) : null;
    final String? recipient = details['accountNumber']?.toString() ?? details['recipient']?.toString();
    final String? bankName = details['bankName']?.toString();

    // Check if details are sufficient. If not, the backend chatResponse has already requested them.
    if (amount == null || amount <= 0 || recipient == null || recipient.isEmpty) {
      return;
    }

    if (bankName != null && bankName.isNotEmpty) {
      // It is a bank transfer request
      await _processBankTransferRequest(context, bankName, recipient, amount);
    } else {
      // It is a BIA-to-BIA transfer request
      final biaBens = await _dashboard.getRecentBeneficiary(context);
      final unified = <UnifiedContact>[];
      for (final b in biaBens) {
        unified.add(UnifiedContact(name: b.fullname, account: b.phone));
      }
      
      final matches = _resolver.resolve(recipient, unified);

      if (matches.isEmpty) {
        state = state.copyWith(
          step: AiChatStep.awaitingAccountNumber,
          pending: PendingTransfer(
            account: '',
            name: recipient,
            amount: amount,
          ),
        );
        final aiMsg = await _llmService.sendContextualMessage(
          'I could not find "$recipient" in the contact list. Ask the user to provide the 10-digit account number.'
        );
        _addAssistant(aiMsg.chatResponse, playAudio: true);
      } else if (matches.length > 1) {
        state = state.copyWith(
          step: AiChatStep.awaitingRecipientClarification,
          pending: PendingTransfer(
            account: '',
            name: recipient,
            amount: amount,
          ),
        );
        final aiMsg = await _llmService.sendContextualMessage(
          'I found multiple people with the name "$recipient". Ask the user to choose the correct one from the suggestions.'
        );
        _addAssistant(
          aiMsg.chatResponse,
          type: MessageType.suggestionChips,
          playAudio: true,
          payload: {
            'suggestions': matches
                .take(5)
                .map((b) => {
                    'name': b.name, 
                    'account': b.account,
                    'isBankTransfer': b.isBankTransfer,
                    'bankCode': b.bankCode,
                  })
                .toList(),
          },
        );
      } else {
        final b = matches.first;
        await _showConfirmCard(
          context,
          name: b.name,
          account: b.account,
          amount: amount,
        );
      }
    }
  }

  Future<void> _handleIntentAirtime(
      BuildContext context, Map<String, dynamic> details, String chatResponse) async {
    final String? phoneNumber = details['phoneNumber']?.toString();
    final amountVal = details['amount'];
    final double? amount = amountVal != null ? double.tryParse(amountVal.toString()) : null;
    final String? network = details['network']?.toString();

    if (phoneNumber == null || phoneNumber.isEmpty || amount == null || amount <= 0) {
      return;
    }

    final resolvedNetwork = network ?? 'MTN';

    state = state.copyWith(
      step: AiChatStep.awaitingConfirmation,
      pending: PendingTransfer(
        account: phoneNumber,
        name: resolvedNetwork.toUpperCase(),
        amount: amount,
      ),
    );

    double feeAmount = 0.0;
    try {
      final charges = await _dashboard.getTransactionCharges(
        context,
        amount: amount,
        transactionType: "DEBIT",
        serviceType: "AIRTIME",
      );
      if (charges != null) {
        feeAmount = (charges['charge'] ?? 0).toDouble();
      }
    } catch (_) {}

    _addAssistant(
      'Everything is set for your airtime purchase. Please confirm the details below to proceed.',
      type: MessageType.confirmCard,
      playAudio: false,
      payload: {
        'name': '$resolvedNetwork Airtime',
        'account': phoneNumber,
        'amount': amount,
        'fee': feeAmount,
        'isBankTransfer': false,
        'destinationType': 'Airtime Top-up',
        'type': 'airtime',
        'meta': {
          'network': resolvedNetwork.toLowerCase(),
        },
      },
    );
  }

  Future<void> _handleIntentData(
      BuildContext context, Map<String, dynamic> details, String chatResponse) async {
    final String? phoneNumber = details['phoneNumber']?.toString();
    final String? dataPlan = details['dataPlan']?.toString();
    final String? network = details['network']?.toString();

    if (phoneNumber == null || phoneNumber.isEmpty || dataPlan == null || dataPlan.isEmpty) {
      return;
    }

    final resolvedNetwork = network ?? 'MTN';
    final serviceId = '${resolvedNetwork.toLowerCase()}-data';

    List<DataPlanModel> plans = [];
    try {
      plans = await _dashboard.fetchDataPlans(context, serviceId, showLoading: false);
    } catch (_) {}

    DataPlanModel? matchedPlan;
    for (final plan in plans) {
      if (plan.name.toLowerCase().contains(dataPlan.toLowerCase()) ||
          (plan.variationCode?.toLowerCase().contains(dataPlan.toLowerCase()) ?? false)) {
        matchedPlan = plan;
        break;
      }
    }

    if (matchedPlan == null && plans.isNotEmpty) {
      matchedPlan = plans.firstWhere(
        (p) => p.name.toLowerCase().contains(dataPlan.split(' ').first.toLowerCase()),
        orElse: () => plans.first,
      );
    }

    if (matchedPlan == null) {
      _addAssistant('I could not resolve a data plan matching "$dataPlan" for $resolvedNetwork. Please try again.');
      return;
    }

    final double amount = matchedPlan.amount.toDouble();

    state = state.copyWith(
      step: AiChatStep.awaitingConfirmation,
      pending: PendingTransfer(
        account: phoneNumber,
        name: matchedPlan.name,
        amount: amount,
      ),
    );

    _addAssistant(
      'Please confirm the data purchase details below to proceed.',
      type: MessageType.confirmCard,
      playAudio: false,
      payload: {
        'name': matchedPlan.name,
        'account': phoneNumber,
        'amount': amount,
        'fee': 0.0,
        'isBankTransfer': false,
        'destinationType': 'Data Purchase',
        'type': 'data',
        'meta': {
          'serviceId': serviceId,
          'variationCode': matchedPlan.variationCode,
        },
      },
    );
  }

  Future<void> _handleIntentCableTv(
      BuildContext context, Map<String, dynamic> details, String chatResponse) async {
    final String? smartcardNumber = details['smartcardNumber']?.toString();
    final String? biller = details['biller']?.toString();
    final String? dataPlan = details['dataPlan']?.toString();
    final amountVal = details['amount'];
    final double? amount = amountVal != null ? double.tryParse(amountVal.toString()) : null;

    if (smartcardNumber == null || smartcardNumber.isEmpty || biller == null || biller.isEmpty) {
      return;
    }

    final serviceId = biller.toLowerCase().trim();

    state = state.copyWith(
      step: AiChatStep.awaitingConfirmation,
      pending: PendingTransfer(
        account: smartcardNumber,
        name: biller.toUpperCase(),
        amount: amount ?? 0.0,
      ),
    );

    _addAssistant(
      'Please confirm the Cable TV subscription details below.',
      type: MessageType.confirmCard,
      playAudio: false,
      payload: {
        'name': '${biller.toUpperCase()} Subscription',
        'account': smartcardNumber,
        'amount': amount ?? 0.0,
        'fee': 0.0,
        'isBankTransfer': false,
        'destinationType': 'Cable TV',
        'type': 'cable',
        'meta': {
          'serviceId': serviceId,
          'variationCode': dataPlan ?? '',
          'packageName': dataPlan ?? '',
        },
      },
    );
  }

  Future<void> _handleIntentElectricity(
      BuildContext context, Map<String, dynamic> details, String chatResponse) async {
    final String? meterNumber = details['meterNumber']?.toString();
    final String? biller = details['biller']?.toString();
    final amountVal = details['amount'];
    final double? amount = amountVal != null ? double.tryParse(amountVal.toString()) : null;

    if (meterNumber == null || meterNumber.isEmpty || biller == null || biller.isEmpty || amount == null || amount <= 0) {
      return;
    }

    final serviceId = biller.toLowerCase().replaceAll(' ', '-').trim();

    state = state.copyWith(
      step: AiChatStep.awaitingConfirmation,
      pending: PendingTransfer(
        account: meterNumber,
        name: biller.toUpperCase(),
        amount: amount,
      ),
    );

    _addAssistant(
      'Please confirm the electricity unit purchase details below.',
      type: MessageType.confirmCard,
      playAudio: false,
      payload: {
        'name': '${biller.toUpperCase()} Meter',
        'account': meterNumber,
        'amount': amount,
        'fee': 0.0,
        'isBankTransfer': false,
        'destinationType': 'Electricity Bill',
        'type': 'electricity',
        'meta': {
          'serviceId': serviceId,
          'variationCode': 'prepaid',
        },
      },
    );
  }



  // ── Intent handlers ───────────────────────────────────────────────────────

  Future<void> _handleCheckBalance(String llmMessage) async {
    try {
      final box = Hive.box('authBox');
      final balance = box.get('balance', defaultValue: '0').toString();
      final formatted = balance.replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
      
      // We can append the LLM's conversational text to our actual verified data
      _addAssistant('$llmMessage\n\n💰 Your BIA wallet balance is ₦$formatted.');
    } catch (_) {
      final aiMsg = await _llmService.sendContextualMessage('An error occurred while fetching the wallet balance. Apologize and explain the network issue.');
      _addAssistant(aiMsg.chatResponse);
    }
  }

  Future<void> _handleSendMoney(
      BuildContext context, LlmParsedResponse response) async {
    
    // Play LLM text first for rich conversational feel!
    if (response.chatResponse.isNotEmpty && response.chatResponse != '...') {
       _addAssistant(response.chatResponse);
    }

    if (response.amount == null || response.amount! <= 0) {
      return; // LLM should have already requested it in chatResponse
    }
    
    final recipientStr = response.recipient;
    if (recipientStr == null || recipientStr.isEmpty) {
      return; // LLM should have requested inside chatResponse
    }

    final biaBens = await _dashboard.getRecentBeneficiary(context);
    final bankBens = await _dashboard.getBankBeneficiaries(context);

    final unified = <UnifiedContact>[];
    for (final b in biaBens) {
      unified.add(UnifiedContact(name: b.fullname, account: b.phone));
    }
    for (final m in bankBens) {
      unified.add(UnifiedContact(
        name: m['name']?.toString() ?? '', 
        account: m['account']?.toString() ?? '', 
        bankCode: m['bankCode']?.toString() ?? '',
      ));
    }

    final matches = _resolver.resolve(recipientStr, unified);

    if (matches.isEmpty) {
      state = state.copyWith(
        step: AiChatStep.awaitingAccountNumber,
        pending: PendingTransfer(
          account: '',
          name: recipientStr,
          amount: response.amount!,
        ),
      );
      final aiMsg = await _llmService.sendContextualMessage('I could not find "$recipientStr" in the contact list. Ask the user to provide the 10-digit account number.');
      _addAssistant(aiMsg.chatResponse, playAudio: true);
      return;
    }

    if (matches.length > 1) {
      state = state.copyWith(
        step: AiChatStep.awaitingRecipientClarification,
        pending: PendingTransfer(
          account: '',
          name: recipientStr,
          amount: response.amount!,
        ),
      );
      final aiMsg = await _llmService.sendContextualMessage('I found multiple people with the name "$recipientStr". Ask the user to choose the correct one from the suggestions I will provide.');
      _addAssistant(
        aiMsg.chatResponse,
        type: MessageType.suggestionChips,
        playAudio: true,
        payload: {
          'suggestions': matches
              .take(5)
              .map((b) => {
                  'name': b.name, 
                  'account': b.account,
                  'isBankTransfer': b.isBankTransfer,
                  'bankCode': b.bankCode,
                })
              .toList(),
        },
      );
    } else if (matches.length == 1) {
      final b = matches.first;
      if (b.isBankTransfer) {
         final banks = await _dashboard.getBanks(context);
         final bankName = banks.firstWhere((e) => e.bankCode == b.bankCode, orElse: () => banks.first).bankName;
         
         await _showConfirmCard(
            context, 
            name: b.name, 
            account: b.account, 
            amount: response.amount!,
            isBankTransfer: true,
            destinationType: "Transfer to $bankName",
            bankCode: b.bankCode,
            bankName: bankName,
         );
      } else {
         await _showConfirmCard(context, name: b.name, account: b.account, amount: response.amount!);
      }
    }
  }

  Future<void> _handleSendMoneyToBank(
      BuildContext context, LlmParsedResponse response) async {
    
    if (response.chatResponse.isNotEmpty && response.chatResponse != '...') {
       _addAssistant(response.chatResponse);
    }

    if (response.amount == null || response.amount! <= 0) return;
    
    final destBankName = response.destinationBank ?? '';
    final recipientStr = response.recipient ?? '';

    // No bank mentioned?
    if (destBankName.isEmpty) {
      final aiMsg = await _llmService.sendContextualMessage('The user wants to send ₦${response.amount} to a bank, but did not specify which bank. Ask for the bank name.');
      _addAssistant(aiMsg.chatResponse, playAudio: true);
      state = state.copyWith(
        step: AiChatStep.awaitingBankClarification,
        pending: PendingTransfer(
          account: RegExp(r'^\d{10}$').hasMatch(recipientStr) ? recipientStr : '',
          name: recipientStr,
          amount: response.amount!,
          isBankTransfer: true,
        ),
      );
      return;
    }

    await _processBankTransferRequest(context, destBankName, recipientStr, response.amount!);
  }

  Future<void> _processBankTransferRequest(BuildContext context, String bankInput, String accountInput, double amount) async {
    // Try resolving bank
    final banks = await _dashboard.getBanks(context);
    if (banks.isEmpty) {
      final aiMsg = await _llmService.sendContextualMessage('Network error while trying to load the list of banks. Tell the user we cannot proceed right now.');
      _addAssistant(aiMsg.chatResponse, playAudio: true);
      return;
    }

    // Fuzzy matcher
    BankModel? matchedBank;
    final tName = bankInput.toLowerCase().trim();
    for (final b in banks) {
      if (b.bankName.toLowerCase().contains(tName) || tName.contains(b.bankCode.toLowerCase())) {
        matchedBank = b;
        break;
      }
    }
    
    // Fallbacks
    if (matchedBank == null) {
      if (tName.contains('gtb') || tName.contains('guaranty')) {
        matchedBank = banks.firstWhere((e) => e.bankName.toLowerCase().contains('guaranty'), orElse: () => banks.first);
      } else if (tName.contains('uba')) {
        matchedBank = banks.firstWhere((e) => e.bankName.toLowerCase().contains('united'), orElse: () => banks.first);
      }
    }

    if (matchedBank == null) {
      final aiMsg = await _llmService.sendContextualMessage('I could not find a bank named "$bankInput". Ask the user to provide the exact name of the bank.');
      _addAssistant(aiMsg.chatResponse, playAudio: true);
      state = state.copyWith(
        step: AiChatStep.awaitingBankClarification,
        pending: PendingTransfer(
          account: RegExp(r'^\d{10}$').hasMatch(accountInput) ? accountInput : '',
          name: accountInput,
          amount: amount,
          isBankTransfer: true,
        ),
      );
      return;
    }

    if (!RegExp(r'^\d{10}$').hasMatch(accountInput)) {
      final aiMsg = await _llmService.sendContextualMessage('The user is sending to ${matchedBank.bankName}. Ask for the 10-digit account number.');
      _addAssistant(aiMsg.chatResponse, playAudio: true);
      state = state.copyWith(
        step: AiChatStep.awaitingBankAccountNumber,
        pending: PendingTransfer(
          account: '',
          name: '',
          amount: amount,
          isBankTransfer: true,
          bankCode: matchedBank.bankCode,
          bankName: matchedBank.bankName,
        ),
      );
      return;
    }

    await _verifyAndShowBankConfirmCard(context, 
      account: accountInput.trim(), 
      amount: amount, 
      bankCode: matchedBank.bankCode, 
      bankName: matchedBank.bankName
    );
  }

  Future<void> _handleBankClarification(BuildContext context, String input) async {
    _setProcessing(true);
    final p = state.pending!;
    await _processBankTransferRequest(context, input, p.account, p.amount);
    _setProcessing(false);
  }

  Future<void> _handleBankAccountNumber(BuildContext context, String input) async {
    _setProcessing(true);
    final account = input.replaceAll(RegExp(r'\s'), '');
    if (!RegExp(r'^\d{10}$').hasMatch(account)) {
      final aiMsg = await _llmService.sendContextualMessage('The account number provided is not exactly 10 digits. Ask the user for a valid 10-digit account number.');
      _addAssistant(aiMsg.chatResponse, playAudio: true);
      _setProcessing(false);
      return;
    }

    final p = state.pending!;
    await _verifyAndShowBankConfirmCard(context, 
      account: account, 
      amount: p.amount, 
      bankCode: p.bankCode!, 
      bankName: p.bankName!
    );
    _setProcessing(false);
  }

  Future<void> _verifyAndShowBankConfirmCard(BuildContext context, {required String account, required double amount, required String bankCode, required String bankName}) async {
    final aiMsg = await _llmService.sendContextualMessage('Tell the user you are verifying the account $account for $bankName.');
    _addAssistant(aiMsg.chatResponse, playAudio: true);

    final result = await _dashboard.verifyBankAccount(context, accountNumber: account, bankCode: bankCode, bankName: bankName);

    if (result?.responseSuccessful == true && result?.responseBody != null) {
      final name = result!.responseBody!.accountName ?? 'Unknown User';
      final destinationLabel = BiaStrings.transferToBankLabel(_lang, bankName);
      await _showConfirmCard(
        context,
        name: name,
        account: account,
        amount: amount,
        isBankTransfer: true,
        destinationType: destinationLabel,
        bankCode: bankCode,
        bankName: bankName,
      );
    } else {
      final aiMsg = await _llmService.sendContextualMessage('Could not verify that account for $bankName. Ask the user to confirm the number.');
      _addAssistant(aiMsg.chatResponse, playAudio: true);
      state = state.copyWith(step: AiChatStep.awaitingBankAccountNumber);
    }
  }

  Future<void> _showConfirmCard(
    BuildContext context, {
    required String name,
    required String account,
    required double amount,
    bool isBankTransfer = false,
    String destinationType = "BIA to BIA",
    String? bankCode,
    String? bankName,
  }) async {
    double feeAmount = 0.0;
    try {
      final charges = await _dashboard.getTransactionCharges(
        context,
        amount: amount,
        transactionType: "DEBIT",
        serviceType: "TRANSFER",
      );
      if (charges != null) {
        feeAmount = (charges['charge'] ?? 0).toDouble();
      }
    } catch (_) {}

    state = state.copyWith(
      step: AiChatStep.awaitingConfirmation,
      pending: PendingTransfer(account: account, name: name, amount: amount),
    );
    final aiMsg = await _llmService.sendContextualMessage('The transfer details are ready. Tell the user everything is set and ask them to confirm the transaction below.');
    _addAssistant(
      aiMsg.chatResponse,
      type: MessageType.confirmCard,
      playAudio: false,
      payload: {
        'name': name,
        'account': account,
        'amount': amount,
        'fee': feeAmount,
        'isBankTransfer': isBankTransfer,
        'destinationType': destinationType,
        'bankCode': bankCode,
        'bankName': bankName,
      },
    );
  }

  // ── Step handlers ─────────────────────────────────────────────────────────

  Future<void> _handleRecipientClarification(
      BuildContext context, String input) async {
    _setProcessing(true);
    final matches = _resolver.resolve(input.trim(), state.beneficiarySuggestions);
    if (matches.isEmpty) {
      await _handleTypedAccount(context, input.trim());
    } else {
      final b = matches.first;
      if (b.isBankTransfer) {
         final banks = await _dashboard.getBanks(context);
         final bankName = banks.firstWhere((e) => e.bankCode == b.bankCode, orElse: () => banks.first).bankName;
         
         await _showConfirmCard(
            context, 
            name: b.name, 
            account: b.account, 
            amount: state.pending!.amount,
            isBankTransfer: true,
            destinationType: "Transfer to $bankName",
            bankCode: b.bankCode,
            bankName: bankName,
         );
      } else {
        await _showConfirmCard(
          context,
          name: b.name,
          account: b.account,
          amount: state.pending!.amount,
        );
      }
    }
    _setProcessing(false);
  }

  Future<void> _handleTypedAccount(BuildContext context, String input) async {
    _setProcessing(true);
    final account = input.replaceAll(RegExp(r'\s'), '');

    if (!RegExp(r'^\d{10}$').hasMatch(account)) {
      final aiMsg = await _llmService.sendContextualMessage('The account number provided is invalid. Ask for a valid 10-digit account number.');
      _addAssistant(aiMsg.chatResponse, playAudio: true);
      _setProcessing(false);
      return;
    }

    final aiMsg = await _llmService.sendContextualMessage('Tell the user you are verifying the account number $account.');
    _addAssistant(aiMsg.chatResponse, playAudio: true);

    try {
      if (!context.mounted) return;
      final result = await _dashboard.verifyAccount(context, account);

      if (result?.responseSuccessful == true && result?.responseBody != null) {
        final name =
            result!.responseBody!.user?.fullname ?? 'Unknown User';
        await _showConfirmCard(
          context,
          name: name,
          account: account,
          amount: state.pending!.amount,
        );
      } else {
        final aiMsg = await _llmService.sendContextualMessage('The account number was not found. Ask the user to double check and try again.');
        _addAssistant(aiMsg.chatResponse, playAudio: true);
        state = state.copyWith(step: AiChatStep.awaitingAccountNumber);
      }
    } catch (_) {
      final aiMsg = await _llmService.sendContextualMessage('An error occurred during account verification. Apologize and ask to try again.');
      _addAssistant(aiMsg.chatResponse, playAudio: true);
      state = state.copyWith(step: AiChatStep.awaitingAccountNumber);
    }

    _setProcessing(false);
  }

  Future<void> _handleConfirmation(BuildContext context, String input) async {
    final lower = input.trim().toLowerCase();

    if (['no', 'cancel', 'stop', 'nope', "a'a"].any(lower.contains)) {
      await cancelTransfer();
      return;
    }

    if (['yes', 'confirm', 'ok', 'go', 'send', 'proceed', 'oya', 'ee']
        .any(lower.contains)) {
      await confirmTransfer(context);
      return;
    }

    final aiMsg = await _llmService.sendContextualMessage('The user gave an ambiguous answer. Ask them clearly to reply "Yes" to confirm or "No" to cancel.');
    _addAssistant(aiMsg.chatResponse, playAudio: true);
  }

  // ── Public actions called from UI ─────────────────────────────────────────

  Future<void> confirmTransfer(BuildContext context) async {
    final p = state.pending;
    if (p == null) return;

    _markLastConfirmCardCompleted();
    state = state.copyWith(step: AiChatStep.idle, clearPending: true);
    final aiMsg = await _llmService.sendContextualMessage('The transfer is confirmed. Tell the user you are opening the PIN screen and will be right here.');
    _addAssistant(aiMsg.chatResponse, playAudio: true);
  }

  Future<void> cancelTransfer() async {
    _markLastConfirmCardCompleted();
    state = state.copyWith(step: AiChatStep.idle, clearPending: true);
    final aiMsg = await _llmService.sendContextualMessage('The transaction has been cancelled. Ask the user if there is anything else I can help with.');
    _addAssistant(aiMsg.chatResponse, playAudio: true);
  }

  void _markLastConfirmCardCompleted() {
    final messages = List<ChatMessage>.from(state.messages);
    for (int i = messages.length - 1; i >= 0; i--) {
      if (messages[i].type == MessageType.confirmCard) {
        final payload = Map<String, dynamic>.from(messages[i].payload ?? {});
        payload['isCompleted'] = true;
        messages[i] = messages[i].copyWith(payload: payload);
        break;
      }
    }
    state = state.copyWith(messages: messages);
    _persistState();
  }

  Future<void> selectSuggestion(
      BuildContext context, Map<String, dynamic> suggestion) async {
    final account = suggestion['account']?.toString() ?? '';
    final name = suggestion['name']?.toString() ?? '';
    final isBankTransfer = suggestion['isBankTransfer'] == true;
    final bankCode = suggestion['bankCode']?.toString();

    _addUser(name);
    _setProcessing(true);

    if (isBankTransfer && bankCode != null) {
      final banks = await _dashboard.getBanks(context);
      final bankName = banks.firstWhere((e) => e.bankCode == bankCode, orElse: () => banks.first).bankName;
      
      final destinationLabel = BiaStrings.transferToBankLabel(_lang, bankName);
      await _showConfirmCard(
        context,
        name: name,
        account: account,
        amount: state.pending?.amount ?? 0,
        isBankTransfer: true,
        destinationType: destinationLabel,
        bankCode: bankCode,
        bankName: bankName,
      );
    } else {
      await _showConfirmCard(
        context,
        name: name,
        account: account,
        amount: state.pending?.amount ?? 0,
      );
    }
    
    _setProcessing(false);
  }
}
