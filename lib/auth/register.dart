import 'package:flutter/material.dart';

import '../custom_checkbox.dart';
import '../primary_button.dart';
import '../theme.dart';

class Register extends StatefulWidget {
  const Register({super.key});
  @override
  RegisterState createState() => RegisterState();
}

class RegisterState extends State<Register> {
  bool passwordVisible = false;
  bool passwordConfirmVisible = false;
  void togglePassword() {
    setState(() {
      passwordVisible = !passwordVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
          child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mobile Absensi\nRegister',
                  style: heading2.copyWith(color: textBlack),
                ),
                const SizedBox(
                  height: 20,
                ),
                Image.asset(
                  'assets/images/accent.png',
                  width: 99,
                  height: 4,
                )
              ],
            ),
            const SizedBox(
              height: 80,
            ),
            Form(
                child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                      color: textWhiteGrey,
                      borderRadius: BorderRadius.circular(14)),
                  child: TextFormField(
                    decoration: InputDecoration(
                        hintText: 'Username',
                        hintStyle: heading6.copyWith(color: textGrey),
                        border: const OutlineInputBorder(
                            borderSide: BorderSide.none)),
                  ),
                ),
                const SizedBox(
                  height: 32,
                ),
                Container(
                  decoration: BoxDecoration(
                      color: textWhiteGrey,
                      borderRadius: BorderRadius.circular(14)),
                  child: TextFormField(
                    obscureText: !passwordVisible,
                    decoration: InputDecoration(
                        hintText: 'Password',
                        hintStyle: heading6.copyWith(color: textGrey),
                        suffixIcon: IconButton(
                          color: textGrey,
                          splashRadius: 1,
                          icon: Icon(passwordVisible
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: togglePassword,
                        ),
                        border: const OutlineInputBorder(
                            borderSide: BorderSide.none)),
                  ),
                ),
                const SizedBox(
                  height: 32,
                ),
                Container(
                  decoration: BoxDecoration(
                      color: textWhiteGrey,
                      borderRadius: BorderRadius.circular(14)),
                  child: TextFormField(
                    obscureText: !passwordConfirmVisible,
                    decoration: InputDecoration(
                        hintText: 'Password Confirmation',
                        hintStyle: heading6.copyWith(color: textGrey),
                        suffixIcon: IconButton(
                          color: textGrey,
                          splashRadius: 1,
                          icon: Icon(passwordConfirmVisible
                              ? Icons.visibility_outlined
                              : Icons.voice_over_off_outlined),
                          onPressed: () {
                            setState(() {
                              passwordConfirmVisible = !passwordConfirmVisible;
                            });
                          },
                        ),
                        border: const OutlineInputBorder(
                            borderSide: BorderSide.none)),
                  ),
                )
              ],
            )),
            const SizedBox(
              height: 32,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const CustomCheckbox(),
                const SizedBox(
                  width: 5,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'By creating an account, you agree to our',
                      style: regular16pt.copyWith(color: textGrey),
                    ),
                    Text(
                      'Term & Condition',
                      style: regular16pt.copyWith(color: primaryBlue),
                    )
                  ],
                )
              ],
            ),
            const SizedBox(
              height: 32,
            ),
            CustomPrimaryButton(
              buttonColor: primaryBlue,
              textValue: 'Register',
              textColor: Colors.white,
            ),
            const SizedBox(
              height: 5,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Already have an account? ',
                  style: regular16pt.copyWith(color: textGrey),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Login',
                    style: regular16pt.copyWith(color: primaryBlue),
                  ),
                )
              ],
            )
          ],
        ),
      )),
    );
  }
}
