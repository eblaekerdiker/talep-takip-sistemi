import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/mahalle_model.dart';

class MahalleDropdown extends StatefulWidget {
  @override
  _MahalleDropdownState createState() => _MahalleDropdownState();
}

class _MahalleDropdownState extends State<MahalleDropdown> {
  List<Mahalle> mahalleler = [];
  Mahalle? secilenMahalle;

  @override
  void initState() {
    super.initState();
    loadMahalleler();
  }

  Future<void> loadMahalleler() async {
    final jsonStr = await rootBundle.loadString('assets/csbm.json');
    final jsonList = json.decode(jsonStr) as List;

    setState(() {
      mahalleler = jsonList.map((e) => Mahalle.fromJson(e)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Mahalle Seçimi")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButton<Mahalle>(
              value: secilenMahalle,
              hint: Text('Mahalle Seçin'),
              isExpanded: true,
              items: mahalleler.map((mahalle) {
                return DropdownMenuItem(value: mahalle, child: Text(mahalle.r));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  secilenMahalle = value;
                });
              },
            ),
            const SizedBox(height: 20),
            if (secilenMahalle != null)
              Expanded(
                child: ListView.builder(
                  itemCount: secilenMahalle!.m.length,
                  itemBuilder: (context, index) {
                    final yol = secilenMahalle!.m[index];
                    return ListTile(title: Text("${yol.name} (${yol.type})"));
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
