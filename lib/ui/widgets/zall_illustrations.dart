import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/zall_theme.dart';

/// 3D Blue Folder Illustration with mini social cards (YouTube, TikTok, Instagram)
class HeroFolderIllustration extends StatelessWidget {
  final double size;

  const HeroFolderIllustration({super.key, this.size = 140});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Background Sparkles & Glow Dots
          Positioned(
            top: 10,
            left: 12,
            child: _sparkle(8, ZallTheme.highlightBlue),
          ),
          Positioned(
            top: 25,
            right: 15,
            child: _sparkle(12, ZallTheme.primaryBlue),
          ),
          Positioned(
            bottom: 20,
            left: 8,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: ZallTheme.primaryBlue,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 45,
            right: 10,
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: ZallTheme.highlightBlue.withOpacity(0.8),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Main Folder Group
          Transform.rotate(
            angle: 0.08,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Back Folder Tab
                Container(
                  width: size * 0.78,
                  height: size * 0.65,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                ),

                // White Paper Inserts
                Positioned(
                  top: 8,
                  left: 10,
                  child: Transform.rotate(
                    angle: -0.04,
                    child: Container(
                      width: size * 0.64,
                      height: size * 0.52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDBEAFE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),

                // Mini Brand Cards Peeking Out
                // 1. YouTube Red Card
                Positioned(
                  top: -18,
                  left: 10,
                  child: Transform.rotate(
                    angle: -0.22,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF2A2A), Color(0xFFCC0000)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFCA5A5), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.play_arrow, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ),

                // 2. TikTok Dark Card
                Positioned(
                  top: -26,
                  left: 48,
                  child: Transform.rotate(
                    angle: 0.12,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF18181B),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF3F3F46), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.music_note, color: Color(0xFF25F4EE), size: 18),
                      ),
                    ),
                  ),
                ),

                // 3. Instagram Gradient Card
                Positioned(
                  top: -14,
                  right: 8,
                  child: Transform.rotate(
                    angle: 0.24,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFDBA74),
                            Color(0xFFF43F5E),
                            Color(0xFFD946EF),
                            Color(0xFF6366F1),
                          ],
                          begin: Alignment.bottomLeft,
                          end: Alignment.topRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFF9A8D4), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.camera_alt_outlined, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ),

                // Front Folder Pocket
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: size * 0.44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF60A5FA), Color(0xFF3B82F6), Color(0xFF2563EB)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                      border: Border.all(color: const Color(0xFF93C5FD), width: 1),
                    ),
                    child: Center(
                      child: Container(
                        width: 32,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF).withOpacity(0.95),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sparkle(double size, Color color) {
    return Icon(Icons.star, size: size, color: color);
  }
}

/// 3D Blue Inbox Tray Illustration with Paper Plane for Empty States
class EmptyInboxIllustration extends StatelessWidget {
  final double size;

  const EmptyInboxIllustration({super.key, this.size = 130});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Background Sparkles & Dots
          Positioned(
            top: 15,
            left: 20,
            child: Icon(Icons.star, size: 12, color: ZallTheme.highlightBlue),
          ),
          Positioned(
            top: 40,
            right: 15,
            child: Icon(Icons.star, size: 10, color: ZallTheme.highlightBlue),
          ),
          Positioned(
            bottom: 30,
            left: 10,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: ZallTheme.primaryBlue,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 25,
            right: 35,
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: const Color(0xFF38BDF8).withOpacity(0.85),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Flying Paper Plane
          Positioned(
            top: 10,
            right: size * 0.35,
            child: Transform.rotate(
              angle: -0.2,
              child: Container(
                padding: const EdgeInsets.all(4),
                child: const Icon(
                  Icons.send_rounded,
                  color: Color(0xFFDBEAFE),
                  size: 26,
                ),
              ),
            ),
          ),

          // 3D Inbox Box / Tray
          Positioned(
            bottom: 12,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Inbox Back & Interior
                Container(
                  width: size * 0.72,
                  height: size * 0.52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1D4ED8), Color(0xFF1E3A8A)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF93C5FD), width: 1.5),
                  ),
                ),

                // Inbox Front Flap with Arrow Down
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: size * 0.38,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF60A5FA), Color(0xFF2563EB)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.arrow_downward_rounded, color: Colors.white, size: 20),
                          SizedBox(height: 2),
                          ContainerTraySlot(),
                        ],
                      ),
                    ),
                  ),
                ),

                // Mini Image Tile on Bottom Right
                Positioned(
                  bottom: -6,
                  right: -12,
                  child: Transform.rotate(
                    angle: 0.16,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF93C5FD),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFDBEAFE), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.image, color: Color(0xFF1D4ED8), size: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ContainerTraySlot extends StatelessWidget {
  const ContainerTraySlot({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 3,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
