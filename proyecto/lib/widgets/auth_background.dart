import 'package:flutter/material.dart';

class AuthBackground extends StatelessWidget {

  final Widget child;

  const AuthBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {

    return Container(

      decoration: const BoxDecoration(

        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,

          colors: [
            Color(0xFFFFF1F5),
            Color(0xFFFFD9E6),
            Color(0xFFFFE8D6),
            Color(0xFFFFF4E8),
          ],
        ),
      ),

      child: child,
    );
  }
}