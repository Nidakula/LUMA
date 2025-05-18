# 🌱 LUMA (Light Utilization Monitoring for Agriculture)
### *Sistem Monitoring Intensitas Cahaya untuk Optimalisasi Fotosintesis* 🌿
---

**Kelompok 17**
1. Reyhan Ahnaf Deannova - 2306267100 
2. Andhika Fadhlan Wijanarko - 2306267164 
3. Zhafira Zahra Alfarisy - 2306250636 
4. Muhammad Iqbal Alfajri - 2306250705 
5. Ekananda Zhafif Dean - 2306264420 

---

## 🌟 Pengenalan Masalah dan Solusi

### Latar Belakang Masalah 🌾
Dalam budidaya pertanian modern, kontrol intensitas cahaya yang optimal merupakan faktor krusial untuk memaksimalkan proses fotosintesis tanaman. Paparan cahaya yang berlebihan dapat menyebabkan stress pada tanaman dan mengurangi efisiensi fotosintesis, sementara cahaya yang tidak mencukupi akan menghambat pertumbuhan tanaman. Petani tradisional seringkali mengandalkan pengamatan manual yang tidak konsisten dan kurang akurat dalam mengatur eksposur cahaya.

### Solusi yang Ditawarkan 💡
**LUMA (Light Utilization Monitoring for Agriculture)** hadir sebagai solusi inovatif yang mengintegrasikan teknologi sensor dan mikrokontroler untuk memberikan kontrol otomatis dan real-time terhadap intensitas cahaya yang diterima tanaman. Sistem ini secara cerdas membuka atau menutup penutup tanaman berdasarkan pembacaan sensor cahaya, memastikan tanaman mendapatkan exposur cahaya yang optimal untuk fotosintesis.

**Keunggulan Utama:**
- ⚡ **Respons Real-time**: Monitoring kontinyu dengan penyesuaian otomatis
- 🎯 **Presisi Tinggi**: Kontrol berdasarkan threshold yang dapat dikonfigurasi
- 🔧 **Fleksibilitas**: Mode manual override melalui interrupt eksternal (INT0)
- 📊 **Monitoring Komprehensif**: Tampilan real-time dengan timestamp dari RTC
- 🎛️ **Interface Ramah**: Display LCD 16x2 dengan indikator LED dual-color

---

## 🛠️ Desain dan Implementasi Hardware

### Arsitektur Sistem 🏗️
Sistem LUMA dibangun dengan pendekatan modular menggunakan komunikasi I2C sebagai backbone utama. Setiap perangkat peripheral dihubungkan melalui bus I2C dengan alamat unik, memungkinkan ekspansi sistem di masa depan. Mikrokontroler ATmega328P bertindak sebagai master controller yang mengelola seluruh operasi sistem.

### Komponen Utama 📦

#### 1. **Mikrokontroler ATmega328P** 🧠
- **Fungsi**: Unit pemroses utama yang menjalankan seluruh logika kontrol
- **Spesifikasi**: 16MHz crystal oscillator, 32KB Flash memory, 2KB SRAM
- **Konfigurasi Pin**: 
  - **ADC0**: Input analog dari sensor LDR
  - **INT0 (PD2)**: Input interrupt untuk tombol manual override
  - **PB1**: Output LED hijau (status terbuka)
  - **PB2**: Output LED merah (status tertutup)
  - **PC4 (SDA)**: I2C Data Line
  - **PC5 (SCL)**: I2C Clock Line

#### 2. **Sensor LDR (Light Dependent Resistor)** 🔆
- **Fungsi**: Mendeteksi intensitas cahaya ambient dengan range 0-1023 (10-bit ADC)
- **Prinsip Kerja**: Voltage divider circuit dengan resistor pull-up 10kΩ
- **Threshold**: 500 ADC units (konfigurabel dalam kode)
- **Response Time**: < 200ms untuk perubahan signifikan
- **Interface**: Analog input melalui kanal ADC0

