import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:ludo_club/providers/game_provider.dart';
import 'package:ludo_club/models/game_state.dart';
import 'package:ludo_club/models/ludo_objects.dart';
import 'package:ludo_club/services/ai_service.dart';
import 'package:ludo_club/ui/game_screen.dart';
import 'package:ludo_club/constants/game_constants.dart';
import 'package:ludo_club/models/game_rules.dart';

class QuickPlayScreen extends StatefulWidget {
  const QuickPlayScreen({super.key, this.onStart});

  /// Optional callback when tapping "Start Quick Game".
  final void Function({
    required String name,
    required Color color,
    required int totalPlayers,
    required AIDifficulty difficulty,
  })? onStart;

  @override
  State<QuickPlayScreen> createState() => _QuickPlayScreenState();
}

class _QuickPlayScreenState extends State<QuickPlayScreen> {
  final TextEditingController _nameCtrl = TextEditingController();
  final List<Color> _uiColors = const [
    Color(0xFFEF4444),
    Color(0xFF22C55E),
    Color(0xFF3B82F6),
    Color(0xFFFACC15),
  ];
  final List<PlayerColor> _playerColors = const [
    PlayerColor.red,
    PlayerColor.green,
    PlayerColor.blue,
    PlayerColor.yellow,
  ];
  int _selectedColorIndex = 0;
  int _totalPlayers = 3; // 2..4
  AIDifficulty _difficulty = AIDifficulty.intermediate;
  GameRules _rules = GameRules.standard;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  TextStyle get _titleStyle =>
      GoogleFonts.poppins(fontWeight: FontWeight.w700, color: Colors.white);

