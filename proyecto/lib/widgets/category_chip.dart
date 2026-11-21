import 'package:flutter/material.dart';

class CategoryChip extends StatelessWidget {

  final String text;
  final bool selected;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {

    return GestureDetector(

      onTap: onTap,

      child: AnimatedContainer(

        duration: const Duration(milliseconds: 200),

        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 9,
        ),

        decoration: BoxDecoration(

          color: selected
              ? const Color(0xFFE0568A)
              : Colors.white,

          borderRadius: BorderRadius.circular(12),

          border: Border.all(
            color: selected
                ? const Color(0xFFE0568A)
                : const Color(0xFFF0CFCC),
          ),
        ),

        child: Text(

          text,

          style: TextStyle(

            color: selected
                ? Colors.white
                : const Color(0xFF2B1111),

            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}