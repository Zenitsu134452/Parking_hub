import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_service.dart';
import '../provider/user_provider.dart';
import 'mail_verification.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();
  final formKey = GlobalKey<FormState>();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Form(
            key:  formKey,
            child: Column(children: [
              SizedBox(
                width: MediaQuery.of(context).size.width * .9,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        "Login",
                        style:
                        TextStyle(fontSize: 40, fontWeight: FontWeight.w700),
                      ),
                    ),
                    Center(child: Text("Get started with your account")),
                    SizedBox(
                      height: 10,
                    ),
                    SizedBox(
                        width: MediaQuery.of(context).size.width * .9,
                        child: TextFormField(
                          validator: (value) =>
                          value!.isEmpty ? "Email cannot be empty." : null,
                          controller: _emailController,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            label: Text("Email"),
                          ),
                        )),
                  ],
                ),
              ),
              SizedBox(
                height: 10,
              ),
              SizedBox(
                  width: MediaQuery.of(context).size.width * .9,
                  child: TextFormField(
                    validator: (value) => value!.length < 8
                        ? "Password should have atleast 8 characters."
                        : null,
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      label: Text("Password"),
                    ),
                  )),
              SizedBox(
                height: 10,
              ),
              Row(  mainAxisAlignment: MainAxisAlignment.end,children: [
                TextButton(onPressed: (){
                  showDialog(context: context, builder:  (builder) {
                    return AlertDialog(
                        title:  Text("Forget Password"),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Enter you email"),
                            SizedBox(height: 10,),
                            TextFormField (controller:  _emailController, decoration: InputDecoration(label: Text("Email"), border: OutlineInputBorder()),),
                          ],
                        ),
                        actions: [
                          TextButton(onPressed: (){
                            Navigator.pop(context);}, child: Text("Cancel")),
                          TextButton(onPressed: ()async{
                            if(_emailController.text.isEmpty){
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Email cannot be empty")));
                              return;
                            }
                            await AuthService().resetPassword(_emailController.text).then( (value) {
                              if(value=="Mail Sent"){
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Password reset link sent to your email")));
                                Navigator.pop(context);
                              }
                              else{
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value,style: TextStyle( color:  Colors.white),), backgroundColor: Colors.red.shade400,));
                              }
                            });
                          }, child: Text("Submit")),
                        ]

                    );
                  });
                }, child: Text("Forget Password")),
              ],),
              SizedBox(
                height: 10,
              ),
              SizedBox(
                height: 60,
                width: MediaQuery.of(context).size.width * .9,
                child: ElevatedButton(
                  onPressed: () async {
                    String loginResult = await _authService.loginWithEmail(
                      _emailController.text,
                      _passwordController.text,
                    );
                    if (loginResult == "Verification Required") {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MailVerification(),
                        ),
                      );
                    } else if (loginResult == "Login Successful") {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Login Successful")),
                      );
                      Navigator.restorablePushNamedAndRemoveUntil(
                          context, "/home", (route) => false);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(loginResult)),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    "Login",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              SizedBox(
                height: 10,
              ),
              SizedBox(height: 40,
                child: ElevatedButton(
                  onPressed: () async {
                    UserCredential? userCredential = await _authService.loginWithGoogle(
                          (String userId) {
                        Provider.of<UserProvider>(context, listen: false).loadUserData(userId);
                      },
                    );
                    if (userCredential != null) {
                      // Successful login
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Google Login Successful")),
                      );
                      Navigator.restorablePushNamedAndRemoveUntil(context, "/home", (route) => false);
                    } else {
                      // Login cancelled or failed
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Google Login Cancelled or Failed")),
                      );
                    }
                  },child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image(
                      image: AssetImage("assets/images/Google.jpg"),
                      height: 20,
                      width: 20,
                    ),
                    SizedBox(width: 10),
                    Text("Sign In with Google"),
                  ],
                ),
                ),

              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have and account?"),
                  TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, "/signup");
                      },
                      child: Text("Sign Up"))
                ],
              )

            ],),
          ),
        ),
      ),
    );
  }
}