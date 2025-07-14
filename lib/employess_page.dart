import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:talepsikayet/utils/shared.dart';
import 'dart:convert';
import 'login_page.dart';

class Complaint {
  final int id;
  final String baslik;
  final String aciklama;
  bool tamamlandi;
  final String departman;

  Complaint({
    required this.id,
    required this.baslik,
    required this.aciklama,
    required this.tamamlandi,
    required this.departman,
  });

  factory Complaint.fromJson(Map<String, dynamic> json) {
    return Complaint(
      id: json['ID'] ?? 0,
      baslik: json['basvuru_tipi'] ?? '', // doğru alan
      aciklama: json['icerik'] ?? '', // doğru alan
      tamamlandi: json['tamamlandi'] == 1,
      departman: json['departman'] ?? '', // doğru alan
    );
  }
}

void main() {
  runApp(
    MaterialApp(
      theme: ThemeData(scaffoldBackgroundColor: Colors.white),
      home: EmployeesPage(),
    ),
  );
}

class EmployeesPage extends StatefulWidget {
  @override
  _EmployeesPageState createState() => _EmployeesPageState();
}

class _EmployeesPageState extends State<EmployeesPage> {
  List<Complaint> complaints = [];
  bool isLoading = true;
  String filter = 'Tümü';
  List<String> departments = [
    'Fen İşleri',
    'İmar',
    'İnsan Kaynakları',
    'Bilgi İşlem',
  ];
  String selectedDepartment = 'Departman Seç';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchComplaints();
  }

  Future<void> fetchComplaints() async {
    setState(() => isLoading = true);
    final url = Uri.parse('http:// 127.0.0.1:3000/api/veriler');
    try {
      final response = await http.get(url);

      print('API STATUS: ${response.statusCode}');
      print('API RESPONSE: ${response.body}'); // ✅ API çıktısını gör

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        List<dynamic> data;
        if (decoded is List) {
          data = decoded;
        } else if (decoded is Map<String, dynamic> &&
            decoded.containsKey('data')) {
          data = decoded['data'];
        } else {
          throw Exception('Beklenmeyen veri formatı');
        }

        setState(() {
          complaints = data.map((json) => Complaint.fromJson(json)).toList();
          isLoading = false;
        });
      } else {
        throw Exception('Veri alınamadı');
      }
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint('Hata: $e');
    }
  }

  Future<void> markAsCompleted(int id) async {
    final url = Uri.parse('http://10.0.2.2:3000/api/veriler/$id');
    try {
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"basvuru_durumu": "tamamlandi"}),
      );

      if (response.statusCode == 200) {
        setState(() {
          complaints.firstWhere((c) => c.id == id).tamamlandi = true;
        });
      } else {
        throw Exception('Güncelleme başarısız');
      }
    } catch (e) {
      debugPrint('Güncelleme hatası: $e');
    }
  }

  List<Complaint> get filteredComplaints {
    List<Complaint> filtered = complaints;

    if (selectedDepartment != 'Departman Seç') {
      filtered = filtered
          .where((c) => c.departman == selectedDepartment)
          .toList();
    }
    if (filter == 'Tamamlanan') {
      filtered = filtered.where((c) => c.tamamlandi).toList();
    } else if (filter == 'Bekleyen') {
      filtered = filtered.where((c) => !c.tamamlandi).toList();
    }
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (c) =>
                c.baslik.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                c.aciklama.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }

    print('Filtrelenen Şikayet Sayısı: ${filtered.length}');
    return filtered;
  }

  Widget buildFilterButton(String label) {
    bool isSelected = filter == label;
    return Expanded(
      child: Container(
        margin: EdgeInsets.zero,
        child: OutlinedButton(
          onPressed: () {
            setState(() {
              filter = label;
            });
          },
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            side: const BorderSide(color: Colors.black, width: 1),
            foregroundColor: Colors.black,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.black,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget buildDepartmentDropdown() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedDepartment,
          isExpanded: true,
          items: ['Departman Seç', ...departments].map((dep) {
            return DropdownMenuItem(value: dep, child: Text(dep));
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                selectedDepartment = value;
              });
            }
          },
        ),
      ),
    );
  }

  Widget buildSearchField() {
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Ara...',
          border: InputBorder.none,
          isCollapsed: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          suffixIcon: const Icon(Icons.search),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Future<void> _logout() async {
    await clearUserSession();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          tooltip: 'Geri',
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Row(
          children: [
            Image.asset('assets/mezitbellogo.png', height: 60),
            const SizedBox(width: 10),
            Expanded(child: Container()),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'TALEP / ŞİKAYETLER',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Expanded(child: buildDepartmentDropdown()),
                const SizedBox(width: 8),
                Expanded(child: buildSearchField()),
              ],
            ),
            Row(
              children: [
                buildFilterButton("Tümü"),
                buildFilterButton("Bekleyen"),
                buildFilterButton("Tamamlanan"),
              ],
            ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredComplaints.isEmpty
                  ? const Center(child: Text("Görüntülenecek talep yok"))
                  : ListView.builder(
                      itemCount: filteredComplaints.length,
                      itemBuilder: (context, index) {
                        final complaint = filteredComplaints[index];
                        return Card(
                          color: Colors.white,
                          child: ListTile(
                            title: Text(complaint.baslik),
                            subtitle: Text(complaint.aciklama),
                            trailing: complaint.tamamlandi
                                ? const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  )
                                : ElevatedButton(
                                    child: const Text("Tamamlandı"),
                                    onPressed: () =>
                                        markAsCompleted(complaint.id),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey[700],
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _logout,
        label: const Text('Çıkış Yap', style: TextStyle(color: Colors.black)),
        icon: const Icon(Icons.logout, color: Colors.black),
        backgroundColor: Colors.white,
      ),
    );
  }
}
