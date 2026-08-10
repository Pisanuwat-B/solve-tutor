import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solve_tutor/auth.dart';
import 'package:solve_tutor/authentication/service/auth_provider.dart';
import 'package:solve_tutor/constants/theme.dart';
import 'package:solve_tutor/widgets/sizer.dart';

import '../../feature/calendar/constants/custom_styles.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool isLoading = false;

  AuthProvider? authProvider;
  @override
  Widget build(BuildContext context) {
    authProvider = Provider.of<AuthProvider>(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
      ),
      body: isLoading
          ? Center(
              child: Container(
                height: Sizer(context).h / 20,
                width: Sizer(context).h / 20,
                child: const CircularProgressIndicator(),
              ),
            )
          : SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 60,
                      ),
                      Text('สร้างบัญชี', style: CustomStyles.bold22Black363636),
                      SizedBox(height: 24.00),
                      Image.asset(
                        'assets/images/register_image.png',
                        width: 165,
                        height: 165,
                      ),
                      SizedBox(height: 60),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Container(
                          width: Sizer(context).w,
                          alignment: Alignment.center,
                          child: field("Name", Icons.account_box, _name),
                        ),
                      ),
                      Container(
                        width: Sizer(context).w,
                        alignment: Alignment.center,
                        child: field("email", Icons.account_box, _email),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Container(
                          width: Sizer(context).w,
                          alignment: Alignment.center,
                          child: field("password", Icons.lock, _password),
                        ),
                      ),
                      SizedBox(
                        height: Sizer(context).h / 20,
                      ),
                      customButton(),
                      SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Text(
                            "Login",
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget customButton() {
    return GestureDetector(
      onTap: () {
        if (_name.text.isNotEmpty &&
            _email.text.isNotEmpty &&
            _password.text.isNotEmpty) {
          setState(() {
            isLoading = true;
          });

          authProvider!
              .createAccount(_name.text, _email.text, _password.text)
              .then(
            (user) {
              if (user != null) {
                setState(() {
                  isLoading = false;
                });
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => Authenticate()));
                print("Account Created Sucessfull");
              } else {
                print("Login Failed");
                setState(() {
                  isLoading = false;
                });
              }
            },
          );
        } else {
          print("Please enter Fields");
        }
      },
      child: Container(
          height: 45,
          width: 95,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: primaryColor,
          ),
          alignment: Alignment.center,
          child: Text(
            "สร้างบัญชี",
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          )),
    );
  }

  Widget field(String hintText, IconData icon, TextEditingController cont) {
    return Container(
      height: Sizer(context).h / 14,
      width: Sizer(context).w / 1.1,
      child: TextField(
        controller: cont,
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
