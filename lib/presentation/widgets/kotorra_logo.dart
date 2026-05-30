import 'package:flutter/material.dart';

class KotorraLogo extends StatelessWidget {
  final double size;
  const KotorraLogo({super.key, this.size = 100});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF7CB342), // Primary Green
        border: Border.all(color: const Color(0xFF558B2F), width: size * 0.05),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // White face circles (background of eyes)
          Positioned(
            left: size * 0.15,
            top: size * 0.22,
            child: _buildFacePart(size * 0.38, Colors.white),
          ),
          Positioned(
            right: size * 0.15,
            top: size * 0.22,
            child: _buildFacePart(size * 0.38, Colors.white),
          ),

          // Pink Cheeks
          Positioned(
            left: size * 0.12,
            top: size * 0.45,
            child: _buildFacePart(size * 0.14, const Color(0xFFFF8A80)),
          ),
          Positioned(
            right: size * 0.12,
            top: size * 0.45,
            child: _buildFacePart(size * 0.14, const Color(0xFFFF8A80)),
          ),

          // Black Pupils
          Positioned(
            left: size * 0.28,
            top: size * 0.32,
            child: _buildPupil(size * 0.16),
          ),
          Positioned(
            right: size * 0.28,
            top: size * 0.32,
            child: _buildPupil(size * 0.16),
          ),

          // Cute Yellow/Orange Beak
          Positioned(
            top: size * 0.40,
            child: Container(
              width: size * 0.26,
              height: size * 0.38,
              decoration: BoxDecoration(
                color: const Color(0xFFFFB300), // Beak yellow
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(size * 0.12),
                  topRight: Radius.circular(size * 0.12),
                  bottomLeft: Radius.circular(size * 0.16),
                  bottomRight: Radius.circular(size * 0.16),
                ),
                border: Border.all(color: const Color(0xFFE65100), width: size * 0.02),
              ),
            ),
          ),
          
          // Inner Beak Detail (soft highlight)
          Positioned(
            top: size * 0.42,
            child: Container(
              width: size * 0.18,
              height: size * 0.12,
              decoration: BoxDecoration(
                color: const Color(0xFFFFCC80),
                borderRadius: BorderRadius.circular(size * 0.06),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFacePart(double partSize, Color color) {
    return Container(
      width: partSize,
      height: partSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }

  Widget _buildPupil(double pupilSize) {
    return Container(
      width: pupilSize,
      height: pupilSize,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF263238), // Dark color
      ),
      child: Stack(
        children: [
          // White eye highlight
          Positioned(
            left: pupilSize * 0.2,
            top: pupilSize * 0.2,
            child: Container(
              width: pupilSize * 0.35,
              height: pupilSize * 0.35,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            ),
          )
        ],
      ),
    );
  }
}
