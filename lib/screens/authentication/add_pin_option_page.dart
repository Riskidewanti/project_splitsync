import 'package:flutter/material.dart';

import '../../widgets/responsive.dart';
import 'create_pin_page.dart';
import '../home/home_page.dart';

class AddPinOptionPage extends StatelessWidget {
  const AddPinOptionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFFFFCF7),
      body: SafeArea(
        child: ResponsivePage(
          maxWidth: 430,
          scrollable: true,
          padding: responsive
              .horizontal(18)
              .copyWith(
                top: responsive.space(28),
                bottom: responsive.space(14),
              ),
          child: Column(
            children: [
              _SecurityIllustration(responsive: responsive),
              SizedBox(height: responsive.space(34)),
              Text(
                'Amankan Transaksi\nAnda',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF8C000E),
                  fontSize: responsive.font(36),
                  fontWeight: FontWeight.w900,
                  height: 1.18,
                ),
              ),
              SizedBox(height: responsive.space(22)),
              Text(
                'Buat PIN 6-digit untuk memberikan lapisan\nkeamanan ekstra pada setiap pengiriman\nuang dan penagihan.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF5E5656),
                  fontSize: responsive.font(18),
                  height: 1.45,
                ),
              ),
              SizedBox(height: responsive.space(36)),
              const _FeatureTile(
                icon: Icons.verified_user_outlined,
                title: 'Proteksi Akun',
                subtitle: 'Hanya Anda yang bisa akses saldo.',
              ),
              SizedBox(height: responsive.space(14)),
              const _FeatureTile(
                icon: Icons.payments_outlined,
                title: 'Konfirmasi Kirim',
                subtitle: 'Transaksi aman dari kesalahan klik.',
              ),
              SizedBox(height: responsive.space(40)),
              _ActionButton(
                label: 'BUAT PIN SEKARANG',
                filled: true,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CreatePinPage()),
                  );
                },
              ),
              SizedBox(height: responsive.space(16)),
              _ActionButton(
                label: 'Nanti Saja',
                onTap: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const HomePage()),
                  );
                },
              ),
              SizedBox(height: responsive.space(22)),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: responsive.space(8),
                children: [
                  Icon(
                    Icons.lock_outline,
                    color: const Color(0xFF9B9B9B),
                    size: responsive.clamp(18, 16, 20),
                  ),
                  Text(
                    'Enkripsi 256-bit standar industri',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF9B9B9B),
                      fontSize: responsive.font(14),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecurityIllustration extends StatelessWidget {
  const _SecurityIllustration({required this.responsive});

  final Responsive responsive;

  @override
  Widget build(BuildContext context) {
    final width = responsive.clamp(282, 230, 310);
    final height = responsive.clamp(142, 116, 154);
    final floating = responsive.clamp(78, 58, 82);
    return SizedBox(
      height: responsive.clamp(236, 178, 246),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(responsive.clamp(34, 26, 36)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x17000000),
                  blurRadius: 24,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: responsive.clamp(94, 74, 98),
                  height: responsive.clamp(94, 74, 98),
                  decoration: const BoxDecoration(
                    color: Color(0xFFA4161D),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.security_rounded,
                    color: Colors.white,
                    size: responsive.clamp(42, 34, 44),
                  ),
                ),
                SizedBox(height: responsive.space(16)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    6,
                    (index) => Container(
                      width: responsive.clamp(16, 12, 17),
                      height: responsive.clamp(16, 12, 17),
                      margin: EdgeInsets.symmetric(
                        horizontal: responsive.space(6),
                      ),
                      decoration: BoxDecoration(
                        color: index < 3
                            ? const Color(0xFF98000E)
                            : const Color(0xFFE9E6E0),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: responsive.space(48),
            bottom: responsive.space(28),
            child: _FloatingIcon(
              size: floating,
              color: const Color(0xFFD7E1FF),
              icon: Icons.fingerprint_rounded,
              iconColor: const Color(0xFF3F4657),
            ),
          ),
          Positioned(
            right: responsive.space(54),
            top: responsive.space(10),
            child: Transform.rotate(
              angle: 0.18,
              child: _FloatingIcon(
                size: floating,
                color: const Color(0xFFFFD6D8),
                icon: Icons.vpn_key_rounded,
                iconColor: const Color(0xFF8C000E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingIcon extends StatelessWidget {
  const _FloatingIcon({
    required this.size,
    required this.color,
    required this.icon,
    required this.iconColor,
  });

  final double size;
  final Color color;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(icon, color: iconColor, size: size * 0.42),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.clamp(28, 18, 28),
        vertical: responsive.clamp(20, 16, 22),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF2F0EC)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: responsive.clamp(30, 24, 32),
            backgroundColor: const Color(0xFFF7E9E9),
            child: Icon(
              icon,
              color: const Color(0xFF8C000E),
              size: responsive.clamp(27, 22, 29),
            ),
          ),
          SizedBox(width: responsive.space(18)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF111B2C),
                    fontSize: responsive.font(18),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: const Color(0xFF5E5656),
                    fontSize: responsive.font(16),
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

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    return SizedBox(
      width: double.infinity,
      height: responsive.clamp(58, 52, 60),
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: filled ? const Color(0xFF8C000E) : Colors.white,
          foregroundColor: filled ? Colors.white : const Color(0xFF4B4242),
          side: BorderSide(
            color: filled ? const Color(0xFF8C000E) : const Color(0xFFE0E0E0),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: FittedBox(
          child: Text(
            label,
            style: TextStyle(
              fontSize: responsive.font(17),
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
