import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import 'dart:convert';

class AuthApi{

  Future<void> login(String email, String password) async {
    final response = await http.post(Uri.parse("http://localhost:5000/api/auth/login"),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'email': email,
      'password': password
    }));

    if (response.statusCode == 200){
      final data = jsonDecode(response.body);
      final token = data['token'];

      developer.log("Login Succesfull token: $token");
    } else{
      developer.log("Login unsuccessfull: Status Code ${response.statusCode}");
    }
  }
  
}