  TextStyle get _bodyStyle =>
      GoogleFonts.poppins(fontWeight: FontWeight.w400, color: Colors.white);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headline = _titleStyle.copyWith(fontSize: 24);
    final bgGradient = const LinearGradient(
      colors: [Color(0xFF5D4BFF), Color(0xFF2EB9FF)],
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(gradient: bgGradient),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
                child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.maybePop(context),
                          tooltip: 'Back',
                        ),
                        Expanded(
                          child: Text('Quick Play',
                              textAlign: TextAlign.center, style: headline),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                    const SizedBox(height: 12),

                    _GlassCard(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const Icon(Icons.flash_on, color: Color(0xFFFFD700), size: 40),
                          const SizedBox(height: 8),
                          _UnderlinedAccentTitle('Quick Play',
                              textStyle: _titleStyle.copyWith(
                                fontSize: 28,
                                letterSpacing: 0.2,
                              )),
                          const SizedBox(height: 8),
                          Text('Jump right into the action against AI opponents!',
                              style: _bodyStyle.copyWith(color: Colors.white.withValues(alpha: .85))),
                        ],
                      ),
                    ),

              const SizedBox(height: 16),

                    _SectionCard(
                      titleIcon: Icons.person,
                      title: 'Player Settings',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                            controller: _nameCtrl,
                            style: GoogleFonts.poppins(),
                        decoration: InputDecoration(
                              hintText: 'Your Name',
                              prefixIcon: const Icon(Icons.account_circle),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                          border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text('Your Color',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF4B5563),
                                fontWeight: FontWeight.w500,
                              )),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: List.generate(_uiColors.length, (i) {
                              final selected = i == _selectedColorIndex;
                              return Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  _ColorCircle(
                                    color: _uiColors[i],
                                    selected: selected,
                                    onTap: () => setState(() => _selectedColorIndex = i),
                                  ),
                                  if (selected)
                                    Positioned(
                                      right: -6,
                                      top: -6,
                            child: Container(
                                        padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(999),
                                          boxShadow: const [
                                                                                 BoxShadow(
                                              blurRadius: 6,
                                              offset: Offset(0, 2),
                                              color: Color(0x1A000000),
                                            )
                                          ],
                                        ),
                                        child: const Icon(Icons.check_circle,
                                            color: Colors.green, size: 20),
                                      ),
                                    ),
                                ],
                              );
                            }),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

                    _SectionCard(
                      titleIcon: Icons.smart_toy,
                      title: 'AI Opponents',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Players: $_totalPlayers',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF4B5563),
                                fontWeight: FontWeight.w500,
                              )),
                          const SizedBox(height: 10),
                          _GradientSlider(
                            value: _totalPlayers.toDouble(),
                            min: 2,
                            max: 4,
                            divisions: 2,
                            label: '$_totalPlayers',
                            onChanged: (v) => setState(() => _totalPlayers = v.round()),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${_totalPlayers - 1} AI opponent(s)',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF6B7280),
                              fontSize: 12.5,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text('AI Difficulty',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF4B5563),
                                fontWeight: FontWeight.w500,
                              )),
                          const SizedBox(height: 10),
                          _DifficultySegmented(
                            value: _difficulty,
                            onChanged: (d) => setState(() => _difficulty = d),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _difficulty == AIDifficulty.beginner
                                ? 'Friendly AI with simple moves'
                                : _difficulty == AIDifficulty.intermediate
                                    ? 'Strategic AI with blocking and capturing'
                                    : 'Expert AI with advanced tactics',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF6B7280),
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),

              const SizedBox(height: 16),

                    _SectionCard(
                      titleIcon: Icons.rule,
                      title: 'Rules',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Select rule preset',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF4B5563),
                                fontWeight: FontWeight.w500,
                              )),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<_RulesPreset>(
                            initialValue: _RulesPreset.standard,
                            items: const [
                              DropdownMenuItem(value: _RulesPreset.standard, child: Text('Standard')),
                              DropdownMenuItem(value: _RulesPreset.quickPlay, child: Text('Quick Play')),
                              DropdownMenuItem(value: _RulesPreset.beginner, child: Text('Beginner')),
                              DropdownMenuItem(value: _RulesPreset.expert, child: Text('Expert')),
                              DropdownMenuItem(value: _RulesPreset.chaos, child: Text('Chaos')),
                            ],
                            borderRadius: BorderRadius.circular(12),
                            onChanged: (preset) {
                              if (preset == null) return;
                              setState(() {
                                _rules = _mapPreset(preset);
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _rulesDescription(_rules),
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF6B7280),
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    SizedBox(
                      width: double.infinity,
                      child: _ElevatedBigButton(
                        icon: Icons.play_arrow,
                        label: 'Start Quick Game',
                        onPressed: _onStartPressed,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onStartPressed() {
    final selectedPlayerColor = _playerColors[_selectedColorIndex];
    final enteredName = _nameCtrl.text.trim();
    final humanName = enteredName.isEmpty ? 'You' : enteredName;

    widget.onStart?.call(
      name: humanName,
      color: _uiColors[_selectedColorIndex],
      totalPlayers: _totalPlayers,
      difficulty: _difficulty,
    );

    final List<Player> players = [];
    players.add(Player(
      id: 'human_player',
      name: humanName,
      color: selectedPlayerColor,
      pieces: List.generate(
        GameConstants.tokensPerPlayer,
        (j) => Piece(selectedPlayerColor, j,
            const PiecePosition(GameState.basePosition)),
      ),
    ));

    final remainingColors = _playerColors
        .where((c) => c != selectedPlayerColor)
        .take(_totalPlayers - 1)
        .toList();

    for (int i = 0; i < remainingColors.length; i++) {
      final c = remainingColors[i];
      players.add(Player(
        id: 'ai_player_${i + 1}',
        name: '${_difficulty.name[0].toUpperCase()}${_difficulty.name.substring(1)} AI ${i + 1}',
        type: PlayerType.ai,
        color: c,
        aiDifficulty: _difficulty,
        pieces: List.generate(
          GameConstants.tokensPerPlayer,
          (j) => Piece(c, j, const PiecePosition(GameState.basePosition)),
        ),
      ));
    }

    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    gameProvider.setRules(_rules);
    gameProvider.startNewGame(players);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const GameScreen()),
    );
  }
}

enum _RulesPreset { standard, quickPlay, beginner, expert, chaos }

GameRules _mapPreset(_RulesPreset preset) {
  switch (preset) {
    case _RulesPreset.standard:
      return GameRules.standard;
    case _RulesPreset.quickPlay:
      return GameRules.quickPlay;
    case _RulesPreset.beginner:
      return GameRules.beginner;
    case _RulesPreset.expert:
      return GameRules.expert;
    case _RulesPreset.chaos:
      return GameRules.chaos;
  }
}

String _rulesDescription(GameRules rules) {
  return 'Exact finish: ${rules.exactRollToFinish ? 'On' : 'Off'} · '
      'Extra turn on 6: ${rules.extraTurnOnSix ? 'On' : 'Off'} · '
      'Extra turn on capture: ${rules.extraTurnOnCapture ? 'On' : 'Off'}';
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                blurRadius: 8,
                offset: Offset(0, 4),
                color: Color(0x1A000000),
              ),
              BoxShadow(
                blurRadius: 6,
                offset: Offset(0, 2),
                color: Color(0x1A000000),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.titleIcon,
    required this.child,
  });

  final String title;
  final IconData titleIcon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            blurRadius: 8,
            offset: Offset(0, 4),
            color: Color(0x1A000000),
          ),
          BoxShadow(
            blurRadius: 6,
            offset: Offset(0, 2),
            color: Color(0x1A000000),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(titleIcon, color: const Color(0xFF374151)),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF374151),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _ColorCircle extends StatelessWidget {
  const _ColorCircle({
    required this.color,
    required this.onTap,
    this.selected = false,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: selected ? 1.08 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                blurRadius: 8,
                offset: Offset(0, 4),
                color: Color(0x1A000000),
              ),
              BoxShadow(
                blurRadius: 6,
                offset: Offset(0, 2),
                color: Color(0x1A000000),
              ),
            ],
            border: Border.all(
              color: Colors.white,
              width: selected ? 3 : 2,
            ),
          ),
        ),
      ),
    );
  }
}

