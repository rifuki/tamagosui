# Day 3: Memahami Object & Dynamic Fields di Sui

## 🤔 Apa itu "Object" dalam Sui? (Analogi Sederhana)

### Analogi Dunia Nyata: Rumah dan Furniture

Bayangkan blockchain tradisional seperti **buku catatan besar** yang berisi semua data:

```
📖 Buku Catatan Ethereum:
Halaman 1: Alice punya 10 ETH
Halaman 2: Bob punya NFT Monkey #123  
Halaman 3: Carol punya 5 USDC
```

Sedangkan **Sui** seperti **dunia nyata dengan benda-benda fisik**:

```
🏠 Rumah Alice (Object)
   - Alamat: 0x123abc (ID unik)
   - Pemilik: Alice
   - Isi: 10 SUI coins

🐵 NFT Monkey (Object) 
   - ID: 0x456def
   - Pemilik: Bob
   - Properties: Name, Image, Rarity

💰 USDC Token (Object)
   - ID: 0x789ghi
   - Pemilik: Carol
   - Amount: 5
```

### Perbedaan Utama

| **Blockchain Tradisional** | **Sui (Object-Based)** |
|---------------------------|------------------------|
| Semua data di "buku besar" | Setiap item = object terpisah |
| Butuh cari di seluruh buku | Langsung akses object |
| Global state | Individual ownership |
| Konflik akses | Parallel processing |

---

## 🏠 Object dalam Tamagosui: Pet sebagai "Rumah Digital"

### Pet = Rumah Digital Anda

```move
public struct Pet has key, store {
    id: UID,                    // 🏠 Alamat rumah (unik)
    name: String,               // 🪪 Nama pet 
    image_url: String,          // 🖼️  Foto pet
    adopted_at: u64,            // 📅 Tanggal adopsi
    stats: PetStats,            // 📊 Status kesehatan
    game_data: PetGameData,     // 🎮 Data game
}
```

**Seperti rumah digital yang:**
- Memiliki alamat unik (`id: UID`)
- Hanya Anda yang bisa masuk dan mengubah isinya
- Berisi barang-barang (stats, data, accessories)
- Bisa dipindahkan ke owner lain

### Contoh Pet Object

```
🏠 Pet "Fluffy" (Object ID: 0x1a2b3c...)
   👤 Owner: Alice
   📊 Energy: 60/100
   😊 Happiness: 80/100  
   🍎 Hunger: 40/100
   💰 Coins: 25
   ⭐ Level: 2
```

---

## 🧳 Apa itu Dynamic Fields?

### Analogi: Tas Ekspansi Tak Terbatas

Bayangkan **Pet** seperti **tas ransel**. Normalnya tas punya kantong tetap:

```
🎒 Tas Biasa (Struct Pet):
├── Kantong Utama: stats (energy, hunger, happiness)
├── Kantong Samping: game_data (coins, level, exp)
└── Kantong Depan: info (name, image, adopted_at)
```

**Dynamic Fields** seperti **kantong ajaib** yang bisa ditambah sesuai kebutuhan:

```
🎒 Tas Ajaib (Pet + Dynamic Fields):
├── Kantong Utama: stats 
├── Kantong Samping: game_data
├── Kantong Depan: info
├── ✨ Kantong Ajaib 1: equipped_item (kacamata)
├── ✨ Kantong Ajaib 2: sleep_started_at (timestamp tidur)
├── ✨ Kantong Ajaib 3: achievements (future)
├── ✨ Kantong Ajaib 4: pets_friends (future)
└── ✨ Kantong Ajaib N: apapun yang dibutuhkan masa depan
```

### Keuntungan Dynamic Fields

1. **Tidak Butuh Ubah Struct Asli**
   ```move
   // Tidak perlu ubah Pet struct untuk tambah fitur
   // Cukup tambah dynamic field baru
   ```

2. **Hemat Space**
   ```move
   // Hanya Pet yang punya aksesori yang nyimpan data aksesori
   // Pet tanpa aksesori tidak buang-buang space
   ```

3. **Ekstensibel Tanpa Batas**
   ```move
   // Bisa tambah fitur baru tanpa breaking changes
   ```

---

## 🔧 Dynamic Fields dalam Tamagosui

### 1. Sistem Aksesori (Equipped Item)

