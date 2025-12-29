import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddNotificationScreen extends StatefulWidget {
  const AddNotificationScreen({super.key});

  @override
  State<AddNotificationScreen> createState() => _AddNotificationScreenState();
}

class _AddNotificationScreenState extends State<AddNotificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedType = 'Sağlık';

  // KONUM SEÇİMİ İÇİN DEĞİŞKENLER
  double? _selectedX;
  double? _selectedY;

  void _saveNotification() async {
    if (!_formKey.currentState!.validate()) return;

    // Konum seçilip seçilmediği kontrolü
    if (_selectedX == null || _selectedY == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen harita üzerinden bir konum seçin!"), backgroundColor: Colors.orange),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'title': _titleController.text, 
        'description': _descriptionController.text, 
        'type': _selectedType, 
        'status': 'Açık', 
        'createdAt': FieldValue.serverTimestamp(),
        'posX': _selectedX, // Harita üzerindeki X koordinatı 
        'posY': _selectedY, // Harita üzerindeki Y koordinatı 
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Bildirim başarıyla oluşturuldu!"), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Yeni Olay Bildir"), backgroundColor: Colors.blueAccent),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tür Seçimi
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: const InputDecoration(labelText: "Olay Türü"),
                  items: ['Sağlık', 'Güvenlik', 'Çevre', 'Teknik Arıza', 'Kayıp-Buluntu']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedType = val!),
                ),
                const SizedBox(height: 15),

                // Başlık
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: "Başlık", border: OutlineInputBorder()),
                  validator: (val) => (val == null || val.isEmpty) ? "Başlık boş olamaz" : null,
                ),
                const SizedBox(height: 15),

                // Açıklama
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: "Açıklama", border: OutlineInputBorder()),
                  maxLines: 3,
                  validator: (val) => (val == null || val.isEmpty) ? "Açıklama boş olamaz" : null,
                ),
                const SizedBox(height: 20),

                // HARİTA ÜZERİNDEN KONUM SEÇİMİ
                const Text("📍 Konum Seçmek İçin Haritaya Dokunun:", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                GestureDetector(
                  onTapDown: (details) {
                    setState(() {
                      // Dokunulan yerin koordinatlarını kaydediyoruz
                      _selectedX = details.localPosition.dx;
                      _selectedY = details.localPosition.dy;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(border: Border.all(color: Colors.blueAccent)),
                    child: Stack(
                      children: [
                        Image.asset('assets/kampus_plan.png', fit: BoxFit.contain),
                        // Seçilen konumu gösteren Pin
                        if (_selectedX != null && _selectedY != null)
                          Positioned(
                            left: _selectedX! - 15,
                            top: _selectedY! - 30,
                            child: const Icon(Icons.location_on, color: Colors.red, size: 35),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                ElevatedButton(
                  onPressed: _saveNotification,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text("Bildirimi Gönder", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}