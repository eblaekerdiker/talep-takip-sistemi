import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ComplaintPage extends StatefulWidget {
  final String token;
  final Map<String, String>? existingComplaint;

  const ComplaintPage({super.key, required this.token, this.existingComplaint});

  @override
  State<ComplaintPage> createState() => _ComplaintPageState();
}

class _ComplaintPageState extends State<ComplaintPage> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedType = 'Talep';
  File? _selectedImage;
  Uint8List? _webImage;

  final List<String> _types = ['Talep', 'Şikayet'];

  @override
  void initState() {
    super.initState();
    if (widget.existingComplaint != null) {
      _selectedType = widget.existingComplaint!['tip'] ?? 'Talep';
      _subjectController.text = widget.existingComplaint!['konu'] ?? '';
      _descriptionController.text = widget.existingComplaint!['icerik'] ?? '';
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  OutlineInputBorder get _blackBorder =>
      const OutlineInputBorder(borderSide: BorderSide(color: Colors.black));

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _webImage = bytes;
          _selectedImage = null;
        });
      } else {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _webImage = null;
        });
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();
    final userString = await prefs.getString('user');
    Map<String, dynamic>? userMap;

    if (userString != null) {
      print('SharedPreferences user string: $userString');
      try {
        final firstDecode = jsonDecode(userString);
        userMap = jsonDecode(firstDecode) as Map<String, dynamic>;
      } catch (e) {
        print('JSON decode hatası: $e');
      }
    }

    final uri = Uri.parse('http://10.0.2.2:3000/api/veri-ekle');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer ${widget.token}'
      ..fields['basvuru_tipi'] = _selectedType
      ..fields['icerik'] = _descriptionController.text
      ..fields['isim'] = userMap?['isim'] ?? 'Test'
      ..fields['soyisim'] = userMap?['soyisim'] ?? 'Kullanici'
      ..fields['konu'] = _subjectController.text;

    if (!kIsWeb && _selectedImage != null) {
      final imageStream = http.ByteStream(_selectedImage!.openRead());
      final imageLength = await _selectedImage!.length();
      final multipartFile = http.MultipartFile(
        'dosya',
        imageStream,
        imageLength,
        filename: _selectedImage!.path.split('/').last,
      );
      request.files.add(multipartFile);
    }

    try {
      final response = await request.send();
      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.pop(context, {
          'basvuru_tipi': _selectedType,
          'icerik': _descriptionController.text,
          'konu': _subjectController.text,
        });
      } else {
        final respStr = await response.stream.bytesToString();
        throw Exception('Sunucu hatası: ${response.statusCode}\n$respStr');
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Hata'),
          content: Text('Gönderim başarısız oldu: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tamam'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  widget.existingComplaint != null
                      ? 'TALEP / ŞİKAYET GÖNDER'
                      : 'TALEP / ŞİKAYET GÖNDER',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              DropdownButtonFormField<String>(
                value: _selectedType,
                items: _types
                    .map(
                      (type) =>
                          DropdownMenuItem(value: type, child: Text(type)),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _selectedType = value!),
                decoration: InputDecoration(
                  labelText: 'Tür Seçiniz',
                  border: _blackBorder,
                  enabledBorder: _blackBorder,
                  focusedBorder: _blackBorder,
                ),
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _subjectController,
                decoration: InputDecoration(
                  labelText: 'Konu İçeriği',
                  border: _blackBorder,
                  enabledBorder: _blackBorder,
                  focusedBorder: _blackBorder,
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Konu içeriğini giriniz'
                    : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'Açıklama',
                  border: _blackBorder,
                  enabledBorder: _blackBorder,
                  focusedBorder: _blackBorder,
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Açıklama giriniz' : null,
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: ElevatedButton.icon(
                        onPressed: _pickImage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                        ),
                        icon: const Icon(Icons.photo),
                        label: const Text('Resim Ekle'),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all(
                            Colors.white,
                          ),
                          foregroundColor: MaterialStateProperty.all(
                            Colors.black,
                          ),
                          overlayColor:
                              MaterialStateProperty.resolveWith<Color?>((
                                states,
                              ) {
                                if (states.contains(MaterialState.hovered)) {
                                  return Colors.red.withOpacity(0.4);
                                }
                                if (states.contains(MaterialState.pressed)) {
                                  return Colors.red.withOpacity(0.6);
                                }
                                return null;
                              }),
                          padding: MaterialStateProperty.all(
                            const EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 15,
                            ),
                          ),
                        ),
                        child: const Text('Gönder'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (kIsWeb && _webImage != null)
                SizedBox(height: 150, child: Image.memory(_webImage!))
              else if (!kIsWeb && _selectedImage != null)
                SizedBox(height: 150, child: Image.file(_selectedImage!)),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