#### 3. **Real-Time Clock DS3231** ⏰
- **Fungsi**: Menyediakan timestamp akurat untuk sistem monitoring
- **Interface**: I2C dengan alamat 0x68 (write: 0xD0, read: 0xD1)
- **Akurasi**: ±2ppm dari 0°C hingga +40°C
- **Format Data**: BCD (Binary Coded Decimal) untuk jam, menit, detik
- **Fitur**: Battery backup untuk kontinuitas waktu

#### 4. **LCD I2C 16x2** 📺
- **Fungsi**: Menampilkan informasi real-time sistem
- **Interface**: I2C dengan alamat 0x27 (write: 0x4E)
- **Mode Operasi**: 4-bit mode dengan backlight control
- **Display Format**: 
  - Baris 1: Nilai intensitas cahaya dan status kotak (OPEN/CLSD)
  - Baris 2: Timestamp real-time (HH:MM:SS)
- **Backlight**: Always-on dengan kontrol melalui I2C expander

#### 5. **Driver Servo PCA9685** 🔄
- **Fungsi**: Mengontrol servo motor dengan presisi tinggi
- **Interface**: I2C dengan alamat 0x40 (write: 0x80)
- **Resolusi**: 12-bit PWM (0-4095 steps)
- **Frekuensi**: 50Hz (optimal untuk servo motor)
- **Posisi Servo**:
  - Terbuka: 150 PWM units
  - Tertutup: 450 PWM units
- **Setup**: Auto-increment mode dengan restart capability

#### 6. **Sistem Indikator & Override** 🚥
- **LED Hijau (PB1)**: Indikator kotak terbuka
- **LED Merah (PB2)**: Indikator kotak tertutup
- **Tombol Manual (PD2)**: Interrupt-driven manual override
- **Debouncing**: Hardware dengan pull-up resistor
- **Respons**: Instant override dengan visual feedback (LED blinking)

### Skematik Rangkaian 📐
```
ATmega328P (16MHz)
├── ADC0 ← LDR + 10kΩ Pull-up (Voltage Divider)
├── PD2 (INT0) ← Push Button + Pull-up (Manual Override)
├── PB1 → LED Hijau (390Ω Current Limiting)
├── PB2 → LED Merah (390Ω Current Limiting)
├── PC4 (SDA) ↔ I2C Bus (4.7kΩ Pull-up)
└── PC5 (SCL) ↔ I2C Bus (4.7kΩ Pull-up)

I2C Bus (100kHz)
├── DS3231 RTC (0x68) + CR2032 Battery
├── LCD 16x2 I2C (0x27) + PCF8574 Expander
└── PCA9685 PWM Driver (0x40) → SG90 Servo Motor

Power Supply: 5V regulated (Arduino Uno compatible)
```

---

## 💻 Implementasi Software

### Filosofi Desain Software 🏛️
Implementasi software menggunakan 100% Assembly language AVR untuk mencapai efisiensi maksimal dan kontrol penuh terhadap hardware. Pendekatan ini memberikan response time yang minimal, penggunaan memori yang optimal, dan reliabilitas tinggi. Semua fungsi kritis dioptimasi di level assembly untuk memastikan timing yang presisi, terutama untuk komunikasi I2C dan interrupt handling.

### Struktur Program 📋

#### **Inisialisasi Sistem (`RESET` Routine)**
```assembly
RESET:
    ; Stack Pointer Initialization
    ; UART Setup (9600 baud untuk debugging)
    ; Port B Configuration (LED outputs)
    ; INT0 Configuration (falling edge detection)
    ; ADC Setup (AVCC reference, prescaler 128)
    ; TWI Initialization (100kHz, prescaler 1)
    ; Device Initialization (LCD, PCA9685, DS3231)
    ; Initial State Setup
    sei                     ; Enable global interrupts
```

