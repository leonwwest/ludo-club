import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ludo_club/ui/home_screen.dart';
import 'package:ludo_club/ui/quick_play_screen.dart';

/// Ludo Club - Landing Page (Flutter)
class LudoClubLandingPage extends StatefulWidget {
  const LudoClubLandingPage({super.key});

  @override
  State<LudoClubLandingPage> createState() => _LudoClubLandingPageState();
}

class _LudoClubLandingPageState extends State<LudoClubLandingPage>
    with SingleTickerProviderStateMixin {
  bool _menuOpen = false;

  void _goQuickPlay() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const QuickPlayScreen()),
    );
  }

  void _goCustomGame() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isSmall = width < 768;

    return Stack(
      children: [
        // Page content
        SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // HEADER / HERO
              Container(
                padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF4F46E5), Color(0xFF818CF8)],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Ludo Club',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: isSmall ? 48 : 72,
                              height: 1.05,
                              letterSpacing: -1.0,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Play, Compete, Enjoy.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: const Color(0xFFC7D2FE),
                              fontWeight: FontWeight.w500,
                              fontSize: isSmall ? 18 : 22,
                            ),
                          ),
                          const SizedBox(height: 40),
                          // HERO IMAGE from assets
                          ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Material(
                              elevation: 16,
                              shadowColor: Colors.black.withOpacity(0.35),
                              child: Image.asset(
                                'assets/images/ludo_board.png',
                                width: isSmall ? width - 32 : 560,
                                fit: BoxFit.cover,
                                alignment: Alignment.center,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          // CTA BUTTONS
                          Wrap(
                            spacing: 16,
                            runSpacing: 12,
                            alignment: WrapAlignment.center,
                            children: [
                              _PillButton(
                                label: 'Quick Play',
                                icon: Icons.bolt,
                                background: const Color(0xFFF97316),
                                foreground: Colors.white,
                                onPressed: _goQuickPlay,
                              ),
                              _PillButton(
                                label: 'Custom Game',
                                icon: Icons.tune,
                                background: const Color(0xFF3B82F6),
                                foreground: Colors.white,
                                onPressed: _goCustomGame,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Removed placeholder and footer
            ],
          ),
        ),

        // Floating Burger button (small screens only)
        if (isSmall)
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 12,
            child: _FrostedIconButton(
              icon: _menuOpen ? Icons.close : Icons.menu,
              onPressed: () => setState(() => _menuOpen = !_menuOpen),
            ),
          ),

        // Mobile Menu Overlay
        _MobileMenuOverlay(
          isVisible: _menuOpen,
          onClose: () => setState(() => _menuOpen = false),
        ),
      ],
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 22, color: foreground),
      label: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          label.toUpperCase(),
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
            color: foreground,
          ),
        ),
      ),
      style: ElevatedButton.styleFrom(
        elevation: 10,
        backgroundColor: background,
        foregroundColor: foreground,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        shape: const StadiumBorder(),
  shadowColor: Colors.black.withOpacity(0.25),
      ),
    );
  }
}

class _FrostedIconButton extends StatelessWidget {
  const _FrostedIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.2),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

class _MobileMenuOverlay extends StatelessWidget {
  const _MobileMenuOverlay({
    required this.isVisible,
    required this.onClose,
  });

  final bool isVisible;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !isVisible,
      child: AnimatedOpacity(
        opacity: isVisible ? 1 : 0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        child: Container(
          alignment: Alignment.center,
          color: Colors.black.withOpacity(0.92),
          child: Stack(
            children: [
              // Link list
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _MenuLink(
                      title: 'Home',
                      onTap: onClose,
                    ),
                  ],
                ),
              ),
              // Close button
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                right: 8,
                child: IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close, color: Colors.white, size: 36),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuLink extends StatelessWidget {
  const _MenuLink({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14.0),
      child: GestureDetector(
        onTap: onTap,
        child: Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
