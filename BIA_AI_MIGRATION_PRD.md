# BIA AI — Backend Migration & Full-Capability PRD

**Owner:** Mobile + Backend team
**Status:** Ready to implement
**Related:** [biaAI.md](biaAI.md) (original feature spec)

---

## 1. Problem

BIA AI (the WhatsApp-style chat/voice payment assistant) currently runs almost entirely **inside the Flutter app**, and only understands 3 things: send money (BIA-to-BIA), send to bank, and check balance.

- [lib/feature/ai_chat/service/llm_service.dart](lib/feature/ai_chat/service/llm_service.dart) calls **Gemini** directly from the client, with the full system prompt (intents, JSON schema, per-language personality) hardcoded in the app.
- [lib/feature/ai_chat/service/eleven_labs_service.dart](lib/feature/ai_chat/service/eleven_labs_service.dart) calls **ElevenLabs** directly from the client.
- Both API keys live in `secrets.json` and get compiled into the app binary via `--dart-define-from-file`. Anyone can pull them out of the APK/IPA with `strings`.
- The Gemini key currently in use (`AQ.Ab8RN6J...`) is not a valid Gemini key format — this is likely why the AI is not responding correctly right now.
- There's no server-side control over the prompt, no rate limiting, no audit trail on an assistant that talks about money.
- The AI currently can't do most of what the app can do — airtime, data, cable, electricity, BIA tag transfers, QR payments, transaction history, etc. are all app-only, not AI-reachable.

**What's already correct** and should NOT change:
- [lib/feature/ai_chat/service/hausa_asr_service.dart](lib/feature/ai_chat/service/hausa_asr_service.dart) already calls **our own backend** (`https://ai.bia.com.ng/transcribe`), not a third party directly. This is the pattern to copy.
- All money-moving calls already go through the real BIA backend via [lib/feature/dashboard/dashboard_repo/repo.dart](lib/feature/dashboard/dashboard_repo/repo.dart). The AI will call into these same existing endpoints — it is not a second payment system, it's a new front door onto the one that already exists.

## 2. Goal

Two things, together:

1. Move the AI's "brain" (intent detection + reply generation, currently Gemini) behind our own backend, using **Claude** instead of Gemini, so no API keys ship in the client.
2. Expand what the AI understands from 3 intents to (almost) everything the app UI can already do: BIA-to-BIA transfer, transfer to bank, transfer by BIA tag, airtime, data, cable TV, electricity, checking balance, transaction history, and showing your own QR code. See §6 for the full matrix, including the few things that are explicitly **not** going to be chat-completable (and why).

## 3. Non-goals

- Not changing the conversational UI or the step-machine (`AiChatStep`) shape — it's extended with new steps for new intents, not redesigned.
- Not building a second payment engine. Every new AI intent calls the **same existing backend methods** in `dashboard_repo/repo.dart` that the equivalent app screen already calls. The AI is a new UI on top of existing, already-live functionality — nothing new is being built on the money-movement side.
- Not making every flow fully chat-native. A few actions structurally need something chat can't provide (a camera scan, a card entry form) — those get a "recognize + hand off to the right screen" treatment instead of full in-chat completion. Flagged explicitly in §6.4.
- **Split payment creation is in scope.** The split payment system exists in the app and backend. The AI will support creating a split bill by extracting participants and amounts, and paying a split bill using a splitId.

## 4. Why Claude instead of Gemini

Straight swap of the "AI Command Engine." Claude is text-in/text-out only — it does **not** do speech-to-text or text-to-speech, so ElevenLabs and the Hausa ASR/TTS services are unaffected and still required. Claude replaces exactly one thing: the Gemini call in `llm_service.dart`.

Bonus: Claude's **structured outputs** (`output_config.format` with a JSON schema) guarantee the response matches our schema exactly, even as that schema grows to cover many more intents (see §7) — no markdown-stripping / defensive `jsonDecode` like the current Gemini integration needs.

---

## 5. Target architecture

