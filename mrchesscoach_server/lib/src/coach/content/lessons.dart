import 'content_types.dart';

/// Curated positions to play out against the engine. Each one teaches a
/// single technique; the student is always the side to move in [fen].
///
/// `test/unit/lessons_content_test.dart` checks that every position is
/// legal and that Stockfish agrees the goal is achievable.
const positionLessons = <PositionLesson>[
  // ---------------------------------------------------------------- Endgames
  PositionLesson(
    id: 'queen-mate',
    category: 'endgame',
    title: 'Queen vs king: checkmate',
    tagline: 'Shrink the box, bring the king, avoid stalemate',
    concept:
        'A queen and king always beat a lone king, but only with a plan. '
        'Use the queen to fence the enemy king into a box: a queen a '
        'knight\'s move away from the king takes away a whole block of '
        'squares without giving check. Each time the king steps aside, '
        'follow it with the queen, keeping that knight\'s-move distance, '
        'and the box gets smaller until the king is stuck on the edge.\n\n'
        'Once the king is on the edge, stop chasing it. The queen alone '
        'cannot mate, so walk your own king over until it stands two '
        'squares in front of the enemy king. Then the queen mates on the '
        'edge, protected by your king or along the whole rank. The only '
        'way to spoil it is stalemate, so before every queen move check '
        'that the enemy king still has a square to go to.',
    tips: [
      'Put your queen a knight\'s move away from the enemy king and keep '
          'following it at that distance.',
      'When the king is trapped on the edge, stop moving the queen and '
          'march your own king over.',
      'Before every queen move, make sure the enemy king still has a '
          'legal move, or it is stalemate.',
      'Checks are not needed to push the king back; quiet queen moves '
          'that take squares away are faster.',
    ],
    fen: '8/8/3k4/8/8/8/8/Q3K3 w - - 0 1',
    goal: LessonGoal.win,
    difficulty: 1,
  ),
  PositionLesson(
    id: 'rook-mate-box',
    category: 'endgame',
    title: 'Rook vs king: the box method',
    tagline: 'Squeeze the king with your rook, one rank at a time',
    concept:
        'With a single rook you cannot chase the king to the edge with '
        'checks alone. Instead, the rook draws a box: a rank and a file '
        'the enemy king may not cross. Your job is to make the box smaller '
        'whenever you can. Bring your king up next to the rook so it '
        'protects it, and when the enemy king steps away from the rook, '
        'move the rook one line closer to shrink the box.\n\n'
        'When the defending king has to face your king with exactly one '
        'square between them (the opposition), a rook check along the '
        'edge is mate, or it drives the king onto the last rank where the '
        'next check mates. If the enemy king attacks your rook, protect it '
        'with your king or move it to the far side of the board along the '
        'same line, so the box stays closed.',
    tips: [
      'Shrink the box with the rook whenever the enemy king is not '
          'blocking the move.',
      'Use your king to protect the rook and to take squares in front of '
          'the enemy king.',
      'If the rook is attacked, move it far away along the same line '
          'instead of giving up the box.',
      'Make a waiting rook move when you need the enemy king to step '
          'into the opposition.',
    ],
    fen: '8/8/8/3k4/8/8/8/R3K3 w - - 0 1',
    goal: LessonGoal.win,
    difficulty: 1,
  ),
  PositionLesson(
    id: 'ladder-mate',
    category: 'endgame',
    title: 'Two rooks: the ladder mate',
    tagline: 'Two rooks walk the king to the edge without help',
    concept:
        'Two rooks can mate without their king. They work like the rungs '
        'of a ladder: one rook cuts the king off along a rank, the other '
        'gives check on the next rank, and the king must step back. Then '
        'the rooks swap roles, the back rook leaps over to the next rank, '
        'and the king is pushed back again until a check on the edge rank '
        'is mate.\n\n'
        'The one thing to watch is the enemy king attacking a rook. When '
        'the king gets close to a rook, move that rook to the far side of '
        'the board on the same rank, out of reach, and then continue the '
        'ladder. The rooks never need protecting if they stay far away '
        'from the king.',
    tips: [
      'Keep one rook cutting off the king while the other gives check '
          'one rank further.',
      'If the king approaches a rook, move it to the opposite side of '
          'the board along its rank.',
      'Keep the rooks on different files so they do not block each '
          'other.',
    ],
    fen: '8/8/8/4k3/8/8/6K1/R6R w - - 0 1',
    goal: LessonGoal.win,
    difficulty: 1,
  ),
  PositionLesson(
    id: 'opposition',
    category: 'endgame',
    title: 'King and pawn: the opposition',
    tagline: 'Face the enemy king and make it give way',
    concept:
        'In king and pawn endings the kings fight for squares. Two kings '
        'standing on the same file (or rank) with one square between them '
        'are in opposition, and the side that does not have to move "has '
        'the opposition": the other king must step aside and let it pass. '
        'With the opposition your king can reach the key squares in front '
        'of the pawn, the squares from which the pawn always promotes.\n\n'
        'For a pawn that has not yet crossed the middle of the board, the '
        'key squares are the three squares two ranks in front of it. Lead '
        'with the king, not the pawn: a pawn pushed too early only gives '
        'the defender time. Take the opposition, wait for the enemy king '
        'to give way, step forward to a key square, and only then advance '
        'the pawn. In this position only one move wins: the king step '
        'that faces the black king on the same file with one square in '
        'between. Every other move, including pushing the pawn, lets '
        'Black take the opposition and draw.',
    tips: [
      'Lead with your king; push the pawn only once your king is on a '
          'key square in front of it.',
      'Move your king so it faces the enemy king with one square between '
          'them and it is the opponent\'s turn.',
      'When the enemy king steps aside, go around it towards the key '
          'squares.',
      'Once you are on a key square, the pawn walks home with your king '
          'escorting it.',
    ],
    fen: '8/3k4/8/8/3KP3/8/8/8 w - - 0 1',
    goal: LessonGoal.win,
    difficulty: 2,
  ),
  PositionLesson(
    id: 'outside-passed-pawn',
    category: 'endgame',
    title: 'The outside passed pawn',
    tagline: 'Decoy the king with a far pawn, feast on the rest',
    concept:
        'A passed pawn far away from the other pawns is a powerful weapon '
        'in king and pawn endings. Push it, and the enemy king has to run '
        'over to stop it. While it is busy, your king walks into the '
        'other side and eats the pawns left behind. Even if your outside '
        'pawn is lost, it has done its job as a decoy.\n\n'
        'Use the rule of the square to judge the race: draw a square from '
        'the pawn to its promotion rank. If the enemy king can step into '
        'that square, it catches the pawn; if not, the pawn queens on its '
        'own. Here the black king can catch the a-pawn, but only by '
        'leaving the kingside, so push the pawn and head the other way '
        'with your king.',
    tips: [
      'Push the outside passed pawn to drag the enemy king away from the '
          'other pawns.',
      'Use the rule of the square to check whether the king can catch '
          'the pawn.',
      'As soon as the enemy king leaves, march your king to the pawns on '
          'the other wing.',
      'Do not swap the kingside pawns; they are what your king will eat.',
    ],
    fen: '8/8/5pp1/4k2p/P6P/4K1P1/5P2/8 w - - 0 1',
    goal: LessonGoal.win,
    difficulty: 2,
  ),
  PositionLesson(
    id: 'lucena-position',
    category: 'endgame',
    title: 'Lucena position: building a bridge',
    tagline: 'Shelter your king from checks with a rook bridge',
    concept:
        'In the Lucena position the attacker\'s king stands on the '
        'promotion square in front of its own pawn on the seventh rank, '
        'and the defending king is cut off along a file. The king cannot '
        'come out, because the defending rook checks it from the side or '
        'from behind. The winning method is to build a bridge: first push '
        'the defending king one more file away with a rook check, then put '
        'your rook on the fourth rank.\n\n'
        'Now walk the king out of the corner. When the checks come from '
        'behind, the king steps down towards your rook, and once the '
        'checks run out the rook blocks the last one on the fourth rank, '
        'protected by the king. The checks are over and the pawn queens. '
        'Here: Rd1+ first, then Rd4, and only then bring the king out.',
    tips: [
      'First give a rook check to push the defending king one more file '
          'away.',
      'Put your rook on the fourth rank: that is where the bridge goes.',
      'Walk the king out and down towards your rook while the checks '
          'come; block the last check with the rook.',
    ],
    fen: '1K1k4/1P6/8/8/8/8/r7/2R5 w - - 0 1',
    goal: LessonGoal.win,
    difficulty: 3,
  ),
  PositionLesson(
    id: 'philidor-position',
    category: 'endgame',
    title: 'Philidor position: third-rank defence',
    tagline: 'Hold the draw a pawn down with an active rook',
    concept:
        'When you are defending a rook ending a pawn down and your king '
        'stands in front of the pawn, the Philidor defence is a simple, '
        'reliable draw. Keep your rook on your third rank (the sixth rank '
        'for Black). There it stops the enemy king from coming forward to '
        'support its pawn.\n\n'
        'Wait with the rook along that rank until the pawn advances to it. '
        'The moment the pawn steps onto your third rank, the enemy king '
        'has lost its shelter, so swing your rook to the far end of the '
        'board and give check from behind. The king cannot hide from '
        'those checks without abandoning its pawn. The typical mistake is '
        'to let the rook drift off the third rank too early, which lets '
        'the king in.',
    tips: [
      'Keep your rook on the sixth rank while the white pawn is on the '
          'fifth.',
      'Keep your king on the queening square or right next to it.',
      'Once the pawn reaches the sixth rank, send your rook to the first '
          'rank and check the king from behind.',
      'Check from a distance; a rook next to the enemy king can be '
          'attacked.',
    ],
    fen: '4k3/R7/1r6/3KP3/8/8/8/8 b - - 0 1',
    goal: LessonGoal.draw,
    targetMoves: 15,
    difficulty: 3,
  ),
  PositionLesson(
    id: 'rook-behind-passed-pawn',
    category: 'endgame',
    title: 'Rook behind the passed pawn',
    tagline: 'Your rook belongs behind the pawn, not in front',
    concept:
        'Tarrasch\'s rule says rooks belong behind passed pawns. A rook '
        'behind its own passed pawn grows stronger with every step the '
        'pawn takes, because the file in front of it gets longer. The '
        'enemy rook in front of the pawn is the opposite: it is tied to '
        'blocking the pawn and gets more passive as the pawn advances.\n\n'
        'Push the pawn with rook support, and keep your rook behind it. '
        'The defending rook has to stay in front of the pawn, so its king '
        'must also watch the pawn. Meanwhile your king can walk towards '
        'the enemy pawns, and the defence soon runs out of useful moves.',
    tips: [
      'Keep your rook behind the a-pawn and push the pawn when it is '
          'safe.',
      'Black\'s rook will have to block the pawn from in front, where it '
          'is passive; keep it tied there.',
      'Bring your king up towards the centre while the black pieces are '
          'tied to the pawn.',
      'Do not swap rooks unless the king and pawn ending is clearly won.',
    ],
    fen: '1r4k1/5ppp/8/P7/8/8/5PPP/R5K1 w - - 0 1',
    goal: LessonGoal.keepAdvantage,
    targetMoves: 12,
    difficulty: 2,
  ),
  PositionLesson(
    id: 'wrong-rook-pawn',
    category: 'endgame',
    title: 'Wrong bishop and rook pawn',
    tagline: 'Run to the corner the bishop can never cover',
    concept:
        'A bishop and a rook pawn (an a- or h-pawn) cannot win if the '
        'bishop does not control the promotion square. Here White\'s '
        'pawn queens on h8, a dark square, and the white bishop runs on '
        'light squares. If the black king reaches the corner, nothing can '
        'drive it out: the bishop cannot attack it there, and the king '
        'just shuffles between h8 and the squares next to it. At worst '
        'White stalemates you.\n\n'
        'So the defence is a race to the corner. Go straight for h8, and '
        'step on dark squares the bishop cannot block. Once you are on h8 '
        'or next to it, stay there and never step out. Do not try to win '
        'the pawn by leaving the corner: the draw is yours as long as the '
        'king stays put.',
    tips: [
      'Run with your king to h8, the corner the light bishop cannot '
          'control.',
      'Prefer dark squares on the way; the light bishop cannot check you '
          'there.',
      'Once in the corner, shuffle between h8, g8 and h7 or g7 and never '
          'leave.',
    ],
    fen: '8/4k3/8/7P/8/3B4/5K2/8 b - - 0 1',
    goal: LessonGoal.draw,
    targetMoves: 12,
    difficulty: 2,
  ),
  PositionLesson(
    id: 'convert-extra-piece',
    category: 'middlegame',
    title: 'Converting an extra piece',
    tagline: 'Trade pieces, not pawns, and the win comes by itself',
    concept:
        'You are a whole knight up. The hardest part of winning a won '
        'position is not getting careless. Every trade of pieces makes '
        'your extra knight count for more: with fewer pieces on the board, '
        'Black has fewer ways to create counterplay or attack your king.\n\n'
        'So offer trades of rooks and queens whenever you can, keep your '
        'king safe, and do not grab pawns if it lets Black\'s pieces become '
        'active. Keep all your pieces protected, because a blunder is the '
        'only way to throw this away.',
    tips: [
      'Offer to trade queens and rooks. Every trade helps the side with '
          'more material.',
      'Before each move, check that none of your pieces are left '
          'undefended.',
      'Do not trade pawns needlessly; you will need them to make a queen '
          'later.',
    ],
    fen: 'r1bq1rk1/pp3ppp/2p5/3p4/3P4/2N2N2/PP3PPP/R2Q1RK1 w - - 0 1',
    goal: LessonGoal.keepAdvantage,
    targetMoves: 12,
    difficulty: 1,
  ),
  PositionLesson(
    id: 'knight-outpost',
    category: 'middlegame',
    title: 'The knight outpost',
    tagline: 'A knight on d5 that no pawn can ever chase away',
    concept:
        'Your knight on d5 sits on an outpost: a square deep in enemy '
        'territory that no black pawn can attack, because Black\'s c- and '
        'e-pawns have already moved past it. From d5 the knight eyes c7, '
        'e7, b6 and f6, and Black\'s bishop on g7 is blocked by its own pawn '
        'on e5, so it can never challenge the knight.\n\n'
        'This is the classic good knight against a bad bishop. Keep the '
        'knight on d5, put your rooks on the open files (c- and d-files) '
        'and slowly press against d6. Do not trade the knight for the '
        'bishop: that would give Black their worst piece\'s freedom back.',
    tips: [
      'Keep the knight on d5. Only move it if it wins something concrete.',
      'Bring your rooks to the c- and d-files and pressure the backward '
          'pawn on d6.',
      'If Black plays ...f5, think about whether to capture or keep the '
          'centre closed.',
    ],
    fen: 'r4rk1/1p3pbp/p2p2p1/3Np3/4P3/8/PPP2PPP/R4RK1 w - - 0 1',
    goal: LessonGoal.keepAdvantage,
    targetMoves: 10,
    difficulty: 2,
  ),
  PositionLesson(
    id: 'opposite-side-attack',
    category: 'middlegame',
    title: 'Pawn storm on opposite sides',
    tagline: 'Castled on opposite wings? It\'s a race. Be first.',
    concept:
        'This is the Yugoslav Attack against the Sicilian Dragon. You '
        'castled queenside, Black castled kingside, so both sides attack '
        'the enemy king with their pawns. Pushing your own pawns does not '
        'expose your king, so the race is on.\n\n'
        'White\'s recipe is famous: push h4-h5 to open the h-file, trade '
        'off Black\'s strong Dragon bishop with Bh6, and bring the queen '
        'to h6 or the rook down the h-file. Speed matters more than '
        'material here. A pawn sacrificed to open a file is a good '
        'investment if it reaches the king first.',
    tips: [
      'Push h4-h5 and open the h-file, even at the cost of a pawn.',
      'Trade the Dragon bishop with Bh6. Without it, Black\'s king has no '
          'guard.',
      'Watch the c-file: Black\'s counterattack comes there, so keep c3 '
          'and b2 covered.',
    ],
    fen: '2rq1rk1/pp1bppbp/3p1np1/4n3/3NP1PP/2N1BP2/PPPQ4/2KR1B1R w - - 1 12',
    goal: LessonGoal.keepAdvantage,
    targetMoves: 10,
    difficulty: 3,
  ),
];
