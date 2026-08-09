import 'package:flutter/material.dart';
import 'package:mobile/services/auth_api.dart';

class LoginView extends StatefulWidget{

  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {

  bool _isLoading = false; 
  final _formKey = GlobalKey<FormState>();

  final _authApi = AuthApi();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void handleLogin(){
    if (_formKey.currentState!.validate()){
      setState(() => _isLoading = true);
      final email = _emailController.text;
      final password = _passwordController.text;

      debugPrint("Email: $email\nPassword: $password");

      try{
        _authApi.login(email, password);
      }
      catch(e){
        debugPrint("Message $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login unsuccesfull!')));
      }
      finally{
        _isLoading = false;
      }

    } else {
      debugPrint("Error!");
    }
  }

  @override 
  void dispose(){
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:AppBar(
        title: Text('Login to CryptoMarket App:')
      ),
      body: Padding(padding: EdgeInsetsGeometry.all(16),
      child: Form( 
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              keyboardType: TextInputType.emailAddress,
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: "E-mail:",
                border: OutlineInputBorder(),
              ),
              validator: (value){
                if(value == null || value.isEmpty){
                  debugPrint("Email error.");
                  return "Email can not be empty!";
                }
        
                if(!value.contains('@')){
                  debugPrint("Email error.");
                  return "Email must contain @";
                }
        
                return null;
              }
            ),
            const SizedBox(height: 16),
            TextFormField(
              keyboardType: TextInputType.visiblePassword,
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: "Password:",
                border: OutlineInputBorder()
              ),
              validator:(value) {
                if(value == null || value.isEmpty){
                  debugPrint("Password error.");
                  return "Password cannot be empty!";
                }
        
                if(value.length < 6) {
                  debugPrint("Password length error.");
                  return "Password length must be bigger than 5";
                }
        
                return null;
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed:() => _isLoading ? null : handleLogin(),
              child: _isLoading
                ? Padding(
                  padding: const EdgeInsets.all(12),
                  child: const CircularProgressIndicator(),
                )
                : Padding(
                  padding: const EdgeInsets.all(12),
                  child: const Text('Log in'),
                ),
            ) 
          ],
          ),
      )
      )
    );
  }
}