```
                         ┌─────────────────────────────┐
   Flutter app           │   ai.bia.com.ng (FastAPI)   │        Third parties
   ─────────────         │  ─────────────────────────  │        ─────────────
   ai_chat_controller     POST /chat        ─────────────▶  Claude API (Anthropic)
     │                    POST /tts         ─────────────▶  ElevenLabs (EN/Pidgin)
     ├─ llm_service   ───▶│                 └──────────────▶ Hausa TTS (HF model)
     ├─ eleven_labs   ───▶│  POST /transcribe (existing) ──▶  Hausa ASR (already built)
     └─ hausa_asr     ───▶│                              │
                         └─────────────┬───────────────┘
                                       │ intent + entities only
                                       ▼
                          ┌─────────────────────────┐
                          │  Existing BIA backend    │  ← sendMoney, sendMoneyToBank,
                          │  (dashboard_repo/repo)    │    purchaseAirtime, purchaseData,
                          └─────────────────────────┘    purchaseCable, purchaseElectricity,
                                                          verifyTag, getUserQrCode, etc.
```

The AI backend (`ai.bia.com.ng`) never moves money itself. It parses the user's text/voice into `{intent, entities, chat_response}`; the **Flutter app** is still the thing that calls the real BIA payment backend, shows the confirm card, and requires the PIN — exactly like it does today for `sendMoney`. This is a hard rule (§9).

The Flutter service classes (`LlmService`, `ElevenLabsService`) keep their **existing public method signatures** (`sendMessage`, `sendContextualMessage`, `updateLanguage`, `generateSpeech`) — only their internals change from "call third party SDK" to "call our backend."

---

## 6. Full capability / intent matrix

Every row calls an **existing** method already in [dashboard_repo/repo.dart](lib/feature/dashboard/dashboard_repo/repo.dart) — nothing here requires new backend payment logic, only new AI entity extraction + new UI wiring for each flow (confirm card + PIN, same pattern as `sendMoney` today).

### 6.1 Fully chat-completable (AI extracts entities → app shows confirm card → PIN → existing endpoint)

| Intent | What the user says (example) | Entities to extract | Existing method to call | Confirm card? |
|---|---|---|---|---|
| `sendMoney` | "Send 500 to Musa" | `recipient`, `amount` | `sendMoney()` (repo.dart:96) — via `verifyAccount()` (150) for resolution | Yes — already built |
| `sendByTag` | "Send 2k to @musa_b" | `tag`, `amount` | `verifyTag()` (186) to resolve, then `sendMoney()` (96) | Yes — new confirm card, same shape as `sendMoney`'s |
| `sendToBank` | "Send 1000 to GTBank, account 0123456789" | `recipient`/`account_number`, `amount`, `destination_bank` | `verifyBankAccount()` (710) → `sendMoneyToBank()` (785) | Yes — already built |
| `checkBalance` | "What's my balance" | — | `getWalletBalance()` (380) | No — direct answer |
| `buyAirtime` | "Buy 500 MTN airtime for 08012345678" | `phone_number`, `network`, `amount` | `purchaseAirtime()` (1011) | Yes — new |
| `buyData` | "Buy 1GB MTN data for me" / "...for 08012345678" | `phone_number`, `network`, `data_plan` | `getDataPlans()` (1044) to resolve plan → `purchaseData()` (1070) | Yes — new |
| `payCableTv` | "Renew my DSTV, smartcard 1234567890" | `cable_provider`, `smartcard_number`, `plan` (optional) | `getCableProviders()` (1127) / `getCableVariations()` (1152) → `verifyCableCard()` (1185) → `purchaseCable()` (1213) | Yes — new |
| `payElectricity` | "Buy 5000 naira light for meter 12345678901" | `electricity_provider`, `meter_number`, `amount` | `getElectricityProviders()` (1250) → `verifyElectricityMeter()` (1275) → `purchaseElectricity()` (1305) | Yes — new |
| `checkTransactionHistory` | "Show my last 5 transactions" / "Did I send Musa money yesterday?" | none, or a loose filter the app applies client-side | `getRecentTransactions()` (409) / `getTransactions()` (449) | No — rendered as a list in chat |
| `showQrCode` | "Show my QR code" / "How do people pay me?" | — | `getUserQrCode()` (249) | No — renders the QR image in chat |
| `createSplit` | "Split 5000 naira with @musa (2000) and @aisha (3000)" | `amount`, `participants` (list of tag/phone and amount) | `createSplit()` (repository) | Yes — new confirm card |
| `paySplit` | "Pay the split bill SPLT_12345" | `splitId` | `paySplit()` (repository) | Yes — confirm card |

### 6.2 Entity resolution notes

