# Akıllı Kampüs Sağlık ve Güvenlik Bildirim Uygulaması 🚨📍

Bu proje, Atatürk Üniversitesi Bilgisayar Mühendisliği Bölümü **Mobil Programlama** dersi kapsamında geliştirilmiştir.Uygulama, kampüs içindeki sağlık, güvenlik ve teknik arızaların raporlanmasını ve takibini sağlayan dijital bir platformdur. 

## 🌟 Proje Özeti
Kampüs paydaşlarının güvenliğini artırmak amacıyla geliştirilen bu sistem, kullanıcıların harita üzerinden konum seçerek anlık bildirim oluşturmasına, yöneticilerin ise bu bildirimleri yönetmesine olanak tanır.

## 🛠 Kullanılan Teknolojiler
- **Framework:** Flutter (Dart)
- **Backend:** Firebase Authentication & Cloud Firestore 
- **Konum Servisleri:** İnteraktif Kampüs Haritası (Custom Implementation)
- **Sürüm Kontrolü:** Git 

## 🚀 Temel Özellikler
### 👤 Kullanıcı (User) Modülü
- E-posta ve şifre ile güvenli giriş/kayıt işlemleri.
- Harita üzerinden konum seçerek (Pinleme) yeni olay bildirimi oluşturma.
- Bildirimleri türlerine göre filtreleme ve anahtar kelime ile arama.
- Olayları takip etme ve durum güncellemelerini izleme.

### 🔑 Yönetici (Admin) Modülü
- Tüm kampüs bildirimlerini tek panelden yönetme.
- Bildirim durumlarını (Açık, İnceleniyor, Çözüldü) güncelleme.
- Tüm kullanıcılara anlık "Acil Durum Duyurusu" yayınlama. 

## 📸 Ekran Görüntüleri
<img width="1449" height="865" alt="girişEkranı" src="https://github.com/user-attachments/assets/4384b9a7-586f-4fac-a60a-5f11c6f2269c" />
<img width="1511" height="865" alt="hesapOlustur" src="https://github.com/user-attachments/assets/1d28c2e0-bdac-45af-96f8-5db6f5a15b51" />
<img width="1511" height="861" alt="bildirimlerListesi" src="https://github.com/user-attachments/assets/131f07a6-7e78-4c55-9ad3-414a0911831e" />
<img width="1511" height="861" alt="adminProfili" src="https://github.com/user-attachments/assets/d79487a3-46be-4d86-94a2-540751a2e765" />


## 📂 Dosya Yapısı
- `lib/screens/`: Uygulama arayüz sayfaları.
- `lib/main.dart`: Uygulama giriş ve Firebase yapılandırması.
- `assets/`: Kampüs harita planı ve görseller.

## 📝 Teknik Rapor
Projenin detaylı analizini, ekran listesini ve fonksiyonel açıklamalarını içeren **Teknik Rapor (PDF)** proje ana dizininde yer almaktadır.
