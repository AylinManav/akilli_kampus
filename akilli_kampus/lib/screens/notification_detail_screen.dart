import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationDetailScreen extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final String userRole;

  const NotificationDetailScreen({
    super.key, 
    required this.docId, 
    required this.data, 
    required this.userRole
  });

  // ADMIN: AÇIKLAMA DÜZENLEME FONKSİYONU
  void _showEditDescriptionDialog(BuildContext context) {
    final TextEditingController _editController = TextEditingController(text: data['description']);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Açıklamayı Düzenle"),
        content: TextField(
          controller: _editController,
          maxLines: 4,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: "Yeni açıklamayı yazın...",
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Vazgeç")),
          ElevatedButton(
            onPressed: () async {
              if (_editController.text.isNotEmpty) {
                await FirebaseFirestore.instance.collection('notifications').doc(docId).update({
                  'description': _editController.text, // Firestore güncelleme 
                });
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Açıklama başarıyla güncellendi.")),
                  );
                }
              }
            },
            child: const Text("Güncelle"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Bildirim Detayı"),
        backgroundColor: Colors.blueAccent,
        actions: [
          // SADECE ADMINLER İÇİN: AÇIKLAMA DÜZENLEME BUTONU 
          if (userRole == 'Admin')
            IconButton(
              icon: const Icon(Icons.edit_note, size: 28),
              tooltip: "Açıklamayı Düzenle",
              onPressed: () => _showEditDescriptionDialog(context),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık, Tür ve Açıklama
            Text(data['title'] ?? 'Başlıksız', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Chip(
              label: Text(data['type'] ?? 'Genel'), 
              backgroundColor: Colors.blueAccent.withOpacity(0.1)
            ),
            const Divider(height: 30),

            const Text("Açıklama:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text(data['description'] ?? 'Açıklama yok.', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),

            // Durum ve Zaman
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Durum: ${data['status']}", 
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    color: data['status'] == 'Çözüldü' ? Colors.green : Colors.red
                  )
                ),
                Text("Tarih: ${data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate().toString().substring(0, 16) : 'Belirtilmedi'}"),
              ],
            ),
            const SizedBox(height: 30),

            // 1. ADMIN PANELİ: DURUM GÜNCELLEME VE SİLME
            if (userRole == 'Admin') ...[
              const Text("Yönetici İşlemleri (Durum Güncelle):", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _adminButton(context, 'Açık', Colors.red),
                  _adminButton(context, 'İnceleniyor', Colors.orange),
                  _adminButton(context, 'Çözüldü', Colors.green),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _showDeleteConfirmDialog(context),
                icon: const Icon(Icons.delete_forever),
                label: const Text("Bu Bildirimi Tamamen Sil"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade900,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 45)
                ),
              ),
            ],

            const SizedBox(height: 20),

            // 2. USER: TAKİP SİSTEMİ
            if (userRole == 'User' && user != null)
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return ElevatedButton(
                      onPressed: () => _toggleFollow(user.uid, false),
                      child: const Text("Takip Sistemini Etkinleştir"),
                    );
                  }
                  
                  Map<String, dynamic>? userData = snapshot.data!.data() as Map<String, dynamic>?;
                  List followed = userData?['followedNotifications'] ?? [];
                  bool isFollowing = followed.contains(docId);

                  return ElevatedButton.icon(
                    onPressed: () => _toggleFollow(user.uid, isFollowing),
                    icon: Icon(isFollowing ? Icons.bookmark_remove : Icons.bookmark_add),
                    label: Text(isFollowing ? "Takibi Bırak" : "Bildirimi Takip Et"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isFollowing ? Colors.grey : Colors.blueAccent,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50)
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _adminButton(BuildContext context, String status, Color color) {
    return ElevatedButton(
      onPressed: () => _updateStatus(status, context), 
      style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white),
      child: Text(status),
    );
  }

  void _updateStatus(String newStatus, BuildContext context) {
    FirebaseFirestore.instance.collection('notifications').doc(docId).update({
      'status': newStatus,
    }).then((_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Durum başarıyla '$newStatus' yapıldı."), backgroundColor: Colors.black87),
        );
      }
    });
  }

  void _showDeleteConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Emin misiniz?"),
        content: const Text("Bu bildirimi silmek geri alınamaz."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Vazgeç")),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('notifications').doc(docId).delete();
              if (context.mounted) {
                Navigator.pop(context); 
                Navigator.pop(context); 
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Bildirim başarıyla silindi.")),
                );
              }
            },
            child: const Text("Evet, Sil", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _toggleFollow(String userId, bool isFollowing) {
    DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(userId);
    if (isFollowing) {
      userRef.update({'followedNotifications': FieldValue.arrayRemove([docId])}); 
    } else {
      userRef.set({
        'followedNotifications': FieldValue.arrayUnion([docId]) 
      }, SetOptions(merge: true));
    }
  }
}