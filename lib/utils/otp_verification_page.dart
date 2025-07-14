import 'package:flutter/material.dart';

class OtpVerificationPage extends StatefulWidget {
  final String phoneNumber;
  final void Function(String code) onCodeSubmitted;

  const OtpVerificationPage({
    Key? key,
    required this.phoneNumber,
    required this.onCodeSubmitted,
  }) : super(key: key);

  @override
  _OtpVerificationPageState createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _isSubmitting = false;

  void _submitCode() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isSubmitting = true);
      Future.delayed(const Duration(seconds: 1), () {
        setState(() => _isSubmitting = false);
        widget.onCodeSubmitted(_codeController.text);
      });
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doğrulama Kodu'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 30),
              const Text(
                "Telefon numaranıza gönderilen kodu girin",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              Text(
                widget.phoneNumber,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              TextFormField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'Doğrulama Kodu',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.length < 4) {
                    return 'Lütfen en az 4 haneli bir kod girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Onayla'),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kod yeniden gönderildi.')),
                  );
                },
                child: const Text('Kodu yeniden gönder'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
