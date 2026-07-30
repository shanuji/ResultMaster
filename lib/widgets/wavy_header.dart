import 'package:flutter/material.dart';

class WavyHeader extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  
  const WavyHeader({super.key, required this.title, this.actions, this.leading});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: WavyClipper(),
      child: Container(
        color: Theme.of(context).colorScheme.primary,
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top, bottom: 25),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: leading,
          title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
          actions: actions,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
      ),
    );
  }
}

class WavyClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 25);
    
    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2.25, size.height - 20);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy, firstEndPoint.dx, firstEndPoint.dy);

    var secondControlPoint = Offset(size.width - (size.width / 3.25), size.height - 45);
    var secondEndPoint = Offset(size.width, size.height - 30);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy, secondEndPoint.dx, secondEndPoint.dy);

    path.lineTo(size.width, size.height - 30);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
