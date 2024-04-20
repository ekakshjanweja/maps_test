import 'package:flutter/material.dart';

class CustomInput extends StatelessWidget {
  final Transform icon;
  const CustomInput({
    required this.icon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final currentWidth = MediaQuery.of(context).size.width;
    final currentHeight = MediaQuery.of(context).size.height;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        icon,
        SizedBox(width: currentWidth * 0.02),
        Container(
          width: currentWidth * 0.8,
          height: currentHeight * 0.06,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.blue.shade800,
            ),
          ),
        )
      ],
    );
  }
}