- **BIA tag (`sendByTag`)**: the current `BeneficiaryResolver` in [lib/feature/ai_chat/engine/beneficiary_resolver.dart](lib/feature/ai_chat/engine/beneficiary_resolver.dart) fuzzy-matches names against known contacts/beneficiaries. Tags (`@handle`) are a different lookup — they resolve via `verifyTag()` (repo.dart:186), a single exact lookup, not fuzzy matching. Treat "recipient starts with `@`, or the user explicitly says 'tag'" as the signal to route to tag resolution instead of the name-based resolver.
- **Airtime/data network detection**: if the user gives a phone number without naming a network (e.g. "buy 500 airtime for 08012345678"), the network can often be inferred from the Nigerian prefix (MTN/Glo/Airtel/9mobile ranges) — do this resolution app-side or backend-side (not the AI's job), same as if a human manually picked it in the airtime screen.
- **Cable/electricity provider names**: users will say "DSTV", "GOTV", "Startimes", "Ikeja Electric", "EKEDC", etc. informally. Match against `getCableProviders()` / `getElectricityProviders()` the same fuzzy way `_processBankTransferRequest` already matches bank names in `ai_chat_controller.dart` — reuse that fuzzy-match pattern (see lines around `matchedBank` in [ai_chat_controller.dart](lib/feature/ai_chat/controller/ai_chat_controller.dart)), don't invent a new one.

### 6.3 Read-only / informational (no PIN, no confirm card)

- `checkBalance`, `checkTransactionHistory`, `showQrCode` — these never touch money movement, so they skip the confirm-card + PIN step entirely and just render the answer, same as `checkBalance` does today.

### 6.4 Explicitly NOT chat-completable — hand off to the existing screen instead

| Intent | Why it can't be chat-only | What the AI should do instead |
|---|---|---|
| **Paying via QR (scanning someone else's code)** | Requires the device camera to scan a code — there's no text/voice equivalent to "scan this." | Recognize phrases like "I want to pay by QR" / "scan a code" and respond by telling the user to tap the QR scanner (`lib/feature/dashboard/pages/send_money/scan_transfer/scanner.dart`) — `intent: "unknown"` with a helpful `chat_response`, or a dedicated `intent: "openQrScanner"` if you want the UI to auto-navigate there. Do not attempt to fabricate a QR payment from chat text. |
| **Top-up / add money to wallet** | Funding the wallet goes through a card-entry or bank-transfer payment gateway UI (`lib/feature/dashboard/pages/send_money/top_up/add_money.dart`, `depositMoney()` repo.dart:547) — there's no safe way to collect card details through a chat bubble. | Same pattern: recognize the intent, respond with guidance, optionally auto-navigate to the top-up screen. Never ask for card details in chat. |
| **Scanning Split QRs** | Requires the device camera to scan a physical QR code. | Treat the physical scan step as outside chat capability. Recognize phrases like "I want to scan a split QR code" and guide the user to trigger the camera scanner. Creating and paying split bills via text/voice intents are fully supported. |
| **PIN change, profile edits, KYC, referral program, support tickets** | Account-management and security-sensitive flows that should go through their existing dedicated screens, not be re-implemented as chat actions. | Same "recognize + point at the right screen" treatment as QR/top-up above. Not in scope for this PRD's confirm-card work. |

---

## 7. API Contract (backend dev builds this)

Base URL: `https://ai.bia.com.ng` (same host as the existing `/transcribe` endpoint).

### 7.1 `POST /chat`

Replaces the client-side Gemini call, now covering the full intent matrix from §6.

**Request:**
```json
{
  "text": "Buy 500 MTN airtime for 08012345678",
  "language": "english",           // "english" | "pidgin" | "hausa"
  "conversation_id": "user_12345"  // stable per-user id — server holds turn history
}
```

**Response:** `200 OK`
```json
{
  "intent": "buyAirtime",
  "entities": {
    "recipient": null,
    "account_number": null,
    "tag": null,
    "amount": 500,
    "destination_bank": null,
    "phone_number": "08012345678",
    "network": "MTN",
    "data_plan": null,
    "cable_provider": null,
    "smartcard_number": null,
    "electricity_provider": null,
    "meter_number": null
  },
  "chat_response": "Sending N500 MTN airtime to 08012345678, confirm?"
}
```

`intent` is one of: `sendMoney`, `sendByTag`, `sendToBank`, `checkBalance`, `buyAirtime`, `buyData`, `payCableTv`, `payElectricity`, `checkTransactionHistory`, `showQrCode`, `createSplit`, `paySplit`, `unknown`. `entities` always contains every key (nulled if not applicable) — this is what makes structured outputs work cleanly; see §9 for the exact JSON Schema.

This is a **breaking change** from the old flat `{intent, recipient, amount, destination_bank, chat_response}` shape — the frontend's `LlmParsedResponse` model needs updating to match (see §11).

**Server-side responsibilities:**
1. Hold the system prompt covering the full intent matrix (§6) — see §8 for what to port over and what to add.
2. Maintain conversation history **server-side**, keyed by `conversation_id` (replaces the client-side `LlmService._history` list).
3. Call Claude with **structured outputs** validating against the full entity schema (§9). This removes the markdown-stripping / try-catch JSON parsing the current Gemini code needs.
4. Rate-limit per user. Log requests (this assistant talks about money — you want an audit trail).
5. On upstream failure, return the same fallback shape the client already knows how to render:
   ```json
   { "intent": "unknown", "entities": { /* all null */ }, "chat_response": "<localized fallback text>" }
   ```
   (Localized fallback strings can be copied from `_getFallbackErrorResponse` / `_getFallbackRateLimitResponse` in the current `llm_service.dart` — keep those on the server now.)

### 7.2 `POST /tts` — unchanged from original scope

Replaces the client-side ElevenLabs call, and the client-side Hausa TTS HF call.

**Request:**
```json
{
  "text": "N500 sent to Musa",
  "language": "hausa",                    // "english" | "pidgin" | "hausa"
  "voice_id": "V2D1qkaFj5NormT9yoaK"      // only meaningful for english/pidgin (ElevenLabs voice)
}
```

**Response:** `200 OK`, `Content-Type: audio/mpeg` — raw audio bytes in the body (same as what `ElevenLabsService.generateSpeech` returns today).

**Server-side responsibilities:**
- If `language == "hausa"` → call the existing Hausa TTS HF model.
- Else → call ElevenLabs with the given `voice_id`, model `eleven_flash_v2_5` (copy the request body from [eleven_labs_service.dart](lib/feature/ai_chat/service/eleven_labs_service.dart)).
- Return `4xx`/`5xx` on failure — the client already treats a non-200 as "skip playback."

### 7.3 `POST /transcribe` — already built, no changes

Keep as-is. This is the pattern the other two endpoints should follow.

---

## 8. System prompt — what to port, what to add

Start from the existing prompt in [llm_service.dart:46-114](lib/feature/ai_chat/service/llm_service.dart#L46-L114) (the intents list, JSON output structure, per-language personality blocks) — **but this is now a rewrite, not a copy-paste**, since the intent count grew from 4 to 11. Keep:
- The three per-language personality blocks (`_buildLangInstruction` — English/Pidgin/Hausa tone).
- The `[SYSTEM_CONTEXT]` convention: when `text` starts with `[SYSTEM_CONTEXT]:`, keep `intent: "unknown"` and just generate `chat_response` — this is how the app asks for things like "tell the user you're verifying the account" without it being a real user turn.
- The "always ask for missing required entities in `chat_response`" behavior (e.g. no amount given → ask for it).

Add:
- The 10 new intents from §6, with the same "ask for missing info" behavior per intent (e.g. `buyAirtime` with no amount → ask for it; `payCableTv` with no smartcard number → ask for it).
- Explicit instruction to return `intent: "unknown"` for the §6.4 hand-off cases (QR scan, top-up, split payment, PIN/profile/referral/support), with a `chat_response` that guides the user to the right screen instead of pretending to process it.
- Guidance for informal provider/network names ("DSTV", "9mobile", "Ikeja Electric" etc.) — the model should pass through what the user said as-is in the entity field; fuzzy-matching against the real provider list happens app-side/backend-side (§6.2), not by the LLM.

---

## 9. Claude API call (backend dev reference)

```python
import anthropic

client = anthropic.Anthropic()  # reads ANTHROPIC_API_KEY from env

INTENT_SCHEMA = {
    "type": "object",
    "properties": {
        "intent": {
            "type": "string",
            "enum": [
                "sendMoney", "sendByTag", "sendToBank", "checkBalance",
                "buyAirtime", "buyData", "payCableTv", "payElectricity",
                "checkTransactionHistory", "showQrCode", "createSplit",
                "paySplit", "unknown"
            ]
        },
        "entities": {
            "type": "object",
            "properties": {
                "recipient": {"type": ["string", "null"]},
                "account_number": {"type": ["string", "null"]},
                "tag": {"type": ["string", "null"]},
                "amount": {"type": ["number", "null"]},
                "destination_bank": {"type": ["string", "null"]},
                "phone_number": {"type": ["string", "null"]},
                "network": {"type": ["string", "null"]},
                "data_plan": {"type": ["string", "null"]},
                "cable_provider": {"type": ["string", "null"]},
                "smartcard_number": {"type": ["string", "null"]},
                "electricity_provider": {"type": ["string", "null"]},
                "meter_number": {"type": ["string", "null"]},
                "split_id": {"type": ["string", "null"]},
                "participants": {
                    "type": ["array", "null"],
                    "items": {
                        "type": "object",
                        "properties": {
                            "tag": {"type": ["string", "null"]},
                            "phone": {"type": ["string", "null"]},
                            "amount": {"type": "number"}
                        },
                        "required": ["amount"]
                    }
                }
            },
            "required": [
                "recipient", "account_number", "tag", "amount", "destination_bank",
                "phone_number", "network", "data_plan", "cable_provider",
                "smartcard_number", "electricity_provider", "meter_number",
                "split_id", "participants"
            ],
            "additionalProperties": False
        },
        "chat_response": {"type": "string"}
    },
    "required": ["intent", "entities", "chat_response"],
    "additionalProperties": False
}

response = client.messages.create(
    model="claude-opus-4-8",
    max_tokens=1024,
    system=SYSTEM_PROMPT_FOR_LANGUAGE[language],   # from §8, cached with cache_control
    messages=conversation_history + [{"role": "user", "content": text}],
    output_config={
        "format": {"type": "json_schema", "schema": INTENT_SCHEMA},
        "effort": "low"   # fast intent-classification + a short reply, not deep reasoning — keep latency down
    }
)

text_block = next(b.text for b in response.content if b.type == "text")
import json
result = json.loads(text_block)  # guaranteed to match INTENT_SCHEMA
```

Notes:
- `output_config.format` guarantees valid JSON matching the schema — no markdown-stripping needed.
- `effort: "low"` keeps this snappy for a chat UI; raise to `"medium"` only if the model under-performs on ambiguous requests (e.g. failing to split "buy 500 MTN airtime for my brother 08012345678" into the right fields).
- Model `claude-opus-4-8` is the default recommendation. If cost becomes a concern at volume, `claude-sonnet-5` is a cheaper/faster tier ($3/$15 per MTok vs $5/$25) that's usually plenty for structured intent classification — benchmark both before committing.
- Cache the system prompt with `cache_control: {"type": "ephemeral"}` on the system block — it's identical across most requests for a given language.
- Store `ANTHROPIC_API_KEY` and `ELEVEN_LABS_API_KEY` in your server's secrets manager / env vars — never in a file that gets deployed to the client.

---

## 10. Backend dev — task checklist

- [ ] Add `POST /chat` to the existing FastAPI service at `ai.bia.com.ng`, per §7.1, covering all 11 intents
- [ ] Add `POST /tts` to the same service, per §7.2
- [ ] Move + extend the system prompt (§8) server-side, parameterized by language
- [ ] Add per-user conversation history storage (replaces client-side `_history` list)
- [ ] Wire up Claude via `output_config.format` structured outputs using the full entity schema (§9)
- [ ] Wire up ElevenLabs + Hausa TTS behind `/tts`, dispatching on `language`
- [ ] Add rate limiting + request logging (this is a money-adjacent endpoint)
- [ ] Add localized fallback responses for upstream failures
- [ ] Store `ANTHROPIC_API_KEY` / `ELEVEN_LABS_API_KEY` in server secrets, never in a repo file
- [ ] Add `createSplit` and `paySplit` intents support to backend Claude model and payload processor.
- [ ] Share the finalized request/response shapes with the frontend dev — should match §7 exactly

## 11. Frontend dev — task checklist

**Service layer:**
- [ ] Rewrite [lib/feature/ai_chat/service/llm_service.dart](lib/feature/ai_chat/service/llm_service.dart): remove `google_generative_ai`, call `$aiBaseUrl/chat` instead, keep public method signatures identical (`sendMessage`, `sendContextualMessage`, `updateLanguage`, `resetHistory`)
- [ ] Update `LlmParsedResponse` (in the same file) to match the new `{intent, entities, chat_response}` shape from §7.1 — this is the one breaking model change
- [ ] Send `conversation_id` = the same `effectiveUserId` the controller already derives from Hive
- [ ] Drop the local `_history` list — history now lives server-side
- [ ] Rewrite [lib/feature/ai_chat/service/eleven_labs_service.dart](lib/feature/ai_chat/service/eleven_labs_service.dart): call `$aiBaseUrl/tts`, pass `language` through, keep `generateSpeech({required text, required voiceId})` signature identical

**Controller / new intent handlers** (in [lib/feature/ai_chat/controller/ai_chat_controller.dart](lib/feature/ai_chat/controller/ai_chat_controller.dart)), each following the existing `_handleSendMoney` / `_showConfirmCard` pattern:
- [ ] `_handleSendByTag` — resolve via `verifyTag()`, then reuse the existing `_showConfirmCard`
- [ ] `_handleBuyAirtime` — new confirm card, `purchaseAirtime()`
- [ ] `_handleBuyData` — resolve plan via `getDataPlans()`, new confirm card, `purchaseData()`
- [ ] `_handlePayCableTv` — resolve provider via `getCableProviders()`/`getCableVariations()`, verify via `verifyCableCard()`, new confirm card, `purchaseCable()`
- [ ] `_handlePayElectricity` — resolve provider via `getElectricityProviders()`, verify via `verifyElectricityMeter()`, new confirm card, `purchaseElectricity()`
- [ ] `_handleCheckTransactionHistory` — render a short list from `getRecentTransactions()`/`getTransactions()`, no PIN
- [ ] `_handleShowQrCode` — render the QR image from `getUserQrCode()`, no PIN
- [ ] For the §6.4 hand-off cases (QR scanning, top-up, PIN/profile/referral/support) — when `intent == "unknown"`, just show `chat_response`; no new handler needed unless product wants auto-navigation to the relevant screen (nice-to-have, not required for v1)
- [ ] Implement `_handleCreateSplit` (new confirm card showing split details, calls repository `createSplit`)
- [ ] Implement `_handlePaySplit` (confirm card for paying split bill, calls repository `paySplit`)

**Cleanup:**
- [ ] Once both backend endpoints are live and verified, delete `GEMINI_API_KEY` and `ELEVEN_LABS_API_KEY` from `secrets.json` and any `--dart-define` / CI build config referencing them
- [ ] Remove the `google_generative_ai` package from `pubspec.yaml` if nothing else uses it
- [ ] Smoke-test every intent end-to-end in all 3 languages, plus voice input/output — in the actual app, not just backend curl tests

---

## 12. Security & critical rules (unchanged, still apply to every new intent)

Carried over from [biaAI.md](biaAI.md) and non-negotiable for every new money-moving intent added here:

- **Always require PIN** before any of `sendMoney`, `sendByTag`, `sendToBank`, `buyAirtime`, `buyData`, `payCableTv`, `payElectricity` actually executes.
- **Manual confirmation only** — the AI never auto-sends. Every money-moving intent shows a confirm card first, exactly like `sendMoney` does today.
- **Language only affects communication.** Which language the user picked never changes transaction logic, amounts, or which backend method gets called.

## 13. Rollout / sequencing

1. Backend dev builds and deploys `/chat` (all 11 intents) and `/tts` against a staging Claude/ElevenLabs key. Share exact request/response JSON with frontend dev.
2. Frontend dev ships the two service rewrites + new intent handlers against staging, one intent at a time if useful (e.g. land `sendMoney`/`sendByTag`/`checkBalance` first since they're closest to what exists, then airtime/data, then cable/electricity, then QR/history).
3. Once verified end-to-end on staging, rotate to production keys server-side, remove keys from the app build config, ship.
4. Confirm the removed `secrets.json` keys are also purged from any CI secrets store / build pipeline.

## 14. Acceptance criteria

- No Anthropic, ElevenLabs, or (already true) Hausa-model API key exists anywhere in the compiled app or its build config.
- All 11 intents in §6 work end-to-end in all 3 languages, with PIN confirmation preserved on every money-moving one.
- The §6.4 hand-off cases (QR scan, top-up, split payment, account-management flows) respond helpfully without attempting to fake a completion.
- `getUserQrCode`/`getRecentTransactions`/`checkBalance` flows work with no PIN prompt (read-only).
- Voice input (Hausa) and voice output (all 3 languages) work unchanged from the user's perspective.
