import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../../../app/utils/colors.dart';
import '../../../../feature/dashboard/pages/send_money/input_transfer/transaction_pin.dart';
import '../../../../feature/dashboard/pages/send_money/to_bank/bank_transaction_pin.dart';
import '../controller/ai_chat_controller.dart';
import '../model/chat_message.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/confirm_card.dart';
import 'widgets/suggestion_chip_row.dart';

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode = FocusNode();

  late stt.SpeechToText _speech;
  late AudioRecorder _recorder; 
  bool _isListening = false;
  bool _hasSpeechInit = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _recorder = AudioRecorder();
    _initSpeech();
    
    // Initialize chat (loads language and adds welcome message)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(aiChatControllerProvider.notifier).initializeChat();
    });
    
    _textCtrl.addListener(() {
      setState(() {});
    });
  }

  void _initSpeech() async {
    _hasSpeechInit = await _speech.initialize(
      onError: (e) => print('STT Error: $e'),
      onStatus: (s) {
        if (s == 'notListening' || s == 'done') {
          if (mounted) setState(() => _isListening = false);
        }
      },
    );
    if (mounted) setState(() {});
  }

  void _toggleListening() async {
    final language = ref.read(aiChatControllerProvider).language;
    
    if (language == 'hausa') {
      await _toggleHausaListening();
      return;
    }

    if (!_hasSpeechInit) {
      _hasSpeechInit = await _speech.initialize();
      if (!_hasSpeechInit) return;
    }

    if (_isListening) {
      setState(() => _isListening = false);
      await _speech.stop();
    } else {
      setState(() => _isListening = true);
      await _speech.listen(
        onResult: (val) {
          if (!mounted) return;
          setState(() {
            _textCtrl.text = val.recognizedWords;
            _textCtrl.selection = TextSelection.fromPosition(
                TextPosition(offset: _textCtrl.text.length));
            if (val.finalResult) {
              _isListening = false;
            }
          });
        },
        listenMode: stt.ListenMode.dictation,
      );
    }
  }

  Future<void> _toggleHausaListening() async {
    if (_isListening) {
      setState(() => _isListening = false);
      final path = await _recorder.stop();
      if (path != null) {
        if (!mounted) return;
        _scrollToBottom();
        await ref.read(aiChatControllerProvider.notifier).processHausaAudio(context, path);
      }
    } else {
      if (await _recorder.hasPermission()) {
        final tempDir = await getTemporaryDirectory();
        final path = p.join(tempDir.path, 'hausa_speech_${DateTime.now().millisecondsSinceEpoch}.wav');
        
        const config = RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        );

        await _recorder.start(config, path: path);
        setState(() => _isListening = true);
      }
    }
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    _recorder.dispose(); // Add this
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    _textCtrl.clear();
    _focusNode.requestFocus();

    await ref
        .read(aiChatControllerProvider.notifier)
        .handleUserInput(context, text);

    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final aiState = ref.watch(aiChatControllerProvider);
    final theme = Theme.of(context);

    ref.listen(aiChatControllerProvider, (_, __) => _scrollToBottom());

    return Scaffold(
      backgroundColor: accentColor, // Deep rich navy background
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Glassmorphic
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF26B4DF), Color(0xFF1E90B2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(Icons.auto_awesome,
                  color: Colors.white, size: 18.sp),
            ),
            SizedBox(width: 12.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BIA AI',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16.sp,
                    letterSpacing: 0.2,
                  ),
                ),
                Text(
                  aiState.isProcessing ? 'Typing...' : 'Your Banking Assistant',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.record_voice_over, color: Colors.white, size: 20.sp),
            tooltip: 'Select Voice',
            onSelected: (voiceId) {
              ref.read(aiChatControllerProvider.notifier).setVoice(voiceId);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Voice updated successfully!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'V2D1qkaFj5NormT9yoaK', child: Text('Paulina (Nigerian)')),
              PopupMenuItem(value: 'it5NMxoQQ2INIh4XcO44', child: Text('Fisayo (Nigerian)')),
              PopupMenuItem(value: 'V2D1qkaFj5NormT9yoaK', child: Text('Hoyeen (Nigerian)')),
              PopupMenuItem(value: 'pNInz6obpgDQGcFmaJgB', child: Text('Adam (Backup)')),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollCtrl,
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  itemCount:
                      aiState.messages.length + (aiState.isProcessing ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (aiState.isProcessing &&
                        index == aiState.messages.length) {
                      return const TypingIndicator();
                    }

                    final msg = aiState.messages[index];

                    if (msg.role == MessageRole.assistant &&
                        msg.type == MessageType.confirmCard &&
                        msg.payload != null) {
                      return _buildConfirmCard(msg, aiState);
                    }

                    if (msg.role == MessageRole.assistant &&
                        msg.type == MessageType.suggestionChips &&
                        msg.payload != null) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ChatBubble(message: msg),
                          _buildSuggestionChips(msg.payload!),
                        ],
                      );
                    }

                    return ChatBubble(message: msg);
                  },
                ),
              ),
              Container(
                margin: EdgeInsets.only(
                  left: 16.w,
                  right: 16.w,
                  bottom: 16.h,
                  top: 8.h,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(30.r),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30.r),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 8.h,
                      ),
                      child: Row(
                        children: [
                          SizedBox(width: 12.w),
                          Expanded(
                            child: TextField(
                              controller: _textCtrl,
                              focusNode: _focusNode,
                              textCapitalization: TextCapitalization.sentences,
                              minLines: 1,
                              maxLines: 4,
                              onSubmitted: (_) => _send(),
                              decoration: InputDecoration(
                                hintText: _isListening
                                    ? 'Listening...'
                                    : 'Type your message...',
                                hintStyle: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w400,
                                ),
                                filled: false,
                                contentPadding: EdgeInsets.zero,
                                border: InputBorder.none,
                              ),
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                              cursorColor: primaryColor,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          _buildSendOrMicButton(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSendOrMicButton() {
    final hasText = _textCtrl.text.trim().isNotEmpty;

    if (hasText && !_isListening) {
      return GestureDetector(
        onTap: _send,
        child: Container(
          width: 44.w,
          height: 44.w,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF26B4DF), Color(0xFF1E90B2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Icon(
            Icons.send_rounded,
            color: Colors.white,
            size: 20.sp,
          ),
        ),
      );
    } else {
      return GestureDetector(
        onTap: _toggleListening,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 44.w,
          height: 44.w,
          decoration: BoxDecoration(
            color: _isListening ? Colors.redAccent : Colors.white.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
               color: _isListening ? Colors.transparent : Colors.white.withValues(alpha: 0.2),
               width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _isListening
                    ? Colors.redAccent.withValues(alpha: 0.4)
                    : Colors.transparent,
                blurRadius: _isListening ? 10 : 0,
                spreadRadius: _isListening ? 2 : 0,
              )
            ],
          ),
          child: Icon(
            _isListening ? Icons.mic : Icons.mic_none,
            color: Colors.white,
            size: 20.sp,
          ),
        ),
      );
    }
  }

  Widget _buildModalOverlay(ChatMessage msg) {
    final p = msg.payload!;
    final name = (p['name'] as String?) ?? '';
    final account = (p['account'] as String?) ?? '';
    final amount = ((p['amount'] as num?) ?? 0).toDouble();
    final fee = ((p['fee'] as num?) ?? 0).toDouble();
    final destinationType = p['destinationType'] as String?;
    final isBankTransfer = (p['isBankTransfer'] as bool?) ?? false;
    final bankCode = p['bankCode'] as String?;
    final bankName = p['bankName'] as String?;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      builder: (context, value, child) {
        return GestureDetector(
          onTap: () {}, // Prevent tap through
          child: Container(
            color: Colors.black.withValues(alpha: 0.6 * value),
            child: Center(
              child: Transform.scale(
                scale: 0.8 + (0.2 * value),
                child: Opacity(
                  opacity: value,
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 24.w),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 50,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: ConfirmCard(
                      name: name,
                      account: account,
                      amount: amount,
                      fee: fee,
                      isCompleted: false,
                      destinationType: destinationType,
                      onConfirm: () => _onConfirmTapped(
                        account: account,
                        name: name,
                        amount: amount,
                        isBankTransfer: isBankTransfer,
                        bankCode: bankCode,
                        bankName: bankName,
                      ),
                      onCancel: () =>
                          ref.read(aiChatControllerProvider.notifier).cancelTransfer(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildConfirmCard(ChatMessage msg, AiChatState aiState, {bool isInStack = false}) {
    if (isInStack) {
      // Render placeholder in list when modal is active
      final p = msg.payload!;
      final isCompleted = (p['isCompleted'] as bool? ?? false);

      if (!isCompleted) {
        // Return empty space where card was - modal handles the actual display
        return const SizedBox(height: 200);
      }
    }

    final p = msg.payload!;
    final name = (p['name'] as String?) ?? '';
    final account = (p['account'] as String?) ?? '';
    final amount = ((p['amount'] as num?) ?? 0).toDouble();
    final fee = ((p['fee'] as num?) ?? 0).toDouble();
    final isCompleted = (p['isCompleted'] as bool?) ?? false;
    final destinationType = p['destinationType'] as String?;
    final isBankTransfer = (p['isBankTransfer'] as bool?) ?? false;
    final bankCode = p['bankCode'] as String?;
    final bankName = p['bankName'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ChatBubble(message: msg),
        Container(
          margin: EdgeInsets.only(top: 8.h),
          child: ConfirmCard(
            name: name,
            account: account,
            amount: amount,
            fee: fee,
            isCompleted: isCompleted,
            destinationType: destinationType,
            onConfirm: () => _onConfirmTapped(
              account: account,
              name: name,
              amount: amount,
              isBankTransfer: isBankTransfer,
              bankCode: bankCode,
              bankName: bankName,
            ),
            onCancel: () =>
                ref.read(aiChatControllerProvider.notifier).cancelTransfer(),
          ),
        ),
      ],
    );
  }

  Widget _buildInputArea() {
    return Container(
      margin: EdgeInsets.only(
        left: 16.w,
        right: 16.w,
        bottom: 16.h,
        top: 8.h,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
            child: Row(
              children: [
                SizedBox(width: 12.w),
                Expanded(
                  child: TextField(
                    controller: _textCtrl,
                    focusNode: _focusNode,
                    textCapitalization: TextCapitalization.sentences,
                    minLines: 1,
                    maxLines: 4,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: _isListening ? 'Listening...' : 'Type your message...',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w400,
                      ),
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                    ),
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    cursorColor: primaryColor,
                  ),
                ),
                SizedBox(width: 8.w),
                _buildSendOrMicButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildSuggestionChips(Map<String, dynamic> payload) {
    final raw = (payload['suggestions'] as List<dynamic>?) ?? [];
    final suggestions = raw.map((e) => e as Map<String, dynamic>).toList();

    return SuggestionChipRow(
      suggestions: suggestions,
      onTap: (suggestion) {
        ref
            .read(aiChatControllerProvider.notifier)
            .selectSuggestion(context, suggestion);
        _scrollToBottom();
      },
    );
  }

  void _onConfirmTapped({
    required String account,
    required String name,
    required double amount,
    required bool isBankTransfer,
    String? bankCode,
    String? bankName,
  }) {
    ref.read(aiChatControllerProvider.notifier).confirmTransfer(context);
    
    if (isBankTransfer && bankCode != null && bankName != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BankTransactionPin(
            recipientAccount: account,
            recipientName: name,
            amount: amount,
            saveAsBeneficiary: false,
            bankCode: bankCode,
            bankName: bankName,
          ),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TransactionPin(
            recipientAccount: account,
            recipientName: name,
            amount: amount,
            saveAsBeneficiary: false,
            type: 'transfer',
          ),
        ),
      );
    }
  }
}
