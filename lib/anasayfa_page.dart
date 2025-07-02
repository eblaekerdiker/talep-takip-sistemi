import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'complaint_page.dart';

class AnasayfaPage extends StatefulWidget {
  final String token;  // Token zorunlu parametre olarak eklendi

  const AnasayfaPage({super.key, required this.token});

  @override
  State<AnasayfaPage> createState() => _AnasayfaPageState();
}

class _AnasayfaPageState extends State<AnasayfaPage> {
  List<Map<String, dynamic>> complaints = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchComplaints();
  }

  Future<void> fetchComplaints() async {
    final url = Uri.parse('http://10.0.2.2:3000/api/veriler');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        setState(() {
          //complaints = data.cast<Map<String, dynamic>>();
          complaints = List<Map<String, dynamic>>.from(data);
          isLoading = false;
        });
      } else {
        throw Exception('Veri alınamadı: ${response.statusCode}');
      }
    } catch (e) {
      print("Hata: $e");
      setState(() => isLoading = false);
    }
  }

  void _navigateToCreatePage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ComplaintPage(token: widget.token),
      ),
    );

    if (result != null) {
      fetchComplaints();
    }
  }

  void _navigateToEditPage(Map<String, dynamic> item) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ComplaintPage(
          token: widget.token,
          existingComplaint: {
            'id': item['id'].toString(),
            'tip': item['tur'] ?? 'Talep',
            'konu': item['konu'] ?? '',
            'aciklama': item['aciklama'] ?? '',
          },
        ),
      ),
    );

    if (result != null) {
      fetchComplaints();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Talep / Şikayetlerim')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : complaints.isEmpty
              ? const Center(child: Text('Henüz talep/şikayet oluşturulmadı'))
              : ListView.builder(
                  itemCount: complaints.length,
                  itemBuilder: (context, index) {
                    final item = complaints[index];
                    return ListTile(
                      title: Text(item['konu'] ?? 'Konu yok'),
                      subtitle: Text(item['aciklama'] ?? 'Açıklama yok'),
                      trailing: TextButton(
                        child: const Text('Düzenle'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.black),// Yazı rengi siyah
                        onPressed: () => _navigateToEditPage(item),
                      ),
                    );
                  },
                ),
      floatingActionButton: Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: FloatingActionButton.extended(
            onPressed: _navigateToCreatePage,
            label: const Text(
              'Oluştur',
            style: TextStyle(color: Colors.red)),
            icon: const Icon(Icons.add, color: Colors.red),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.red, width: 2)
            ),
          ),
        ),
      ),
    );
  }
}
