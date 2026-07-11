/// Represents a structured intent returned by the AI intent parser
/// (either the local fallback parser or the FastAPI backend).
class IntentModel {
  final String intent;
  final Map<String, dynamic> parameters;
  final double confidence;

  const IntentModel({
    required this.intent,
    required this.parameters,
    this.confidence = 1.0,
  });

  factory IntentModel.fromJson(Map<String, dynamic> json) {
    return IntentModel(
      intent: json['intent'] as String? ?? 'UNKNOWN',
      parameters: Map<String, dynamic>.from(json['parameters'] as Map? ?? {}),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'intent': intent,
        'parameters': parameters,
        'confidence': confidence,
      };

  @override
  String toString() => 'IntentModel(intent: $intent, parameters: $parameters)';
}

/// All intents currently supported across the roadmap.
/// Phase 1 intents are the ones actually wired to actions right now.
class IntentType {
  static const openApp = 'OPEN_APP';
  static const makeCall = 'MAKE_CALL';
  static const sendSms = 'SEND_SMS';
  static const playMusic = 'PLAY_MUSIC';
  static const pauseMusic = 'PAUSE_MUSIC';
  static const nextTrack = 'NEXT_TRACK';
  static const previousTrack = 'PREVIOUS_TRACK';
  static const addExpense = 'ADD_EXPENSE';
  static const addTrade = 'ADD_TRADE';
  static const showExpenses = 'SHOW_EXPENSES';
  static const showTradingStats = 'SHOW_TRADING_STATS';
  static const unknown = 'UNKNOWN';
}