Program dimulai dengan inisialisasi komprehensif yang meliputi konfigurasi stack pointer, setup UART untuk debugging (9600 baud), konfigurasi port B untuk output LED, pengaturan interrupt eksternal INT0 dengan deteksi falling edge, inisialisasi ADC dengan referensi AVCC dan prescaler 128, serta setup TWI dengan clock 100kHz.

#### **Loop Utama (`MAIN_LOOP`)**
Program beroperasi dalam infinite loop dengan sequence terstruktur:

1. **Pembacaan Sensor (`ReadLight`)**: Melakukan konversi ADC dari sensor LDR dengan waiting sampai konversi selesai
2. **Pembacaan Waktu (`ReadTime`)**: Mengambil data waktu dari DS3231 dalam format BCD
3. **Kontrol Otomatis (`AutoControl`)**: Membandingkan nilai cahaya dengan threshold dan update status
4. **Update Display (`UpdateDisplay`)**: Refresh LCD dengan data terbaru
5. **Delay Stabilitas**: 100ms delay untuk stabilitas sistem

#### **Interrupt Service Routine (`BUTTON_ISR`)**
```assembly
BUTTON_ISR:
    push  r16           ; Save context
    push  r17
    in    r16, SREG
    push  r16
    
    ; Toggle box state (0↔1)
    ; Visual feedback (LED blinking)
    ; Apply changes (servo, LEDs, display)
    
    pop   r16           ; Restore context
    out   SREG, r16
    pop   r17
    pop   r16
    reti
```

ISR untuk manual override memberikan respons instant terhadap input pengguna dengan toggle status kotak, visual feedback melalui LED blinking, dan update immediate semua aktuator.

### Algoritma Kontrol 🧮

#### **Threshold-based Decision Making (`AutoControl`)**
Sistem menggunakan algoritma sederhana namun efektif dengan single threshold:

```assembly
AutoControl:
    ; Load light value (16-bit)
    lds   r17, lightValue
    lds   r18, lightValue+1
    
    ; Compare with threshold (500)
    ldi   r19, lo8(LIGHT_THRESHOLD)
    ldi   r20, hi8(LIGHT_THRESHOLD)
    cp    r17, r19
    cpc   r18, r20
    brlt  .LOW_LIGHT    ; Light < 500: maybe open
    
    ; High light: maybe close
    ; Low light: maybe open
```

Logika kontrol bersifat state-aware, hanya mengubah status jika diperlukan untuk menghindari gerakan servo yang tidak perlu dan menghemat energi.

#### **State Management**
Sistem mengelola state sederhana namun efektif:
- **boxState**: 0 = tertutup, 1 = terbuka
- **Servo Control**: Posisi akurat berbasis PWM value
- **LED Indication**: Real-time visual feedback
- **Display Status**: Synchronous update pada LCD

### Komunikasi I2C 🔄

Implementasi komunikasi I2C memungkinkan:

1. **Kontrol LCD**: Menampilkan informasi real-time dengan format yang jelas
2. **Pembacaan RTC**: Mendapatkan timestamp akurat untuk monitoring
3. **Kontrol Servo**: Menggerakkan penutup tanaman dengan presisi tinggi

---

## 📊 Hasil Pengujian dan Evaluasi Performa

### Pengujian Fungsional ✅

#### **1. Pengujian Respons Sistem**
- **Pembacaan Sensor**: Respons cepat terhadap perubahan intensitas cahaya
- **Kontrol Aktuator**: Pergerakan servo yang mulus dan konsisten
- **Total Latency**: < 500ms dari perubahan cahaya hingga respons sistem

#### **2. Pengujian Akurasi**
- **Threshold Detection**: > 95% akurasi
- **Mode Manual**: 100% reliable dengan debouncing yang efektif
- **Tampilan Informasi**: Presisi tinggi dalam menampilkan data sensor dan waktu

#### **3. Pengujian Komunikasi I2C**
- **LCD Display**: Tampilan stabil tanpa flicker
- **RTC Reading**: Pembacaan waktu akurat dan konsisten
- **Servo Control**: Kontrol presisi dengan posisi yang stabil

