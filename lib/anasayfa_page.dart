import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talepsikayet/utils/shared.dart';
import 'dart:convert';
import 'complaint_page.dart';
import 'login_page.dart'; // LoginPage'i import ediyoruz

class AnasayfaPage extends StatefulWidget {
  final String token;

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

  Future<void> _confirmAndDelete(int id) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Silmek istiyor musunuz?'),
        content: const Text('Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Evet', style: TextStyle(color: Colors.red)) ,
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hayır', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await _deleteComplaint(id);
    }
  }

  Future<void> _deleteComplaint(int id) async {
    final url = Uri.parse('http://10.0.2.2:3000/api/veriler/$id');

    try {
      final response = await http.delete(url);

      if (response.statusCode == 200) {
        setState(() {
          complaints.removeWhere((item) => item['id'] == id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kayıt başarıyla silindi')),
        );
      } else {
        throw Exception('Silinemedi: ${response.statusCode}');
      }
    } catch (e) {
      print("Silme hatası: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silme işlemi sırasında bir hata oluştu')),
      );
    }
  }

  Future<void> _logout() async {
    await clearUserSession();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Talep / Şikayetlerim'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: _logout,
            tooltip: 'Çıkış Yap',
          ),
        ],
      ),
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
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            child: const Text('Düzenle'),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.black,
                            ),
                            onPressed: () => _navigateToEditPage(item),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.black),
                            onPressed: () => _confirmAndDelete(int.tryParse(item['id'].toString()) ?? 0),
                          ),
                        ],
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
              style: TextStyle(color: Colors.red),
            ),
            icon: const Icon(Icons.add, color: Colors.red),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.red, width: 2),
            ),
          ),
        ),
      ),
    );
  }
}