```move
const EQUIPPED_ITEM_KEY: vector<u8> = b"equipped_item";

// Pasang kacamata ke pet
public entry fun equip_accessory(pet: &mut Pet, accessory: PetAccessory) {
    let key = string::utf8(EQUIPPED_ITEM_KEY);
    
    // Masukkan aksesori ke "kantong ajaib" pet
    dynamic_field::add(&mut pet.id, key, accessory);
    
    // Update tampilan pet
    update_pet_image(pet);
}
```

**Analogi**: Seperti memasukkan kacamata ke kantong ajaib dalam tas pet Anda.

### 2. Sistem Sleep Tracking

```move
const SLEEP_STARTED_AT_KEY: vector<u8> = b"sleep_started_at";

// Pet mulai tidur
public entry fun let_pet_sleep(pet: &mut Pet, clock: &Clock) {
    let key = string::utf8(SLEEP_STARTED_AT_KEY);
    
    // Catat waktu mulai tidur di "kantong ajaib"
    dynamic_field::add(&mut pet.id, key, clock.timestamp_ms());
    
    pet.image_url = string::utf8(PET_SLEEP_IMAGE_URL);
}

// Pet bangun tidur
public entry fun wake_up_pet(pet: &mut Pet, clock: &Clock) {
    let key = string::utf8(SLEEP_STARTED_AT_KEY);
    
    // Ambil waktu mulai tidur dari "kantong ajaib"
    let sleep_started_at: u64 = dynamic_field::remove(&mut pet.id, key);
    let duration_ms = clock.timestamp_ms() - sleep_started_at;
    
    // Hitung recovery berdasarkan durasi tidur
    // Recovery energy = durasi_tidur / 1000ms (1 energy per detik)
    let energy_gained = duration_ms / 1000;
    // ... update stats pet
}
```

**Analogi**: Seperti menaruh alarm di kantong ajaib saat pet tidur, lalu mengecek berapa lama pet tidur saat bangun.

### 3. Cek Status Pet

```move
// Cek apakah pet sedang tidur
public fun is_sleeping(pet: &Pet): bool {
    let key = string::utf8(SLEEP_STARTED_AT_KEY);
    dynamic_field::exists_<String>(&pet.id, key)
}

// Cek apakah pet punya aksesori
fun has_accessory(pet: &Pet): bool {
    let key = string::utf8(EQUIPPED_ITEM_KEY);
    dynamic_field::exists_<String>(&pet.id, key)
}
```

**Analogi**: Seperti mengintip kantong ajaib untuk cek apakah ada alarm (pet tidur) atau kacamata (pet punya aksesori).

---

## 🎮 Gameplay Dynamic Fields di Tamagosui

### Skenario 1: Pet Normal vs Pet dengan Aksesori

```
🐱 Pet "Mochi" Level 1 Tanpa Aksesori:
├── 📊 Stats: Energy 60, Happiness 50, Hunger 40
├── 🎮 Game Data: Coins 20, Level 1, Exp 0
├── 🖼️  Image: pet_level_1.jpg
└── ✨ Dynamic Fields: (kosong)

🐱 Pet "Mochi" Level 1 Dengan Kacamata:
├── 📊 Stats: Energy 60, Happiness 50, Hunger 40  
├── 🎮 Game Data: Coins 20, Level 1, Exp 0
├── 🖼️  Image: pet_level_1_with_glasses.jpg
└── ✨ Dynamic Fields: 
    └── equipped_item: PetAccessory("cool glasses")
```

### Skenario 2: Pet Tidur vs Pet Bangun

```
🐱 Pet "Mochi" Sedang Tidur:
├── 📊 Stats: Energy 20, Happiness 80, Hunger 60
├── 🖼️  Image: pet_sleep.jpg
└── ✨ Dynamic Fields:
    └── sleep_started_at: 1693834567890 (timestamp)

🐱 Pet "Mochi" Setelah Bangun (tidur 10 detik):
├── 📊 Stats: Energy 30 (+10), Happiness 80, Hunger 60
├── 🖼️  Image: pet_level_1.jpg  
└── ✨ Dynamic Fields: (sleep_started_at dihapus)
```

---

## 💡 Mengapa Dynamic Fields Keren?

### 1. **Tidak Butuh Prediksi Masa Depan**

