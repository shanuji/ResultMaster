import 'package:flutter/material.dart';

class WavyHeader extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;

  const WavyHeader({
    super.key,
    required this.title,
    this.actions,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return ClipPath(
      clipper: WavyClipper(),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.only(
          top: top,
          left: 20,
          right: 20,
          bottom: 34,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xff1BC6B4),
              Color(0xff129E95),
              Color(0xff0A8078),
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: 72,
            child: Row(
              children: [
                if (leading != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: leading!,
                  ),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .2,
                    ),
                  ),
                ),
                if (actions != null) ...actions!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class WavyClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    path.lineTo(0, size.height - 48);

    path.quadraticBezierTo(
      size.width * .18,
      size.height + 8,
      size.width * .42,
      size.height - 22,
    );

    path.quadraticBezierTo(
      size.width * .72,
      size.height - 56,
      size.width,
      size.height - 28,
    );

    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
