import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  String? username;
  String? newPassword;
  String? confirmPassword;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Şifremi Unuttum'),
        backgroundColor: const Color.fromARGB(255, 99, 156, 213),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Kullanıcı Adı',
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen kullanıcı adınızı giriniz';
                  }
                  username = value;
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Yeni Şifre',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen yeni şifrenizi giriniz';
                  }
                  newPassword = value;
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Yeni Şifre (Tekrar)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen şifreyi tekrar giriniz';
                  }
                  if (value != newPassword) {
                    return 'Şifreler eşleşmiyor';
                  }
                  confirmPassword = value;
                  return null;
                },
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _resetPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 247, 247, 255),
                  foregroundColor: Colors.black,
                ),
                child: const Text('Şifreyi Değiştir'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      try {
        final response = await http.post(
          Uri.parse('http://10.0.2.2:3000/api/sifre-sifirla'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "kullanici_adi": username,
            "yeni_sifre": newPassword,
          }),
        );

        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          _showSuccessDialog("Şifre değiştirme işlemi başarılı.");
        } else {
          _showErrorDialog(data['message'] ?? 'Bir hata oluştu.');
        }
      } catch (e) {
        _showErrorDialog("Sunucuya bağlanılamadı: $e");
      }
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Başarılı"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // dialogu kapat
              Navigator.pop(context); // login sayfasına dön
            },
            child: const Text("Tamam"),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hata"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Tamam"),
          ),
        ],
      ),
    );
  }
}
