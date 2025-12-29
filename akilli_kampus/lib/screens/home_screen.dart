import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'add_notification_screen.dart';
import 'notification_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String? userRole;
  String? userName;
  String? userUnit;
  bool _emergencyChecked = false;

  String _searchQuery = "";
  String _selectedCategory = "Hepsi";
  bool _showOnlyOpen = false;

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  Future<void> _getUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (mounted) {
        setState(() {
          userRole = doc.data()?['role'] ?? "User";
          userName = doc.data()?['fullName'] ?? "Kullanıcı";
          userUnit = doc.data()?['unit'] ?? "Birim Belirtilmedi";
        });
        _checkForEmergency();
      }
    }
  }

  // 1. ACİL DURUM DUYURUSU YAYINLAMA
  void _showEmergencyAnnouncementDialog() {
    final TextEditingController _announceController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("🚨 Acil Durum Duyurusu Yayınla", style: TextStyle(color: Colors.red)),
        content: TextField(
          controller: _announceController,
          decoration: const InputDecoration(hintText: "Duyuru metnini buraya yazın..."),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              if (_announceController.text.isNotEmpty) {
                await FirebaseFirestore.instance.collection('notifications').add({
                  'title': 'ACİL DURUM DUYURUSU',
                  'description': _announceController.text,
                  'type': 'Güvenlik',
                  'status': 'Açık',
                  'createdAt': FieldValue.serverTimestamp(),
                  'isEmergency': true,
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Acil duyuru tüm kullanıcılara gönderildi.")));
              }
            },
            child: const Text("Yayınla", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showPinInfoCard(String docId, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(_getIconForType(data['type'] ?? ''), color: Colors.blueAccent),
              title: Text(data['title'] ?? 'Başlıksız', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("${data['type']} • Durum: ${data['status']}"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationDetailScreen(docId: docId, data: data, userRole: userRole ?? 'User')));
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 45)),
              child: const Text("Detayı Gör"),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Bildirimi Sil"),
        content: const Text("Bu bildirim kalıcı olarak silinecektir. Emin misiniz?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Vazgeç")),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('notifications').doc(docId).delete();
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bildirim silindi."), backgroundColor: Colors.red));
              }
            },
            child: const Text("Sil", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _checkForEmergency() {
    if (_emergencyChecked) return;
    FirebaseFirestore.instance.collection('notifications').where('status', isEqualTo: 'Açık').where('type', isEqualTo: 'Güvenlik').limit(1).get().then((snapshot) {
      if (snapshot.docs.isNotEmpty && mounted) {
        final data = snapshot.docs.first.data();
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("📢 Kampüs Duyurusu", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            content: Text("${data['title']}\n\n${data['description']}"),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Anladım"))],
          ),
        );
        setState(() => _emergencyChecked = true);
      }
    });
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'Sağlık': return Icons.health_and_safety;
      case 'Güvenlik': return Icons.security;
      case 'Çevre': return Icons.nature_people;
      case 'Teknik Arıza': return Icons.build;
      case 'Kayıp-Buluntu': return Icons.search;
      default: return Icons.notification_important;
    }
  }

  Color _getStatusColor(String status) {
    if (status == 'Açık') return Colors.red;
    if (status == 'İnceleniyor') return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final List<Widget> _pages = <Widget>[
      Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              decoration: InputDecoration(hintText: "Ara...", prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Colors.white),
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                FilterChip(label: const Text("Sadece Açık"), selected: _showOnlyOpen, onSelected: (val) => setState(() => _showOnlyOpen = val), selectedColor: Colors.red.shade100),
                const SizedBox(width: 8),
                ...['Hepsi', 'Sağlık', 'Güvenlik', 'Çevre', 'Teknik Arıza', 'Kayıp-Buluntu'].map((cat) => Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(label: Text(cat), selected: _selectedCategory == cat, onSelected: (selected) => setState(() => _selectedCategory = selected ? cat : "Hepsi")),
                )),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddNotificationScreen())), icon: const Icon(Icons.add_location_alt), label: const Text("Yeni Olay Bildir"), style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 45))),
          ),
          const Divider(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('notifications').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                var docs = snapshot.data?.docs ?? [];
                if (_selectedCategory != "Hepsi") docs = docs.where((doc) => (doc.data() as Map)['type'] == _selectedCategory).toList();
                if (_showOnlyOpen) docs = docs.where((doc) => (doc.data() as Map)['status'] == 'Açık').toList();
                if (_searchQuery.isNotEmpty) {
                  docs = docs.where((doc) {
                    final d = doc.data() as Map;
                    return (d['title'] ?? "").toLowerCase().contains(_searchQuery) || (d['description'] ?? "").toLowerCase().contains(_searchQuery);
                  }).toList();
                }
                if (docs.isEmpty) return const Center(child: Text("Sonuç bulunamadı."));
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final docId = docs[index].id;
                    final bool isEmergency = data['type'] == 'Güvenlik' || data['type'] == 'Sağlık';
                    return Card(
                      shape: isEmergency ? RoundedRectangleBorder(side: const BorderSide(color: Colors.orange, width: 2), borderRadius: BorderRadius.circular(8)) : null,
                      color: isEmergency ? Colors.orange.shade50 : Colors.white,
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationDetailScreen(docId: docId, data: data, userRole: userRole ?? 'User'))),
                        leading: Icon(isEmergency ? Icons.warning : _getIconForType(data['type'] ?? ''), color: isEmergency ? Colors.red : Colors.blueGrey),
                        title: Text(isEmergency ? "🚨 ${data['title']}" : (data['title'] ?? 'Başlıksız'), style: TextStyle(fontWeight: FontWeight.bold, color: isEmergency ? Colors.red.shade900 : Colors.black)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['description'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: _getStatusColor(data['status'] ?? '').withOpacity(0.2), borderRadius: BorderRadius.circular(4)), child: Text(data['status'] ?? 'Açık', style: TextStyle(color: _getStatusColor(data['status'] ?? ''), fontWeight: FontWeight.bold, fontSize: 11))),
                                Text(data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate().toString().substring(0, 16) : 'Tarih Yok', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                              ],
                            ),
                          ],
                        ),
                        trailing: userRole == 'Admin' ? IconButton(icon: const Icon(Icons.delete_sweep, color: Colors.redAccent), onPressed: () => _showDeleteDialog(docId)) : const Icon(Icons.arrow_forward_ios, size: 14),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      // 1: HARİTA SEKMESİ
      Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
        child: Column(
          children: [
            const SizedBox(height: 10),
            const Text('📍 Kampüs Bildirim Haritası', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            Expanded(
              child: InteractiveViewer(
                panEnabled: true, minScale: 0.5, maxScale: 4.0,
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.asset('assets/kampus_plan.png', fit: BoxFit.contain),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('notifications').snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const SizedBox();
                          return Stack(
                            children: snapshot.data!.docs.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              double? posX = data['posX']?.toDouble();
                              double? posY = data['posY']?.toDouble();
                              if (posX == null || posY == null) return const SizedBox();
                              return Positioned(left: posX, top: posY, child: GestureDetector(onTap: () => _showPinInfoCard(doc.id, data), child: Icon(_getIconForType(data['type'] ?? ''), color: _getStatusColor(data['status'] ?? ''), size: 32)));
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // 2: PROFİL VE AYARLAR SEKMESİ
      SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 30),
            const CircleAvatar(radius: 50, backgroundColor: Colors.blueAccent, child: Icon(Icons.person, size: 60, color: Colors.white)),
            const SizedBox(height: 15),
            Text(userName ?? "Kullanıcı", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(user?.email ?? "", style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 5),
            Chip(label: Text("Birim: $userUnit")),
            const Divider(height: 40),

            // ADMIN ÖZEL: ACİL DUYURU YAYINLAMA
            if (userRole == 'Admin') ...[
               const Padding(padding: EdgeInsets.symmetric(horizontal: 16.0), child: Align(alignment: Alignment.centerLeft, child: Text("🛠 Yönetici İşlemleri", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))),
               Padding(
                 padding: const EdgeInsets.all(16.0),
                 child: ElevatedButton.icon(
                   style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, minimumSize: const Size(double.infinity, 50)),
                   onPressed: _showEmergencyAnnouncementDialog,
                   icon: const Icon(Icons.campaign, color: Colors.white),
                   label: const Text("Acil Durum Duyurusu Yayınla", style: TextStyle(color: Colors.white)),
                 ),
               ),
               const Divider(),
            ],

            // BİLDİRİM AYARLARI
            const Padding(padding: EdgeInsets.symmetric(horizontal: 16.0), child: Align(alignment: Alignment.centerLeft, child: Text("🔔 Bildirim Ayarları", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))),
            SwitchListTile(title: const Text("Acil Durum Bildirimleri"), value: true, onChanged: (v) {}, secondary: const Icon(Icons.emergency_share)),
            SwitchListTile(title: const Text("Teknik Arıza Bildirimleri"), value: true, onChanged: (v) {}, secondary: const Icon(Icons.build)),
            
            const Divider(),

            // TAKİP EDİLENLER LİSTESİ
            const Padding(padding: EdgeInsets.symmetric(horizontal: 16.0), child: Align(alignment: Alignment.centerLeft, child: Text("📌 Takip Ettiğim Olaylar", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))),
            const SizedBox(height: 10),
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData || !userSnapshot.data!.exists) return const SizedBox();
                List followedIds = (userSnapshot.data!.data() as Map<String, dynamic>)['followedNotifications'] ?? [];
                if (followedIds.isEmpty) return const Padding(padding: EdgeInsets.all(20.0), child: Text("Takip ettiğiniz olay yok."));
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('notifications').where(FieldPath.documentId, whereIn: followedIds).snapshots(),
                  builder: (context, notifSnapshot) {
                    if (!notifSnapshot.hasData) return const CircularProgressIndicator();
                    final docs = notifSnapshot.data!.docs;
                    return ListView.builder(
                      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        return Card(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5), child: ListTile(leading: Icon(_getIconForType(data['type'] ?? ''), color: Colors.blueAccent), title: Text(data['title'] ?? 'Başlıksız'), subtitle: Text("Durum: ${data['status']}"), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationDetailScreen(docId: docs[index].id, data: data, userRole: userRole ?? 'User')))));
                      },
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Akıllı Kampüs"), backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () async { await FirebaseAuth.instance.signOut(); Navigator.pushReplacementNamed(context, '/'); })]),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(currentIndex: _selectedIndex, onTap: (index) => setState(() => _selectedIndex = index), selectedItemColor: Colors.blueAccent, items: const [BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Akış'), BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Harita'), BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil')]),
    );
  }
}