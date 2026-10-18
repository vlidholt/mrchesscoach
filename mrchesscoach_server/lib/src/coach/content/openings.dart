/// Curated opening courses: a main line per opening with a comment on every
/// move (both sides), validated by `test/unit/openings_content_test.dart`.
library;

import 'content_types.dart';

const openingCourses = <OpeningCourse>[
  // ---------------------------------------------------------------- White
  OpeningCourse(
    id: 'italian-game',
    name: 'Italian Game',
    eco: 'C53',
    side: StudentSide.white,
    level: 'Beginner',
    lichessFamily: 'Italian_Game',
    tagline: 'Classical development and a slow, safe squeeze',
    summary:
        'The Italian Game develops the bishop to c4, where it eyes the '
        "f7-square, the weakest point in Black's camp. In the quiet Giuoco "
        'Piano setup with c3 and d3, White builds a solid centre first and '
        'only strikes with d4 when the pieces are ready. It suits players who '
        'want natural, easy-to-learn development and long manoeuvring games.',
    ideas: [
      'Every piece goes to a natural square, so the plans are easy to learn.',
      'The c3-d3 pawn chain keeps the centre solid and prepares a later d4.',
      'The light-squared bishop on the a2-g8 diagonal keeps pressure on f7.',
      'Typical plans are Nbd2-f1-g3, h3 and a timely d4 or a kingside push.',
      'White castles early, so the king is safe while the game builds up.',
    ],
    moves: [
      OpeningMove(
        'e4',
        'White takes the centre, frees the bishop on f1 and the queen, and '
            'controls d5 and f5.',
      ),
      OpeningMove(
        'e5',
        'Black claims an equal share of the centre and opens lines for the '
            'f8-bishop and the queen.',
      ),
      OpeningMove(
        'Nf3',
        'The knight develops with tempo by attacking the e5-pawn.',
        arrows: ['f3e5'],
      ),
      OpeningMove(
        'Nc6',
        'Black defends e5 while developing a piece toward the centre.',
      ),
      OpeningMove(
        'Bc4',
        'The bishop takes the active a2-g8 diagonal and aims at f7, which only '
            'the black king protects.',
        arrows: ['c4f7'],
      ),
      OpeningMove(
        'Bc5',
        'Black mirrors White: the bishop eyes f2, the weak point in the white '
            'camp.',
        arrows: ['c5f2'],
      ),
      OpeningMove(
        'c3',
        'White prepares the central break d4, which would also hit the bishop '
            'on c5 and gain space.',
        arrows: ['d2d4'],
      ),
      OpeningMove(
        'Nf6',
        'Black develops and counterattacks the e4-pawn, which is now '
            'undefended.',
        arrows: ['f6e4'],
      ),
      OpeningMove(
        'd3',
        'The quiet approach: d3 defends e4 calmly and keeps the centre closed '
            'until White is fully developed.',
      ),
      OpeningMove(
        'd6',
        'Black supports e5 and opens the c8-bishop, keeping a solid, symmetrical '
            'position.',
      ),
      OpeningMove(
        'O-O',
        'White tucks the king away and connects the rook to the centre.',
      ),
      OpeningMove(
        'O-O',
        'Black castles too; both kings are safe and the manoeuvring battle '
            'begins.',
      ),
      OpeningMove(
        'Re1',
        'The rook supports e4 and prepares d3-d4, ready for the e-file to '
            'open.',
        arrows: ['d3d4'],
      ),
      OpeningMove(
        'a6',
        'Black makes room on a7 for the bishop, so a later d4 will not hit it '
            "with tempo, and takes the b5-square from White's bishop.",
      ),
      OpeningMove(
        'Bb3',
        'The bishop steps back in advance, out of reach of ...Na5 and ...b5, '
            'while keeping its aim at f7.',
        arrows: ['b3f7'],
      ),
      OpeningMove(
        'Ba7',
        'Black does the same: from a7 the bishop still bites at f2 and is safe '
            'from d4. White continues with h3 and Nbd2-f1-g3.',
        arrows: ['a7f2'],
      ),
    ],
  ),
  OpeningCourse(
    id: 'ruy-lopez',
    name: 'Ruy Lopez',
    eco: 'C88',
    side: StudentSide.white,
    level: 'Intermediate',
    lichessFamily: 'Ruy_Lopez',
    tagline: 'Pressure on e5 that lasts the whole game',
    summary:
        'The Ruy Lopez, or Spanish Game, attacks the knight that defends e5 '
        'and builds long-term pressure on the black centre. In the Closed '
        'main line White castles, supports e4 with Re1 and prepares d4 with '
        'c3. It has been a top-level favourite for centuries and suits players '
        'who enjoy rich strategic middlegames.',
    ideas: [
      'Bb5 hits the defender of e5, so Black is under pressure from move three.',
      'After c3 and d4 White gets a broad, mobile pawn centre.',
      'The bishop retreats to b3 and later c2, staying aimed at the kingside.',
      'The knight manoeuvre Nbd2-f1-g3 brings extra force to the kingside.',
      'The positions are rich but safe, which makes it a lifelong repertoire.',
    ],
    moves: [
      OpeningMove(
        'e4',
        'White occupies the centre and opens lines for the queen and the '
            'f1-bishop.',
      ),
      OpeningMove('e5', 'Black stakes an equal claim in the centre.'),
      OpeningMove(
        'Nf3',
        'The knight develops and attacks e5 right away.',
        arrows: ['f3e5'],
      ),
      OpeningMove(
        'Nc6',
        'Black defends the e5-pawn with a natural developing move.',
      ),
      OpeningMove(
        'Bb5',
        'The Spanish bishop attacks the knight that guards e5, creating '
            'pressure that lasts deep into the middlegame.',
        arrows: ['b5c6', 'c6e5'],
      ),
      OpeningMove(
        'a6',
        'The Morphy Defence: Black asks the bishop where it is going. Bxc6 '
            'does not win e5 yet, because the queen can win the pawn on e4 back.',
      ),
      OpeningMove(
        'Ba4',
        'White keeps the bishop and the pressure on c6 instead of exchanging.',
        arrows: ['a4c6'],
      ),
      OpeningMove(
        'Nf6',
        'Black develops and counterattacks the e4-pawn.',
        arrows: ['f6e4'],
      ),
      OpeningMove(
        'O-O',
        'White castles instead of defending e4: after ...Nxe4, Re1 or d4 wins '
            'the pawn back with active play.',
      ),
      OpeningMove(
        'Be7',
        'The Closed Ruy Lopez: Black prepares to castle and keeps a solid, '
            'flexible position.',
      ),
      OpeningMove(
        'Re1',
        'The rook defends e4, which renews the threat Bxc6 followed by Nxe5, '
            'winning a pawn.',
        arrows: ['a4c6', 'f3e5'],
      ),
      OpeningMove(
        'b5',
        'Black ends the pressure on c6 for good by driving the bishop away and '
            'gains queenside space.',
        arrows: ['b5a4'],
      ),
      OpeningMove(
        'Bb3',
        'The bishop retreats to the excellent a2-g8 diagonal, aiming at f7.',
        arrows: ['b3f7'],
      ),
      OpeningMove(
        'd6',
        'Black solidly supports e5 and opens the diagonal of the c8-bishop.',
      ),
      OpeningMove(
        'c3',
        'White prepares d4 to build a big centre and makes c2 available as a '
            'retreat square for the bishop.',
        arrows: ['d2d4', 'b3c2'],
      ),
      OpeningMove(
        'O-O',
        'Black castles. White usually plays h3 next, to stop ...Bg4 before '
            'pushing d4.',
        arrows: ['h2h3', 'd2d4'],
      ),
    ],
  ),
  OpeningCourse(
    id: 'scotch-game',
    name: 'Scotch Game',
    eco: 'C45',
    side: StudentSide.white,
    level: 'Beginner',
    lichessFamily: 'Scotch_Game',
    tagline: 'Open the centre on move three and play fast',
    summary:
        'In the Scotch Game White strikes with d4 on the third move and opens '
        'the centre at once. After the exchange on d4 White gets free piece '
        'play and a lasting space edge, while the main line with 6.e5 leaves '
        'Black with doubled c-pawns. It suits players who like open positions '
        'and clear plans without a lot of theory.',
    ideas: [
      'The early d4 opens lines quickly, so the pieces become active at once.',
      'After Nxc6 bxc6 Black is left with doubled, isolated-looking c-pawns.',
      'The e5-pawn gains space and takes the f6-square from the black knight.',
      'It avoids the long manoeuvring theory of the Ruy Lopez and Italian.',
      'Kasparov revived it at world-championship level, so it is fully sound.',
    ],
    moves: [
      OpeningMove(
        'e4',
        'White takes the centre and frees the kingside pieces.',
      ),
      OpeningMove('e5', 'Black answers symmetrically and contests the centre.'),
      OpeningMove(
        'Nf3',
        'The knight develops and attacks the e5-pawn.',
        arrows: ['f3e5'],
      ),
      OpeningMove('Nc6', 'Black defends e5 and develops a knight.'),
      OpeningMove(
        'd4',
        'The Scotch: White hits e5 a second time and opens the centre '
            'immediately.',
        arrows: ['d4e5'],
      ),
      OpeningMove(
        'exd4',
        'Black takes, because the e5-pawn could not be held comfortably.',
      ),
      OpeningMove(
        'Nxd4',
        'White recaptures with a strong central knight and has more space.',
      ),
      OpeningMove(
        'Nf6',
        'Black develops with an attack on the e4-pawn.',
        arrows: ['f6e4'],
      ),
      OpeningMove(
        'Nxc6',
        'White exchanges knights to double Black\'s c-pawns before pushing e5.',
      ),
      OpeningMove(
        'bxc6',
        'Black recaptures toward the centre; the doubled pawns still control '
            'd5 and the b-file opens for a rook.',
      ),
      OpeningMove(
        'e5',
        'White gains space with tempo, driving the knight away from f6.',
        arrows: ['e5f6'],
      ),
      OpeningMove(
        'Qe7',
        'Black pins the e5-pawn to the king, so exf6 is impossible, and '
            'attacks it, since no white piece defends it.',
        arrows: ['e7e5'],
      ),
      OpeningMove(
        'Qe2',
        'White defends e5 and unpins it, accepting that the queen blocks the '
            'f1-bishop for a while.',
      ),
      OpeningMove(
        'Nd5',
        'The knight jumps to an active central square.',
      ),
      OpeningMove(
        'c4',
        'White kicks the knight from its central square and gains space on '
            'the queenside.',
        arrows: ['c4d5'],
      ),
      OpeningMove(
        'Ba6',
        'A neat counter: the bishop pins the c4-pawn to the queen on e2, so '
            'the knight is safe for now. White usually continues with b3.',
        arrows: ['a6e2'],
      ),
    ],
  ),
  OpeningCourse(
    id: 'london-system',
    name: 'London System',
    eco: 'D02',
    side: StudentSide.white,
    level: 'Beginner',
    lichessFamily: 'London_System',
    tagline: 'One solid setup against almost anything',
    summary:
        'The London System is a setup rather than a line of theory: d4, Bf4, '
        'e3, Nf3, c3, Nbd2 and Bd3 against nearly every black defence. White '
        'builds an unbreakable pawn pyramid and then looks for Ne5 and a '
        'kingside attack. It suits players who want a reliable opening with '
        'little memorisation.',
    ideas: [
      'The same piece placement works against almost every black setup.',
      'The bishop develops to f4 before e3, so it is not locked inside.',
      'The c3-d4-e3 pyramid is very hard for Black to break down.',
      'Bd3 and a knight on e5 point straight at the black king.',
      'It is low-risk, so you reach a playable middlegame every time.',
    ],
    moves: [
      OpeningMove(
        'd4',
        'White takes the centre with the queen\'s pawn, which is already '
            'defended by the queen.',
      ),
      OpeningMove('d5', 'Black claims an equal share of the centre.'),
      OpeningMove(
        'Bf4',
        'The signature move: the dark-squared bishop develops before e3 so it '
            'will not be trapped behind the pawns.',
      ),
      OpeningMove(
        'Nf6',
        'Black develops the knight and controls e4.',
      ),
      OpeningMove(
        'e3',
        'White supports d4 and opens the way for the f1-bishop.',
      ),
      OpeningMove(
        'e6',
        'Black builds a solid centre and frees the f8-bishop.',
      ),
      OpeningMove(
        'Nf3',
        'The knight develops, guards d4 and eyes the e5-square.',
        arrows: ['f3e5'],
      ),
      OpeningMove(
        'c5',
        'Black challenges the d4-pawn, the most active plan against the '
            'London.',
        arrows: ['c5d4'],
      ),
      OpeningMove(
        'c3',
        'White completes the c3-d4-e3 pyramid, so an exchange on d4 can always '
            'be met by a pawn recapture.',
      ),
      OpeningMove(
        'Nc6',
        'Black adds more pressure on d4 and develops.',
        arrows: ['c6d4'],
      ),
      OpeningMove(
        'Nbd2',
        'The knight develops behind the pawns, supports a later e4 or Ne5, '
            'and keeps c3 protected.',
      ),
      OpeningMove(
        'Bd6',
        'Black offers to trade off White\'s best bishop.',
        arrows: ['d6f4'],
      ),
      OpeningMove(
        'Bg3',
        'White keeps the bishop. If Black takes on g3, hxg3 opens the h-file '
            'for the rook.',
      ),
      OpeningMove('O-O', 'Black puts the king in safety.'),
      OpeningMove(
        'Bd3',
        'The bishop takes the b1-h7 diagonal, aiming straight at the black '
            'king.',
        arrows: ['d3h7'],
      ),
      OpeningMove(
        'b6',
        'Black prepares ...Bb7 to fight for e4. White continues with Ne5 and '
            'Qf3 or Qe2 for kingside play.',
        arrows: ['f3e5'],
      ),
    ],
  ),
  OpeningCourse(
    id: 'queens-gambit-declined',
    name: "Queen's Gambit Declined",
    eco: 'D66',
    side: StudentSide.white,
    level: 'Intermediate',
    lichessFamily: 'Queens_Gambit_Declined',
    tagline: "Classical pressure on Black's centre",
    summary:
        "In the Queen's Gambit White offers the c-pawn to deflect Black's "
        "d-pawn from the centre. In the Orthodox Defence Black declines with "
        '...e6 and keeps a rock-solid centre, while White develops with Bg5 '
        'and Rc1 and pressures d5 and the c-file. It suits players who like '
        'clear, classical strategy with a small but lasting edge.',
    ideas: [
      'c4 attacks Black\'s centre with a wing pawn, keeping the d4-pawn.',
      'Bg5 pins the f6-knight, which is the main defender of d5.',
      'Rc1 prepares play on the half-open c-file after a later exchange.',
      'White can choose the minority attack or a central e4 later.',
      'The gambit is not a real gambit: the c4-pawn is easily regained.',
    ],
    moves: [
      OpeningMove('d4', 'White occupies the centre with a protected pawn.'),
      OpeningMove('d5', 'Black takes an equal share of the centre.'),
      OpeningMove(
        'c4',
        "The Queen's Gambit: White offers a wing pawn to lure the d5-pawn away "
            'from the centre.',
        arrows: ['c4d5'],
      ),
      OpeningMove(
        'e6',
        'Black declines and supports d5 with a pawn, keeping a strong centre.',
      ),
      OpeningMove(
        'Nc3',
        'The knight develops and adds a third attacker to d5.',
        arrows: ['c3d5'],
      ),
      OpeningMove('Nf6', 'Black adds a defender of d5 and develops.'),
      OpeningMove(
        'Bg5',
        'The bishop pins the f6-knight to the queen, weakening Black\'s '
            'control of d5 and e4.',
        arrows: ['g5d8'],
      ),
      OpeningMove(
        'Be7',
        'Black breaks the pin by placing the bishop between knight and queen, '
            'and prepares to castle.',
      ),
      OpeningMove(
        'e3',
        'White supports d4 and opens the diagonal of the f1-bishop.',
      ),
      OpeningMove('O-O', 'Black castles the king to safety.'),
      OpeningMove('Nf3', 'White develops the last minor piece toward e5.'),
      OpeningMove(
        'Nbd7',
        'The Orthodox Defence: the knight supports a later ...c5 or ...e5 '
            'break.',
      ),
      OpeningMove(
        'Rc1',
        'The rook moves to the c-file, which will open after an exchange on '
            'c4 or d5.',
      ),
      OpeningMove(
        'c6',
        'Black strengthens d5 and blunts the rook on the c-file.',
      ),
      OpeningMove(
        'Bd3',
        'White develops the bishop, aiming at h7 and preparing to castle.',
        arrows: ['d3h7'],
      ),
      OpeningMove(
        'dxc4',
        'Black takes on c4 to make White spend a tempo recapturing, then '
            'plans ...Nd5 to trade pieces and free the position.',
        arrows: ['f6d5'],
      ),
    ],
  ),
  OpeningCourse(
    id: 'english-opening',
    name: 'English Opening',
    eco: 'A29',
    side: StudentSide.white,
    level: 'Intermediate',
    lichessFamily: 'English_Opening',
    tagline: 'A Sicilian with an extra tempo',
    summary:
        'The English Opening starts with c4, controlling d5 from the flank '
        'instead of occupying the centre. Against 1...e5 White plays a '
        'Reversed Sicilian with a kingside fianchetto, so the bishop on g2 '
        'and the c-file put pressure on the queenside. It suits positional '
        'players who like flexible, manoeuvring games.',
    ideas: [
      'White fights for d5 from the side without committing the centre pawns.',
      'It is a Sicilian structure with colours reversed and an extra tempo.',
      'The g2-bishop rakes the long diagonal toward b7 and the queenside.',
      'A typical plan is a3 and b4 to expand on the queenside.',
      'It avoids most of the sharp theory of 1.e4 openings.',
    ],
    moves: [
      OpeningMove(
        'c4',
        'White controls d5 from the flank and keeps the centre pawns flexible.',
        arrows: ['c4d5'],
      ),
      OpeningMove(
        'e5',
        'Black takes central space; the position is now a Sicilian with '
            'colours reversed.',
      ),
      OpeningMove(
        'Nc3',
        'The knight develops and adds control of d5, the key square.',
        arrows: ['c3d5'],
      ),
      OpeningMove('Nf6', 'Black develops and also eyes d5 and e4.'),
      OpeningMove(
        'Nf3',
        'White develops and attacks the e5-pawn.',
        arrows: ['f3e5'],
      ),
      OpeningMove('Nc6', 'Black defends e5 with a developing move.'),
      OpeningMove(
        'g3',
        'White prepares Bg2, which will rake the long diagonal toward the '
            'queenside.',
      ),
      OpeningMove(
        'd5',
        "Black grabs the centre, playing White's side of an Open Sicilian "
            'with one tempo less.',
      ),
      OpeningMove(
        'cxd5',
        'White trades the wing pawn for a centre pawn, as in an Open Sicilian.',
      ),
      OpeningMove(
        'Nxd5',
        'Black recaptures with a centralised knight.',
      ),
      OpeningMove(
        'Bg2',
        'The bishop takes the long diagonal; once the f3-knight moves it will '
            'hit d5 and c6.',
        arrows: ['g2c6'],
      ),
      OpeningMove(
        'Nb6',
        'Black steps the knight off d5 to avoid exchanges and tactics on the '
            'long diagonal.',
      ),
      OpeningMove('O-O', 'White castles and keeps all options open.'),
      OpeningMove(
        'Be7',
        'Black develops quietly and prepares to castle.',
      ),
      OpeningMove(
        'd3',
        'White opens the c1-bishop and prepares Be3 and a queenside push with '
            'a3 and b4.',
        arrows: ['b2b4'],
      ),
      OpeningMove(
        'O-O',
        'Black castles. White will expand with a3, b4 and Rc1, pressing on '
            'the queenside.',
        arrows: ['a2a3', 'b2b4'],
      ),
    ],
  ),
  // ---------------------------------------------------------------- Black
  OpeningCourse(
    id: 'sicilian-najdorf',
    name: 'Sicilian Najdorf',
    eco: 'B90',
    side: StudentSide.black,
    level: 'Advanced',
    lichessFamily: 'Sicilian_Defense',
    tagline: 'The fighting choice of world champions',
    summary:
        'The Najdorf is the sharpest and most respected answer to 1.e4. Black '
        'trades the c-pawn for White\'s d-pawn, gets an extra central pawn and '
        'the half-open c-file, and uses ...a6 to prepare ...e5 and ...b5. It '
        'suits ambitious players who are ready to learn theory and play for a '
        'win with Black.',
    ideas: [
      'Black gains a central pawn majority and the half-open c-file.',
      '...a6 keeps White\'s pieces off b5 and prepares queenside expansion.',
      '...e5 grabs central space and pushes the d4-knight back.',
      'Opposite-side castling creates races where Black attacks on the queenside.',
      'It is unbalanced, so it is a great weapon when you need to win.',
    ],
    moves: [
      OpeningMove('e4', 'White takes the centre and opens lines.'),
      OpeningMove(
        'c5',
        'The Sicilian: Black fights for d4 with a wing pawn, creating an '
            'unbalanced game.',
        arrows: ['c5d4'],
      ),
      OpeningMove(
        'Nf3',
        'White develops and prepares d4 to open the centre.',
        arrows: ['d2d4'],
      ),
      OpeningMove(
        'd6',
        'Black controls e5 and prepares ...Nf6 without allowing e5.',
      ),
      OpeningMove(
        'd4',
        'The Open Sicilian: White breaks in the centre for fast development.',
      ),
      OpeningMove(
        'cxd4',
        'Black swaps a wing pawn for a centre pawn and opens the c-file.',
      ),
      OpeningMove(
        'Nxd4',
        'White recaptures with a strong centralised knight.',
      ),
      OpeningMove(
        'Nf6',
        'Black develops with an attack on e4.',
        arrows: ['f6e4'],
      ),
      OpeningMove(
        'Nc3',
        'White defends e4 and develops.',
      ),
      OpeningMove(
        'a6',
        'The Najdorf: Black takes b5 away from White\'s pieces and prepares '
            '...e5 and ...b5.',
        arrows: ['a6b5'],
      ),
      OpeningMove(
        'Be3',
        'The English Attack: White plans f3, Qd2, castling long and a kingside '
            'pawn storm with g4.',
        arrows: ['g2g4'],
      ),
      OpeningMove(
        'e5',
        'Black gains central space with tempo on the d4-knight. The d5-square '
            'becomes a hole that Black must control.',
        arrows: ['e5d4'],
      ),
      OpeningMove(
        'Nb3',
        'The knight retreats to b3, where it keeps an eye on c5 and d4.',
      ),
      OpeningMove(
        'Be6',
        'Black develops the bishop to fight for the key d5-square.',
        arrows: ['e6d5'],
      ),
      OpeningMove(
        'f3',
        'White secures e4, stops ...Ng4 hitting the bishop, and prepares g4.',
        arrows: ['g2g4'],
      ),
      OpeningMove(
        'Be7',
        'Black prepares to castle. Next come ...O-O, ...Nbd7 and ...b5 to '
            'attack on the queenside.',
        arrows: ['b7b5'],
      ),
    ],
  ),
  OpeningCourse(
    id: 'french-advance',
    name: 'French Defense: Advance',
    eco: 'C02',
    side: StudentSide.black,
    level: 'Intermediate',
    lichessFamily: 'French_Defense',
    tagline: 'Hit the base of the chain until it breaks',
    summary:
        'Against the Advance Variation White grabs space with e5, but the '
        'pawn chain needs the d4-pawn at its base. Black attacks d4 with '
        '...c5, ...Nc6, ...Qb6 and ...Nf5, forcing White onto the defensive. '
        'It suits patient players who like clear pawn-structure plans and '
        'counterattacking.',
    ideas: [
      'The pawn chain tells you the plan: attack its base on d4.',
      '...c5, ...Nc6, ...Qb6 and ...Nf5 pile up on d4 one after another.',
      'Qb6 also pressures b2, so White\'s c1-bishop is tied down.',
      'The knight goes via h6 to f5 because f6 is taken by the e5-pawn.',
      'Black\'s position is very solid, with a later ...f6 break in reserve.',
    ],
    moves: [
      OpeningMove('e4', 'White occupies the centre.'),
      OpeningMove(
        'e6',
        'The French: Black prepares ...d5 with pawn support.',
        arrows: ['d7d5'],
      ),
      OpeningMove('d4', 'White builds a classical two-pawn centre.'),
      OpeningMove(
        'd5',
        'Black challenges e4 straight away.',
        arrows: ['d5e4'],
      ),
      OpeningMove(
        'e5',
        'The Advance Variation: White gains space and takes f6 from the black '
            'knight.',
      ),
      OpeningMove(
        'c5',
        'Black strikes at d4, the base of White\'s pawn chain.',
        arrows: ['c5d4'],
      ),
      OpeningMove(
        'c3',
        'White supports d4 with a pawn so the chain stays intact.',
      ),
      OpeningMove(
        'Nc6',
        'Black adds a second attacker on d4.',
        arrows: ['c6d4'],
      ),
      OpeningMove('Nf3', 'White defends d4 and develops.'),
      OpeningMove(
        'Qb6',
        'The queen adds a third attacker on d4 and also hits b2, keeping the '
            'c1-bishop at home.',
        arrows: ['b6d4', 'b6b2'],
      ),
      OpeningMove(
        'Be2',
        "White prepares to castle. Bd3 would block the queen's defence of "
            'd4, so Be2 keeps the pawn protected.',
      ),
      OpeningMove(
        'cxd4',
        'Black opens the c-file and makes d4 a target that can only be '
            'defended by pieces.',
      ),
      OpeningMove('cxd4', 'White recaptures and keeps the pawn chain.'),
      OpeningMove(
        'Nh6',
        'The knight heads for f5 to hit d4 again, since f6 is controlled by '
            'the e5-pawn.',
        arrows: ['h6f5'],
      ),
      OpeningMove(
        'Nc3',
        'White develops. Bxh6 would give up the good bishop and hand Black the '
            'bishop pair.',
      ),
      OpeningMove(
        'Nf5',
        'Now d4 is attacked three times and defended twice. White usually '
            'answers Na4 to hit the queen.',
        arrows: ['f5d4', 'c6d4'],
      ),
    ],
  ),
  OpeningCourse(
    id: 'caro-kann-classical',
    name: 'Caro-Kann: Classical',
    eco: 'B19',
    side: StudentSide.black,
    level: 'Beginner',
    lichessFamily: 'Caro-Kann_Defense',
    tagline: 'Rock-solid structure with an active bishop',
    summary:
        'The Caro-Kann prepares ...d5 with ...c6, so Black can fight for the '
        'centre without locking in the light-squared bishop. In the Classical '
        'line that bishop develops to f5 before ...e6, and Black gets a sound '
        'pawn structure with no weaknesses. It suits players who want a safe, '
        'reliable answer to 1.e4.',
    ideas: [
      'Black\'s pawn structure is healthy and very hard to attack.',
      'The light-squared bishop gets out to f5 before ...e6 closes it in.',
      '...Nd7 controls e5 so White\'s knights cannot settle there.',
      'Black often castles long and plays ...c5 or ...e5 to free the game.',
      'Its endgames are good for Black, so simplifying is never a worry.',
    ],
    moves: [
      OpeningMove(
        'e4',
        'White takes the centre.',
      ),
      OpeningMove(
        'c6',
        'The Caro-Kann: Black prepares ...d5 while keeping the c8-bishop free.',
        arrows: ['d7d5'],
      ),
      OpeningMove('d4', 'White builds a broad pawn centre.'),
      OpeningMove(
        'd5',
        'Black challenges e4 with pawn support from c6.',
        arrows: ['d5e4'],
      ),
      OpeningMove('Nc3', 'White defends e4 with a developing move.'),
      OpeningMove(
        'dxe4',
        'Black gives up the centre for now to free the position and develop '
            'with tempo.',
      ),
      OpeningMove('Nxe4', 'White recaptures with a centralised knight.'),
      OpeningMove(
        'Bf5',
        'The Classical: the bishop develops outside the pawn chain and attacks '
            'the e4-knight.',
        arrows: ['f5e4'],
      ),
      OpeningMove(
        'Ng3',
        'White gains a tempo by attacking the bishop.',
        arrows: ['g3f5'],
      ),
      OpeningMove(
        'Bg6',
        'The bishop retreats but stays on the active b1-h7 diagonal.',
      ),
      OpeningMove(
        'h4',
        'White threatens h5 to trap or harass the bishop.',
        arrows: ['h4h5'],
      ),
      OpeningMove(
        'h6',
        'Black makes room on h7, so h5 can be met by a calm bishop retreat.',
        arrows: ['g6h7'],
      ),
      OpeningMove('Nf3', 'White develops and eyes the e5-square.'),
      OpeningMove(
        'Nd7',
        'Black controls e5 so the white knight cannot jump there.',
        arrows: ['d7e5'],
      ),
      OpeningMove(
        'h5',
        'White gains kingside space and cramps Black, though the pawn can '
            'become a target later.',
      ),
      OpeningMove(
        'Bh7',
        'The bishop stays on its diagonal. Black follows with ...Ngf6, ...e6 '
            'and often castles long.',
        arrows: ['e7e6'],
      ),
    ],
  ),
  OpeningCourse(
    id: 'slav-defense',
    name: 'Slav Defense',
    eco: 'D19',
    side: StudentSide.black,
    level: 'Intermediate',
    lichessFamily: 'Slav_Defense',
    tagline: "A sturdy answer to the Queen's Gambit",
    summary:
        "The Slav meets the Queen's Gambit with ...c6, defending d5 with a "
        'pawn and keeping the light-squared bishop free. In the main line '
        'Black takes on c4, develops the bishop to f5 and uses the b4-square '
        'for the other bishop. It suits players who want a solid but active '
        'defence against 1.d4.',
    ideas: [
      '...c6 supports d5 without blocking the c8-bishop.',
      'The bishop develops to f5 before ...e6, so it is never a bad piece.',
      'After a4 Black can use the b4-square for the bishop.',
      'The pawn structure is compact and has no weaknesses.',
      'Black often aims for ...Nbd7 and ...e5 or ...c5 to free the game.',
    ],
    moves: [
      OpeningMove('d4', 'White occupies the centre.'),
      OpeningMove('d5', 'Black takes an equal share of the centre.'),
      OpeningMove(
        'c4',
        "The Queen's Gambit: White attacks d5 with a wing pawn.",
        arrows: ['c4d5'],
      ),
      OpeningMove(
        'c6',
        'The Slav: d5 is supported by a pawn and the c8-bishop stays free.',
      ),
      OpeningMove('Nf3', 'White develops and controls e5.'),
      OpeningMove('Nf6', 'Black develops and guards d5.'),
      OpeningMove('Nc3', 'White develops and adds pressure on d5.'),
      OpeningMove(
        'dxc4',
        'Black takes the pawn, hoping to hold it with ...b5.',
        arrows: ['b7b5'],
      ),
      OpeningMove(
        'a4',
        'White stops ...b5 so the c4-pawn can be won back, at the cost of '
            'weakening b4.',
      ),
      OpeningMove(
        'Bf5',
        'The bishop develops outside the pawn chain and controls e4.',
        arrows: ['f5e4'],
      ),
      OpeningMove(
        'e3',
        'White prepares to recapture on c4 with the bishop.',
        arrows: ['f1c4'],
      ),
      OpeningMove(
        'e6',
        'Black frees the f8-bishop and gives up the c4-pawn calmly.',
      ),
      OpeningMove('Bxc4', 'White regains the pawn with a well-placed bishop.'),
      OpeningMove(
        'Bb4',
        'The bishop uses the b4 hole created by a4 and pins the c3-knight, '
            'keeping control of e4.',
        arrows: ['b4c3'],
      ),
      OpeningMove(
        'O-O',
        'White castles and prepares Qe2 and e4 to gain central space.',
        arrows: ['e3e4'],
      ),
      OpeningMove(
        'O-O',
        'Black castles too. Next come ...Nbd7 and ...Qe7, ready to meet e4.',
      ),
    ],
  ),
  OpeningCourse(
    id: 'kings-indian-defense',
    name: "King's Indian Defense",
    eco: 'E97',
    side: StudentSide.black,
    level: 'Advanced',
    lichessFamily: 'Kings_Indian_Defense',
    tagline: 'Let White build a centre, then attack the king',
    summary:
        "The King's Indian lets White build a big pawn centre and then hits "
        'back with ...e5. In the Classical main line the centre locks after '
        'd5, and the game becomes a race: White attacks on the queenside, '
        'Black storms the kingside with ...f5. It suits fighting players who '
        'enjoy sharp attacks and double-edged positions.',
    ideas: [
      'The fianchettoed bishop on g7 is a monster on the long diagonal.',
      'Black lets White take the centre, then strikes it with ...e5.',
      'When the centre locks, Black attacks with ...f5, ...f4 and ...g5.',
      'The positions are unbalanced, so it is a great weapon to play for a win.',
    ],
    moves: [
      OpeningMove('d4', 'White occupies the centre.'),
      OpeningMove(
        'Nf6',
        'Black develops and stops e4 for now, keeping the setup flexible.',
      ),
      OpeningMove('c4', 'White gains queenside space and controls d5.'),
      OpeningMove(
        'g6',
        'Black prepares to fianchetto the bishop on g7.',
      ),
      OpeningMove(
        'Nc3',
        'White develops and prepares e4.',
        arrows: ['e2e4'],
      ),
      OpeningMove(
        'Bg7',
        'The bishop takes the long diagonal, aiming at d4 and the queenside.',
        arrows: ['g7d4'],
      ),
      OpeningMove(
        'e4',
        'White builds a big centre with pawns on c4, d4 and e4.',
      ),
      OpeningMove(
        'd6',
        'Black controls e5 and prepares the central strike ...e5.',
      ),
      OpeningMove('Nf3', 'The Classical: White develops naturally.'),
      OpeningMove('O-O', 'Black castles before opening the position.'),
      OpeningMove('Be2', 'White develops and prepares to castle.'),
      OpeningMove(
        'e5',
        'Black hits the centre and challenges d4.',
        arrows: ['e5d4'],
      ),
      OpeningMove('O-O', 'White castles and keeps the tension.'),
      OpeningMove(
        'Nc6',
        'The Mar del Plata: Black piles on d4 and dares White to decide on '
            'the centre.',
        arrows: ['c6d4'],
      ),
      OpeningMove(
        'd5',
        'White closes the centre with tempo and plans to attack on the '
            'queenside with b4 and c5.',
        arrows: ['c4c5'],
      ),
      OpeningMove(
        'Ne7',
        'The knight reroutes toward the kingside. Black will play ...Ne8 or '
            '...Nd7 and then ...f5 to attack.',
        arrows: ['f7f5'],
      ),
    ],
  ),
  OpeningCourse(
    id: 'scandinavian-defense',
    name: 'Scandinavian Defense',
    eco: 'B01',
    side: StudentSide.black,
    level: 'Beginner',
    lichessFamily: 'Scandinavian_Defense',
    tagline: 'Hit e4 on move one and skip the theory',
    summary:
        'The Scandinavian challenges e4 on the very first move. After the '
        'queen recaptures on d5 it retreats to a5, where it is safe and pins '
        'White\'s knight, and Black builds a solid ...c6, ...Bf5, ...e6 setup. '
        'It suits players who want a simple, low-theory defence with clear '
        'piece play.',
    ideas: [
      'Black dictates the game from move one and avoids mainstream theory.',
      'The queen on a5 is safe and pins the c3-knight to the king.',
      'The c6-e6 structure is like a Caro-Kann: solid with no weaknesses.',
      'The light-squared bishop develops actively to f5 before ...e6.',
      'The setup is the same against most White systems, so it is easy to learn.',
    ],
    moves: [
      OpeningMove('e4', 'White takes the centre.'),
      OpeningMove(
        'd5',
        'The Scandinavian: Black challenges e4 immediately.',
        arrows: ['d5e4'],
      ),
      OpeningMove('exd5', 'White takes the pawn, the most testing reply.'),
      OpeningMove(
        'Qxd5',
        'Black recaptures with the queen, accepting a lost tempo later.',
      ),
      OpeningMove(
        'Nc3',
        'White develops with tempo by attacking the queen.',
        arrows: ['c3d5'],
      ),
      OpeningMove(
        'Qa5',
        'The queen moves to a safe square off the centre, from where it will '
            'pin the c3-knight once d2 is empty.',
      ),
      OpeningMove(
        'd4',
        'White builds the centre and frees the c1-bishop.',
      ),
      OpeningMove(
        'Nf6',
        'Black develops and controls e4 and d5.',
      ),
      OpeningMove('Nf3', 'White develops naturally.'),
      OpeningMove(
        'c6',
        'Black gives the queen a retreat to c7 or d8 and controls d5 and b5.',
      ),
      OpeningMove(
        'Bc4',
        'The bishop takes the active diagonal toward f7.',
        arrows: ['c4f7'],
      ),
      OpeningMove(
        'Bf5',
        'Black develops the bishop outside the pawn chain before ...e6.',
      ),
      OpeningMove(
        'Bd2',
        'White unpins the knight and threatens Nd5, a discovered attack on '
            'the queen.',
        arrows: ['c3d5', 'd2a5'],
      ),
      OpeningMove(
        'e6',
        'Black completes the solid pawn triangle and frees the f8-bishop.',
      ),
      OpeningMove(
        'Qe2',
        'White prepares to castle long and connects the rooks.',
      ),
      OpeningMove(
        'Bb4',
        'Black develops and pins the c3-knight against the d2-bishop. Next '
            'come ...Nbd7 and castling.',
        arrows: ['b4c3'],
      ),
    ],
  ),
];