**Tanpa Dynamic Fields:**
```move
// Harus prediksi semua fitur dari awal 😰
public struct Pet has key, store {
    id: UID,
    name: String,
    // ... basic fields
    equipped_hat: Option<Hat>,          // Bagaimana kalau butuh sepatu?
    equipped_glasses: Option<Glasses>,  // Bagaimana kalau butuh tas?
    sleep_data: Option<SleepData>,      // Bagaimana kalau butuh exercise data?
    achievement_data: Option<Achievements>, // Dan seterusnya...
}
```

**Dengan Dynamic Fields:**
```move
// Struct tetap simple, fitur tambah sesuai kebutuhan 😎
public struct Pet has key, store {
    id: UID,
    name: String,
    image_url: String,
    adopted_at: u64,
    stats: PetStats,
    game_data: PetGameData,
    // Dynamic fields ditambah saat butuh!
}
```

### 2. **Efisiensi Storage**

```
Pet A: Punya kacamata → Dynamic field "equipped_item" ada
Pet B: Tidak punya aksesori → Dynamic field "equipped_item" tidak ada (hemat space!)
Pet C: Sedang tidur → Dynamic field "sleep_started_at" ada  
Pet D: Tidak tidur → Dynamic field "sleep_started_at" tidak ada
```

### 3. **Extensibility Tanpa Breaking Changes**

```move
// Update 1: Tambah sistem achievements
dynamic_field::add(&mut pet.id, b"achievements", achievement_data);

// Update 2: Tambah sistem friendship  
dynamic_field::add(&mut pet.id, b"friends", friends_list);

// Update 3: Tambah sistem breeding
dynamic_field::add(&mut pet.id, b"breeding_cooldown", timestamp);

// Semua pet lama tetap compatible! 🎉
```

---

## 📦 Wrapped vs Unwrapped Objects (Singkat)

### Konsep Dasar

**Unwrapped Object**: Pet bebas, bisa langsung digunakan (feed, play, transfer)
**Wrapped Object**: Pet "dikemas" dalam container lain (marketplace, escrow, rental)

```move
// Unwrapped - pet bebas
public entry fun feed_pet(pet: &mut Pet) { ... } // ✅ Langsung bisa

// Wrapped - pet dalam listing marketplace  
public struct PetListing has key {
    id: UID,
    pet: Pet,        // Pet terkunci dalam listing
    price: u64,
}
// Pet tidak bisa di-feed sampai di-unwrap dari listing ❌
```

**Use Case**: Marketplace, escrow, rental system, breeding pairs

---

## 🗑️ Object Deletion 

### Konsep: Objects Bisa Dihancurkan Permanen

```move
// WARNING: Pet akan hilang selamanya!
public entry fun release_pet_to_wild(pet: Pet) {
    let Pet { id, name: _, image_url: _, adopted_at: _, stats: _, game_data: _ } = pet;
    object::delete(id); // 💥 POOF! Pet hilang selamanya
}
```

### Demo Steps
```bash
# 1. Adopsi pet untuk demo
sui client call --function adopt_pet --args "TempPet" [CLOCK_ID]

# 2. Verify pet exists
sui client object [PET_ID]  # ✅ Pet ada

# 3. Delete pet permanently  
sui client call --function release_pet_to_wild --args [PET_ID]

# 4. Verify pet is gone
sui client object [PET_ID]  # ❌ "Object not found" - benar-benar hilang!
```

---

## 🎯 Kesimpulan

### Object = Rumah Digital
- Setiap pet adalah "rumah digital" dengan alamat unik
- Hanya owner yang bisa masuk dan mengubah
- Bisa dipindahkan ownership

### Dynamic Fields = Kantong Ajaib Tak Terbatas  
- Tambah fitur tanpa ubah struct asli
- Hemat storage (hanya ada jika dibutuhkan)
- Extensible tanpa breaking changes

### Tamagosui Implementation
- **Aksesori**: Dynamic field untuk equipped items
- **Sleep**: Dynamic field untuk sleep tracking  
- **Future**: Bisa tambah achievements, friends, breeding, dll

### Next Steps
- Pelajari lebih lanjut: [Upgrade Capabilities](./day3-upgrade-capabilities.md) 
- Explore advanced: [PTB - Programmable Transaction Blocks](./day3-ptb-programmable-transaction-blocks.md)
- Advanced gaming mechanics

---

**Remember**: Object bukan cuma "data", tapi "benda digital" yang bisa dimiliki, dipindah, dan dimodifikasi secara independent! 🎮✨
