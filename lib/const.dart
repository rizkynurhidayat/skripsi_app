import 'package:flutter/material.dart';

const Color yellow = Color.fromRGBO(255, 235, 0, 1);
const Color darkblue = Color.fromRGBO(0, 9, 87, 1);
const Color blueAccent = Color.fromRGBO(52, 76, 183, 1);

class CommonButton extends StatelessWidget {
  const CommonButton(
      {required this.onTap,
      required this.text,
      required this.isLoginButton,
      super.key});
  final VoidCallback onTap;
  final String text;
  final bool isLoginButton;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
          style: ButtonStyle(
              backgroundColor:
                  WidgetStatePropertyAll(isLoginButton ? yellow : darkblue),
              foregroundColor: WidgetStatePropertyAll(
                  isLoginButton ? darkblue : Colors.white)),
          onPressed: onTap,
          child: Text(
            text,
            style: TextStyle(color: isLoginButton ? darkblue : Colors.white),
          )),
    );
  }
}