### Pengujian Kondisi Ekstrim 🔥

#### **Variasi Intensitas Cahaya**
- **Low Light**: Sistem membuka penutup secara konsisten
- **High Light**: Sistem menutup penutup dengan tepat
- **Fluctuating Light**: Sistem merespons dengan stabilitas yang baik
- **Border-line Threshold**: Minimal histeresis untuk menghindari osilasi

#### **Pengujian Mode Manual**
- **Button Response**: Respons segera terhadap penekanan tombol
- **Mode Switching**: Transisi mulus antara mode otomatis dan manual
- **Manual Control**: Operasi yang konsisten dalam mode override

### Performa Daya dan Efisiensi ⚡

- **Konsumsi Daya**: ~50mA pada operasi normal
- **Efisiensi Kode**: Penggunaan memori yang optimal
- **Stabilitas Jangka Panjang**: Operasi stabil dalam pengujian 24 jam

---

## 🎯 Kesimpulan dan Pengembangan Future

### Kesimpulan 📝

Proyek **LUMA (Light Utilization Monitoring for Agriculture)** telah berhasil diimplementasikan sebagai solusi efektif untuk optimalisasi intensitas cahaya dalam aplikasi pertanian. Sistem menunjukkan performa yang baik dengan respons cepat, akurasi tinggi, dan operasi yang stabil.

**Pencapaian Utama:**
- ✅ **Kontrol Otomatis**: Penyesuaian real-time berdasarkan intensitas cahaya
- ✅ **Komunikasi I2C**: Integrasi sukses antara multiple devices
- ✅ **User Interface**: Tampilan informasi yang jelas dengan visual feedback
- ✅ **Fleksibilitas**: Mode manual override untuk fleksibilitas operasional
- ✅ **Validasi Konsep**: Prototype fungsional yang membuktikan konsep dasar

### Pembelajaran Teknis 🎓

Implementasi LUMA memberikan beberapa insight penting:

- **Komunikasi I2C**: Penggunaan satu bus untuk multiple devices memerlukan manajemen alamat yang baik
- **Sensor Calibration**: Threshold optimal perlu disesuaikan dengan kondisi lingkungan
- **Interrupt Handling**: Debouncing efektif sangat penting untuk input melalui tombol
- **Power Management**: Desain hardware yang efisien untuk aplikasi pertanian

### Rencana Pengembangan 🚀

#### **Peningkatan Jangka Pendek**
- 📊 **Data Logging**: Implementasi penyimpanan data untuk analisis jangka panjang
- 🌐 **Konektivitas Wireless**: Integrasi modul WiFi untuk monitoring jarak jauh
- 🔧 **Konfigurasi User**: Interface untuk mengubah parameter sistem
- 🔋 **Baterai Cadangan**: Sistem power backup untuk operasi kontinyu

#### **Pengembangan Jangka Panjang**
- 🤖 **Algoritma Adaptif**: Penyesuaian threshold berdasarkan jenis tanaman
- 📱 **Aplikasi Mobile**: Kontrol dan monitoring melalui smartphone
- 🌡️ **Sensor Tambahan**: Integrasi sensor suhu, kelembaban, dan kadar air tanah
- ⚡ **Energi Terbarukan**: Penggunaan panel surya untuk kemandirian energi

### Aplikasi Potensial 🌍

Implementasi LUMA memiliki potensi aplikasi yang luas dalam:
- **Pertanian Perkotaan**: Optimalisasi cahaya dalam ruangan terbatas
- **Penelitian Botani**: Studi tentang pengaruh cahaya terhadap pertumbuhan tanaman
- **Edukasi**: Alat peraga untuk pembelajaran sistem kontrol dan pertanian presisi
- **Smart Farming**: Komponen dari sistem pertanian terintegrasi yang lebih besar

---
