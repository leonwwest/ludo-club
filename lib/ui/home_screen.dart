import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ludo_club/providers/game_provider.dart';
import 'package:ludo_club/models/game_state.dart';
import 'package:ludo_club/models/ludo_objects.dart';
import 'package:ludo_club/ui/game_screen.dart';
import 'package:ludo_club/ui/quick_play_screen.dart';
import 'package:ludo_club/utils/color_utils.dart';
import 'package:ludo_club/constants/game_constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  List<TextEditingController> _nameControllers = [];
  int _playerCount = 2;

  final List<PlayerColor> _availableColors = [
    PlayerColor.red,
    PlayerColor.green,
    PlayerColor.blue,
    PlayerColor.yellow,
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _nameControllers = List.generate(
      _playerCount,
      (index) => TextEditingController(text: 'Player ${index + 1}'),
    );
  }

  @override
  void dispose() {
    for (var controller in _nameControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addPlayer() {
    if (_playerCount < 4) {
      setState(() {
        _playerCount++;
        _nameControllers
            .add(TextEditingController(text: 'Player $_playerCount'));
      });
    }
  }

  void _removePlayer() {
    if (_playerCount > 2) {
      setState(() {
        _nameControllers.last.dispose();
        _nameControllers.removeLast();
        _playerCount--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final headline = GoogleFonts.poppins(
      fontWeight: FontWeight.w700,
      color: Colors.white,
      fontSize: 24,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF5D4BFF), Color(0xFF2EB9FF)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    // Top bar with back and title
                    Row(
                      children: [
                        IconButton(
                          icon:
                              const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.maybePop(context),
                          tooltip: 'Back',
                        ),
                        Expanded(
                          child: Text('Ludo Club',
                              textAlign: TextAlign.center, style: headline),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Hero card
                    _GlassCard(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const Icon(Icons.settings,
                              color: Color(0xFFFFD700), size: 40),
                          const SizedBox(height: 8),
                          Text(
                            'Game Settings',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 28,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Players section
                    _SectionCard(
                      titleIcon: Icons.group,
                      title: 'Players',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...List.generate(_playerCount, (index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Row(
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    margin: const EdgeInsets.only(right: 12),
                                    decoration: BoxDecoration(
                                      color: ColorUtils.getPrimaryColor(
                                          _availableColors[index]),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 2),
                                      boxShadow: const [
                                        BoxShadow(
                                          blurRadius: 6,
                                          offset: Offset(0, 2),
                                          color: Color(0x1A000000),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: TextField(
                                      controller: _nameControllers[index],
                                      style: GoogleFonts.poppins(),
                                      decoration: InputDecoration(
                                        hintText:
                                            'Player ${index + 1} (${_getColorName(_availableColors[index])})',
                                        filled: true,
                                        fillColor: Colors.white,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                vertical: 14, horizontal: 12),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          borderSide: const BorderSide(
                                              color: Color(0xFFD1D5DB)),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          borderSide: const BorderSide(
                                              color: Color(0xFF3B82F6),
                                              width: 2),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed:
                                      _playerCount > 2 ? _removePlayer : null,
                                  icon: const Icon(Icons.remove_circle_outline),
                                  label: const Text('Remove Player'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF9CA3AF),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed:
                                      _playerCount < 4 ? _addPlayer : null,
                                  icon: const Icon(Icons.add_circle_outline),
                                  label: const Text('Add Player'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF22C55E),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // CTAs
                    SizedBox(
                      width: double.infinity,
                      child: _ElevatedBigButton(
                        icon: Icons.flash_on,
                        label: 'Quick Play vs AI',
                        onPressed: _goToQuickPlay,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: _ElevatedBigButton(
                        icon: Icons.settings,
                        label: 'Custom Game',
                        onPressed: _startGame,
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

  void _goToQuickPlay() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const QuickPlayScreen(),
      ),
    );
  }

  void _startGame() {
    // Validate player count
    if (_playerCount < 2 || _playerCount > 4) {
      _showErrorDialog('Please select 2-4 players');
      return;
    }

    // Validate that we have enough controllers
    if (_nameControllers.length < _playerCount) {
      _showErrorDialog('Player setup error. Please try again.');
      return;
    }

    final List<Player> players = [];
    for (int i = 0; i < _playerCount; i++) {
      final playerName = _nameControllers[i].text.trim();
      players.add(Player(
        id: 'player${i + 1}',
        name: playerName.isNotEmpty ? playerName : 'Player ${i + 1}',
        color: _availableColors[i],
        pieces: List.generate(
            GameConstants.tokensPerPlayer,
            (j) => Piece(_availableColors[i], j,
                const PiecePosition(GameState.basePosition))),
      ));
    }

    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    gameProvider.startNewGame(players);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const GameScreen(),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _getColorName(PlayerColor playerColor) {
    switch (playerColor) {
      case PlayerColor.red:
        return 'Red';
      case PlayerColor.green:
        return 'Green';
      case PlayerColor.blue:
        return 'Blue';
      case PlayerColor.yellow:
        return 'Yellow';
    }
  }
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
            style:
                GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: label == 'Quick Play vs AI'
              ? const Color(0xFFFF7A1A)
              : const Color(0xFF3B82F6),
          foregroundColor: Colors.white,
          shadowColor: const Color(0x33000000),
          elevation: 6,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.pressed)
                ? (label == 'Quick Play vs AI'
                        ? const Color(0xFFFF7A1A)
                        : const Color(0xFF3B82F6))
                    .withValues(alpha: .85)
                : null,
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }
}