class _UnderlinedAccentTitle extends StatelessWidget {
  const _UnderlinedAccentTitle(this.text, {required this.textStyle});

  final String text;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(text, style: textStyle),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ],
    );
  }
}

class _GradientSlider extends StatelessWidget {
  const _GradientSlider({
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.label,
  });

  final double value;
  final double min;
  final double max;
  final int? divisions;
  final String? label;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final percent = (value - min) / (max - min);
      return Stack(
        alignment: Alignment.centerLeft,
        children: [
          Container(
            height: 10,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Container(
            height: 10,
            width: constraints.maxWidth * percent.clamp(0.0, 1.0),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF60A5FA), Color(0xFF60A5FA)],
              ),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackShape: const RectangularSliderTrackShape(),
              trackHeight: 0,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
            ),
            child: Slider(
              value: value,
              onChanged: onChanged,
              min: min,
              max: max,
              divisions: divisions,
              label: label,
            ),
          ),
        ],
      );
    });
  }
}

class _DifficultySegmented extends StatelessWidget {
  const _DifficultySegmented({
    required this.value,
    required this.onChanged,
  });

  final AIDifficulty value;
  final ValueChanged<AIDifficulty> onChanged;

  @override
  Widget build(BuildContext context) {
    final entries = <(String, AIDifficulty)>[
      ('Beginner', AIDifficulty.beginner),
      ('Intermediate', AIDifficulty.intermediate),
      ('Expert', AIDifficulty.expert),
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          for (final (label, diff) in entries)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(2.0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: value == diff ? const Color(0xFF3B82F6) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: value == diff
                        ? const [
                            BoxShadow(
                              blurRadius: 8,
                              offset: Offset(0, 4),
                              color: Color(0x1A000000),
                            ),
                          ]
                        : null,
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => onChanged(diff),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Center(
                        child: Text(
                          label,
                          style: GoogleFonts.poppins(
                            color: value == diff ? Colors.white : const Color(0xFF374151),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ElevatedBigButton extends StatelessWidget {
  const _ElevatedBigButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 120),
      scale: 1.0,
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            label,
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF7A1A),
          foregroundColor: Colors.white,
          shadowColor: const Color(0x33000000),
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.pressed)
                ? const Color(0xFFFF7A1A).withValues(alpha: .85)
                : null,
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }
}
