import 'package:flutter/material.dart';
import 'package:mrchesscoach_client/mrchesscoach_client.dart';

import '../client.dart';
import '../theme.dart';
import 'coach_panel.dart';

/// Conversations with the coach, kept per position source (e.g. a game) for
/// as long as the app runs.
final _conversations = <String, List<CoachChatTurn>>{};

/// Opens the "Ask the coach" dialog for the position [fen].
Future<void> showAskCoach(
  BuildContext context, {
  required String conversationKey,
  required String fen,
  List<String> recentSan = const [],
  PlayerColor? studentColor,
  List<String> suggestions = const [
    'What is my plan here?',
    'Is my king safe?',
    'What is my opponent up to?',
    'Which piece should I improve?',
  ],
}) => showDialog<void>(
  context: context,
  barrierColor: Colors.black.withValues(alpha: 0.6),
  builder: (context) => _AskCoachDialog(
    conversation: _conversations.putIfAbsent(conversationKey, () => []),
    fen: fen,
    recentSan: recentSan,
    studentColor: studentColor,
    suggestions: suggestions,
  ),
);

class _AskCoachDialog extends StatefulWidget {
  const _AskCoachDialog({
    required this.conversation,
    required this.fen,
    required this.recentSan,
    required this.studentColor,
    required this.suggestions,
  });

  final List<CoachChatTurn> conversation;
  final String fen;
  final List<String> recentSan;
  final PlayerColor? studentColor;
  final List<String> suggestions;

  @override
  State<_AskCoachDialog> createState() => _AskCoachDialogState();
}

class _AskCoachDialogState extends State<_AskCoachDialog> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  bool _waiting = false;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send(String question) async {
    final q = question.trim();
    if (q.isEmpty || _waiting) return;
    final history = List<CoachChatTurn>.of(widget.conversation);
    setState(() {
      widget.conversation.add(CoachChatTurn(fromCoach: false, text: q));
      _waiting = true;
      _input.clear();
    });
    _scrollToEnd();
    String answer;
    try {
      answer = await client.coach.ask(
        widget.fen,
        widget.recentSan,
        q,
        history,
        widget.studentColor,
      );
    } on ChessGameException catch (e) {
      answer = e.message;
    } catch (_) {
      answer = 'I lost my connection for a moment. Ask me again?';
    }
    if (!mounted) return;
    setState(() {
      widget.conversation.add(CoachChatTurn(fromCoach: true, text: answer));
      _waiting = false;
    });
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final turns = widget.conversation;
    final size = MediaQuery.sizeOf(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: (size.height * 0.85).clamp(360, 760),
        ),
        child: Panel(
          padding: EdgeInsets.zero,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 8, 12),
                child: Row(
                  children: [
                    const CoachAvatar(size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Ask the coach', style: Typo.display(28)),
                          Text(
                            'About the position on the board right now',
                            style: Typo.body(12, color: Palette.muted),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Palette.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 0.7,
                color: Palette.goldDeep.withValues(alpha: 0.4),
              ),
              Flexible(
                child: ListView(
                  controller: _scroll,
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  children: [
                    if (turns.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Ask me anything about this position: plans, '
                          'threats, why a move is good or bad.',
                          style: Typo.display(19, color: Palette.parchment),
                        ),
                      ),
                    for (final t in turns) _ChatBubble(turn: t),
                    if (_waiting)
                      const Padding(
                        padding: EdgeInsets.only(top: 4, bottom: 8),
                        child: CoachThinking(label: 'Coach is looking'),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final s in widget.suggestions)
                      ActionChip(
                        label: Text(
                          s,
                          style: Typo.body(12, color: Palette.ivory),
                        ),
                        backgroundColor: Colors.white.withValues(alpha: 0.04),
                        side: BorderSide(
                          color: Palette.goldDeep.withValues(alpha: 0.5),
                        ),
                        shape: const StadiumBorder(),
                        onPressed: _waiting ? null : () => _send(s),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 12, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        autofocus: true,
                        enabled: !_waiting,
                        minLines: 1,
                        maxLines: 3,
                        textInputAction: TextInputAction.send,
                        onSubmitted: _send,
                        style: Typo.body(14, color: Palette.ivory),
                        decoration: InputDecoration(
                          hintText: 'Type your question…',
                          hintStyle: Typo.body(14, color: Palette.muted),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.04),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: Palette.goldDeep.withValues(alpha: 0.5),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: Palette.goldDeep.withValues(alpha: 0.5),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Palette.gold),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      tooltip: 'Send',
                      onPressed: _waiting ? null : () => _send(_input.text),
                      style: IconButton.styleFrom(
                        backgroundColor: Palette.gold,
                        foregroundColor: Palette.onyx,
                      ),
                      icon: const Icon(Icons.arrow_upward_rounded),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.turn});

  final CoachChatTurn turn;

  @override
  Widget build(BuildContext context) {
    final coach = turn.fromCoach;
    return Align(
      alignment: coach ? Alignment.centerLeft : Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: coach
                ? Colors.white.withValues(alpha: 0.05)
                : Palette.gold.withValues(alpha: 0.16),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(coach ? 4 : 16),
              topRight: Radius.circular(coach ? 16 : 4),
              bottomLeft: const Radius.circular(16),
              bottomRight: const Radius.circular(16),
            ),
            border: Border.all(
              color: coach
                  ? Palette.goldDeep.withValues(alpha: 0.35)
                  : Palette.gold.withValues(alpha: 0.5),
            ),
          ),
          child: coach
              ? TypewriterText(
                  turn.text,
                  style: Typo.body(
                    14,
                    color: Palette.ivory,
                  ).copyWith(height: 1.45),
                )
              : Text(turn.text, style: Typo.body(14, color: Palette.ivory)),
        ),
      ),
    );
  }
}
