import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_tokens.dart';

class CinematicSplashPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0 (corresponds to 0.0s - 3.2s)
  final bool isDark;

  CinematicSplashPainter({
    required this.progress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // -------------------------------------------------------------------------
    // ACT 1: Phone & Order Card Ripple (0.0 - 0.25 on progress timeline)
    // -------------------------------------------------------------------------
    if (progress <= 0.32) {
      final act1Progress = (progress / 0.25).clamp(0.0, 1.0);
      _drawAct1Phone(canvas, size, act1Progress);
    }

    // -------------------------------------------------------------------------
    // ACT 2: Flying Glass Chip to Colony Shop (0.22 - 0.53 on progress timeline)
    // -------------------------------------------------------------------------
    if (progress >= 0.22 && progress <= 0.58) {
      final act2Progress = ((progress - 0.22) / 0.31).clamp(0.0, 1.0);
      _drawAct2Shop(canvas, size, act2Progress);
    }

    // -------------------------------------------------------------------------
    // ACT 3: Scooter Road & Home Doorstep Bounce (0.50 - 0.84 on progress timeline)
    // -------------------------------------------------------------------------
    if (progress >= 0.50 && progress <= 0.88) {
      final act3Progress = ((progress - 0.50) / 0.34).clamp(0.0, 1.0);
      _drawAct3Delivery(canvas, size, act3Progress);
    }

    // -------------------------------------------------------------------------
    // ACT 4: Shimmer Sweep & Final Logo Reveal (0.80 - 1.0 on progress timeline)
    // -------------------------------------------------------------------------
    if (progress >= 0.80) {
      final act4Progress = ((progress - 0.80) / 0.20).clamp(0.0, 1.0);
      _drawAct4LogoReveal(canvas, size, act4Progress);
    }
  }

  // --- ACT 1 DRAWING: 3D-Tilted Phone Mockup ---
  void _drawAct1Phone(Canvas canvas, Size size, double t) {
    final cx = size.width / 2;
    final cy = size.height / 2 - 20;

    final phoneWidth = 140.0;
    final phoneHeight = 260.0;

    final opacity = (t * 2.0).clamp(0.0, 1.0);
    final riseY = (1.0 - Curves.easeOutCubic.transform(t)) * 60;

    final phoneRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy + riseY), width: phoneWidth, height: phoneHeight),
      const Radius.circular(24),
    );

    // Glass phone body
    final phonePaint = Paint()
      ..color = (isDark ? const Color(0x33FFFFFF) : const Color(0x99FFFFFF)).withOpacity(opacity * 0.4)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(phoneRect, phonePaint);

    final borderPaint = Paint()
      ..color = (isDark ? AppTokens.glassBorderDark : AppTokens.glassBorderLight).withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(phoneRect, borderPaint);

    // Order Card inside phone
    final cardRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy + riseY - 20), width: phoneWidth - 28, height: 90),
      const Radius.circular(14),
    );
    final cardPaint = Paint()
      ..color = (isDark ? AppTokens.primaryDark : AppTokens.primaryLight).withOpacity(opacity * 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(cardRect, cardPaint);

    // Place Order Button inside phone with tap ripple
    final btnRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy + riseY + 60), width: phoneWidth - 36, height: 32),
      const Radius.circular(10),
    );
    final btnPaint = Paint()
      ..color = (isDark ? AppTokens.primaryDark : AppTokens.primaryLight).withOpacity(opacity * 0.9)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(btnRect, btnPaint);

    // Thumb-tap ripple
    if (t > 0.6) {
      final rippleT = ((t - 0.6) / 0.4).clamp(0.0, 1.0);
      final rippleRadius = 10.0 + rippleT * 26.0;
      final ripplePaint = Paint()
        ..color = (isDark ? AppTokens.accentDark : AppTokens.accentLight).withOpacity((1.0 - rippleT) * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(Offset(cx, cy + riseY + 60), rippleRadius, ripplePaint);
    }
  }

  // --- ACT 2 DRAWING: Flying Chip to Colony Shop ---
  void _drawAct2Shop(Canvas canvas, Size size, double t) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Curved Bezier Flight path from phone to shop
    final p0 = Offset(cx - 60, cy + 20);
    final p1 = Offset(cx, cy - 100);
    final p2 = Offset(cx + 70, cy - 20);

    // Cubic Bezier interpolation
    final u = 1 - t;
    final chipX = u * u * p0.dx + 2 * u * t * p1.dx + t * t * p2.dx;
    final chipY = u * u * p0.dy + 2 * u * t * p1.dy + t * t * p2.dy;

    // Glowing Trail
    final trailPaint = Paint()
      ..color = (isDark ? AppTokens.primaryDark : AppTokens.primaryLight).withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final trailPath = Path()..moveTo(p0.dx, p0.dy);
    trailPath.quadraticBezierTo(p1.dx, p1.dy, chipX, chipY);
    canvas.drawPath(trailPath, trailPaint);

    // Flying Glowing Chip
    final chipPaint = Paint()
      ..color = isDark ? AppTokens.primaryDark : AppTokens.primaryLight
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(chipX, chipY), width: 24, height: 16), const Radius.circular(5)),
      chipPaint,
    );

    // Stylized Colony Shop (Awning, Shutter lifting, Bag packing)
    final shopX = cx + 70;
    final shopY = cy - 10;

    // Shop Awning
    final awningPath = Path()
      ..moveTo(shopX - 40, shopY - 30)
      ..lineTo(shopX + 40, shopY - 30)
      ..lineTo(shopX + 34, shopY - 14)
      ..lineTo(shopX - 34, shopY - 14)
      ..close();

    final awningPaint = Paint()
      ..color = isDark ? AppTokens.accentDark : AppTokens.accentLight
      ..style = PaintingStyle.fill;
    canvas.drawPath(awningPath, awningPaint);

    // Shop Storefront Box
    final shopRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(shopX, shopY + 10), width: 68, height: 48),
      const Radius.circular(6),
    );
    final shopPaint = Paint()
      ..color = (isDark ? const Color(0x33FFFFFF) : const Color(0x66FFFFFF))
      ..style = PaintingStyle.fill;
    canvas.drawRRect(shopRect, shopPaint);

    // Grocery Bag Packing Icon / Indicator
    if (t > 0.6) {
      final bagT = ((t - 0.6) / 0.4).clamp(0.0, 1.0);
      final bagPaint = Paint()
        ..color = (isDark ? AppTokens.primaryDark : AppTokens.primaryLight).withOpacity(bagT)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(shopX, shopY + 12), width: 18, height: 22), const Radius.circular(4)),
        bagPaint,
      );
    }
  }

  // --- ACT 3 DRAWING: Delivery Scooter, Parallax Road & Doorstep Bounce ---
  void _drawAct3Delivery(Canvas canvas, Size size, double t) {
    final w = size.width;
    final cy = size.height / 2 + 20;

    // 3 Parallax Background Layers
    final pLayer1 = (t * 80) % w;
    final pLayer2 = (t * 140) % w;

    final sceneryPaint = Paint()
      ..color = (isDark ? const Color(0x1FFFFFFF) : const Color(0x1F0F172A))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset((w - pLayer1).abs(), cy + 10), 10, sceneryPaint);
    canvas.drawCircle(Offset((w - pLayer2).abs(), cy + 18), 6, sceneryPaint);

    final roadPaint = Paint()
      ..color = (isDark ? const Color(0x29FFFFFF) : const Color(0x330F172A))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Road Line
    canvas.drawLine(Offset(20, cy + 30), Offset(w - 20, cy + 30), roadPaint);

    // Scooter Movement across road
    final scooterX = 30 + Curves.easeInOutCubic.transform(t) * (w - 140);
    final scooterY = cy + 18;

    // Draw Minimal Vector Scooter
    final scooterPaint = Paint()
      ..color = isDark ? AppTokens.primaryDark : AppTokens.primaryLight
      ..style = PaintingStyle.fill;

    // Scooter Wheels
    canvas.drawCircle(Offset(scooterX, scooterY + 8), 6, scooterPaint);
    canvas.drawCircle(Offset(scooterX + 26, scooterY + 8), 6, scooterPaint);

    // Scooter Body & Delivery Box
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(scooterX + 13, scooterY), width: 28, height: 10), const Radius.circular(3)),
      scooterPaint,
    );
    // Green delivery crate
    final boxPaint = Paint()
      ..color = isDark ? AppTokens.accentDark : AppTokens.accentLight
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(scooterX + 6, scooterY - 8), width: 14, height: 12), const Radius.circular(2)),
      boxPaint,
    );

    // Customer Home on Right Side
    final homeX = w - 70;
    final homeY = cy - 10;

    // House outline
    final housePath = Path()
      ..moveTo(homeX - 25, homeY + 30)
      ..lineTo(homeX - 25, homeY)
      ..lineTo(homeX, homeY - 20)
      ..lineTo(homeX + 25, homeY)
      ..lineTo(homeX + 25, homeY + 30)
      ..close();

    final housePaint = Paint()
      ..color = (isDark ? const Color(0x33FFFFFF) : const Color(0x66FFFFFF))
      ..style = PaintingStyle.fill;
    canvas.drawPath(housePath, housePaint);

    // Glowing Amber Door
    final doorPaint = Paint()
      ..color = (isDark ? AppTokens.accentDark : AppTokens.accentLight).withOpacity(t > 0.7 ? 0.9 : 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(homeX - 8, homeY + 6, 16, 24), const Radius.circular(3)),
      doorPaint,
    );

    // Squash-and-stretch package bounce on doorstep at end of Act 3
    if (t > 0.8) {
      final bounceT = ((t - 0.8) / 0.2).clamp(0.0, 1.0);
      final bounceY = math.sin(bounceT * math.pi) * 14;
      final squashX = 12.0 + (1.0 - math.sin(bounceT * math.pi)) * 3;
      final squashY = 12.0 - (1.0 - math.sin(bounceT * math.pi)) * 2;

      final packagePaint = Paint()
        ..color = isDark ? AppTokens.primaryDark : AppTokens.primaryLight
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(homeX - 16, cy + 22 - bounceY), width: squashX, height: squashY),
          const Radius.circular(3),
        ),
        packagePaint,
      );
    }
  }

  // --- ACT 4 DRAWING: Logo Reveal & Shimmer Sweep ---
  void _drawAct4LogoReveal(Canvas canvas, Size size, double t) {
    final cx = size.width / 2;
    final cy = size.height / 2 - 30;

    final logoScale = 0.8 + 0.2 * Curves.easeOutBack.transform(t);
    final logoOpacity = t.clamp(0.0, 1.0);

    // Glow Aura behind logo
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          (isDark ? AppTokens.primaryDark : AppTokens.primaryLight).withOpacity(0.35 * logoOpacity),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: 80 * logoScale));

    canvas.drawCircle(Offset(cx, cy), 90 * logoScale, glowPaint);

    // Shimmer Sweep Line
    final shimmerX = (cx - 120) + t * 240;
    final shimmerPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          Colors.white.withOpacity(0.6 * logoOpacity),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(shimmerX - 30, cy - 60, 60, 120));

    canvas.drawRect(Rect.fromLTWH(shimmerX - 30, cy - 60, 60, 120), shimmerPaint);
  }

  @override
  bool shouldRepaint(covariant CinematicSplashPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isDark != isDark;
  }
}
