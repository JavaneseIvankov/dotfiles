# Semantic Keymaps Specification (SSOT)

> **Directive for AI / LLM Generator:**
> Dokumen ini adalah *Single Source of Truth* (SSOT) untuk konfigurasi keyboard shortcut dan workflow desktop saya.
> Ketika saya meminta kamu untuk menghasilkan (*generate*) konfigurasi untuk Window Manager atau Desktop Environment tertentu (seperti Niri, Hyprland, Sway, i3, River, KDE, GNOME, dll.):
> 1. Terjemahkan setiap **Semantic Intent** di bawah ini ke dalam sintaks dan modul native target secara idiomatik.
> 2. Gantikan setiap **Role Token** (`$TERMINAL`, `$APP_LAUNCHER`, dll.) dengan executable atau tool yang sesuai profil target.
> 3. Jika target tidak memiliki padanan fitur 1:1 (misalnya *scrollable column* Niri vs *dwindle tiling* Hyprland), gunakan panduan di [Section 6: Paradigm Translation Matrix](#6-paradigm-translation-matrix-for-ai) untuk mengadaptasinya secara logis.

---

## 0. Hardware & Low-Level Input Remap (xremap / keyd)

Bagian ini mendefinisikan transformasi tombol fisik laptop di level kernel/evdev (`xremap` atau `keyd`) sebelum sinyal diterima oleh Window Manager dan aplikasi:

| Tombol Fisik Laptop | Dipetakan Menjadi | Peran / Fungsi Semantik | Alasan Ergonomi & Desain |
| :--- | :--- | :--- | :--- |
| **`Left Alt`** | `Shift` (Overload: Space/Enter) | **Thumb Shift** | Mengetik huruf kapital & simbol tanpa ketegangan kelingking |
| **`Right Alt`** | `Super` (Mod4) | **WM Modifier (`$MOD`)** | Jempol kanan memegang kendali penuh Window Manager (0% ubah muscle memory) |
| **`Super / Win`** | `Alt` (Mod1) | **In-App Alt** | Disediakan khusus saat aplikasi/terminal membutuhkan tombol `Alt` |
| **`Caps Lock`** | `Escape` (tap) / Nav Modifier (held) | **Dual-Role Esc & Nav** | Tap untuk Escape instan (Vim); tahan untuk navigasi panah tanpa ghosting |
| **`Right Alt + C`** | `Escape` | **Right-hand Escape** | Kombo escape satu tangan kanan |

### 0.1. Caps-Nav Layer (Tahan `Caps Lock`)
Navigasi kursor panah dialokasikan khusus pada `Caps Lock` (held) untuk menghindari limitasi *hardware matrix jamming* laptop (di mana kombinasi 3 tombol fisik `Left Alt + Right Alt + H` diblokir oleh keyboard controller/BIOS):

| Tombol saat `Caps Lock` Ditahan | Aksi / Sinyal Output | Posisi Jari | Deskripsi |
| :--- | :--- | :--- | :--- |
| **`h`** | `Left Arrow` ($\leftarrow$) | Tangan Kanan (Home Row) | Navigasi kursor kiri di semua aplikasi |
| **`j`** | `Down Arrow` ($\downarrow$) | Tangan Kanan (Home Row) | Navigasi kursor bawah di semua aplikasi |
| **`k`** | `Up Arrow` ($\uparrow$) | Tangan Kanan (Home Row) | Navigasi kursor atas di semua aplikasi |
| **`l`** | `Right Arrow` ($\rightarrow$) | Tangan Kanan (Home Row) | Navigasi kursor kanan di semua aplikasi |

*Catatan:* Mengetuk (*tap*) `Caps Lock` sendirian tetap mengirim sinyal `Escape` murni tanpa delay.

### 0.2. Dual-Thumb Fast Editing Layer (Tahan `Left Alt` + `Right Alt`)
Ketika kedua tombol jempol ditahan bersamaan (`Super-Shift_R-` di evdev), keyboard mengaktifkan layer reflek edit teks berfrekuensi tinggi tanpa perlu merentangkan jari kelingking ke pojok keyboard:

| Tombol saat Kedua Jempol Ditahan | Aksi / Sinyal Output | Posisi Jari | Deskripsi |
| :--- | :--- | :--- | :--- |
| **`p`** | `Backspace` | Tangan Kanan (Top Row) | Hapus 1 karakter kiri tanpa menjangkau pojok atas |
| **`o`** | `Ctrl + Backspace` | Tangan Kanan (Top Row) | Hapus 1 kata ke belakang (*word delete*) tepat di sebelah `p` |
| **`u`** | `Ctrl + z` | Tangan Kanan (Top Row) | Undo perubahan teks instan |

*Keunggulan Arsitektur:* 
- Layer ini tidak mengganggu kombinasi Niri (`Super + Shift + ...`) karena Niri mendengarkan `Shift_L` (kelingking), sedangkan jempol kiri memancarkan `Shift_R`.
- Didesain minimalis dan zero-delay sesuai kebutuhan ergonomi pengetikan tanpa tombol berlebih seperti Delete/Home/End.

---

## 1. Filosofi & Konteks Ergonomi

* **Modifier Utama Window Manager (`$MOD`):** Default adalah **`Super`** (Mod4).
  * **Pemisahan Peran Dua Jempol:**
    * **Jempol Kiri:** Khusus untuk **Mengetik Teks** (`Left Alt` $\rightarrow$ **Shift** / Space). Tidak pernah mengontrol WM.
    * **Jempol Kanan:** Khusus untuk **Window Management** (`Right Alt` $\rightarrow$ **Super** / `$MOD`).
    * **Hasil:** Muscle memory jempol kanan tetap identik seperti saat memakai Niri/WM sebelumnya, tetapi sinyal yang dikirim ke sistem adalah **`Super`**.
* **Kebebasan Tombol `Alt` (In-App Namespace):**
  * Karena seluruh aksi WM ditangani oleh sinyal `Super`, namespace `Alt` **bersih 100% untuk aplikasi**:
    * Navigasi shell ZSH/Bash (`Alt+f`, `Alt+b`, `Alt+d`, `Alt+.`).
    * Manipulasi baris kode di Neovim (`<M-j>`, `<M-k>`).
    * Navigasi pane Tmux dan history browser (`Alt+Left/Right`).
    * Akses ke `Alt` di laptop dilakukan melalui tombol fisik `Super/Win` (kiri bawah).
* **Filosofi Navigasi:** 
  * Menjaga tangan tetap di *home row* (Vim navigation `h / j / k / l`).
  * **Konsistensi Vim `L`:** Tombol `$MOD + l` **mutlak dialokasikan untuk Focus Right**. Fungsi Lock Screen dialihkan sepenuhnya ke dalam Leader Menu (`$LEADER -> p -> l`).
  * *Mouseless principle*: Minimalkan penggunaan mouse/touchpad; sediakan keyboard navigation (`$MOUSELESS_POINTER`) jika interaksi kursor dibutuhkan.
* **Pendekatan Layout:**
  * Di Niri: Berbasis *Infinite Horizontal Ribbon* (kolom horizontal dinamis).
  * Di Tiling WM konvensional: Terjemahkan kolom ke window/container focus terdekat atau *tabbed/stacked grouping*.

---

## 2. Capability Providers & Semantic Roles

Daftar peran abstrak sistem dan implementasi default pada sistem saat ini (Arch Linux / Wayland):

| Role Token | Kebutuhan / Peran | Implementasi Default | Catatan & Alternatif Umum |
| :--- | :--- | :--- | :--- |
| `$TERMINAL` | Terminal emulator utama | `kitty` | `foot`, `alacritty`, `ghostty` |
| `$APP_LAUNCHER` | Application launcher / dmenu | `fuzzel` | `walker`, `rofi`, `wofi` |
| `$CHORD_HELPER` | Multi-step chord / Leader menu | `wlr-which-key` | Native WM submap / mode |
| `$WINDOW_SWITCHER` | Pencari & switcher window aktif | `fuzzel-utils switch` | Rofi window, WM native focus |
| `$WINDOW_RENAMER` | Mengubah alias nama window | `fuzzel-utils rename-window` | Custom script |
| `$WORKSPACE_RENAMER`| Mengubah nama/label workspace | `fuzzel-utils rename-workspace-current` | Custom script |
| `$FILE_MANAGER` | File manager grafis | `thunar` | `nautilus`, `dolphin`, `yazi` |
| `$FILE_PICKER` | Pencari file cepat berbasis fuzzy | `fuzzel-utils file-explorer` | Fzf picker, Walker |
| `$BROWSER` | Web browser utama | `vivaldi-stable --remote-debugging-port=9222` | Chromium / Firefox |
| `$MOUSELESS_POINTER`| Kontrol mouse via keyboard | `wl-kbptr -o modes=floating,click -o mode_floating.source=detect` | - |
| `$BAR_TOGGLER` | Toggle status bar | `pkill -x waybar \|\| waybar --config ~/.config/waybar/config.niri.jsonc &` | - |
| `$SCREEN_LOCKER` | Pengunci layar | `swaylock` | `hyprlock` |
| `$NOTIFICATION_CENTER`| Panel notifikasi sistem | `swaync-client -t` | Dunst, Mako |
| `$TASK_TRACKER` | Manajemen tugas & waktu | `flatpak run com.super_productivity.SuperProductivity` | SuperProductivity |
| `$AI_PROMPT` | Asisten AI instan | Browser membuka ChatGPT temporary chat | Web/CLI AI tool |

---

## 3. Core Keymaps (Direct Bindings)

### 3.1. Application Launchers & Core Utilities
Hanya aksi peluncur berfrekuensi tinggi (reflex) yang dipertahankan di level flat:

| Shortcut | Semantic Intent | Target Role / Command | Deskripsi |
| :--- | :--- | :--- | :--- |
| `$MOD + Return` | `launch` | `$TERMINAL` | Buka terminal utama |
| `$MOD + d` | `launch` | `$APP_LAUNCHER` | Buka launcher aplikasi |
| `$MOD + w` | `launch` | `$WINDOW_SWITCHER` | Buka switcher window aktif |
| `$MOD + e` | `helper` | `$CHORD_HELPER` | Buka leader key menu (`$LEADER`, lihat Section 5) |
| `$MOD + Space` | `launch` | `$MOUSELESS_POINTER` | Aktifkan keyboard pointer navigation |
| `$MOD + Shift + /` | `help` | `show_hotkey_overlay` | Tampilkan overlay daftar shortcut |

> *Catatan:* Utilitas file manager, file picker, renamer, dan toggle bar telah di-collapse ke dalam **Leader Menu (`$LEADER`)** di Section 5 untuk menghemat namespace tombol.

### 3.2. Window Navigation (Focus)
| Shortcut | Semantic Intent | Target / Arah | Deskripsi |
| :--- | :--- | :--- | :--- |
| `$MOD + h` / `$MOD + Left` | `focus:direction` | `left` | Pindah fokus ke kolom/window kiri |
| `$MOD + l` / `$MOD + Right`| `focus:direction` | `right` | Pindah fokus ke kolom/window kanan |
| `$MOD + j` / `$MOD + Down` | `focus:direction` | `down` | Pindah fokus ke window/workspace bawah |
| `$MOD + k` / `$MOD + Up` | `focus:direction` | `up` | Pindah fokus ke window/workspace atas |
| `$MOD + Home` | `focus:boundary` | `first` | Lompat ke kolom paling awal |
| `$MOD + End` | `focus:boundary` | `last` | Lompat ke kolom paling akhir |

### 3.3. Window & Column Movement
| Shortcut | Semantic Intent | Target / Arah | Deskripsi |
| :--- | :--- | :--- | :--- |
| `$MOD + Shift + h` / `Left` | `move:direction` | `left` | Pindahkan kolom/window ke kiri |
| `$MOD + Shift + l` / `Right`| `move:direction` | `right` | Pindahkan kolom/window ke kanan |
| `$MOD + Shift + j` / `Down` | `move:direction` | `down` | Pindahkan window ke bawah |
| `$MOD + Shift + k` / `Up` | `move:direction` | `up` | Pindahkan window ke atas |
| `$MOD + Ctrl + Home` | `move:boundary` | `first` | Pindahkan kolom ke posisi paling awal |
| `$MOD + Ctrl + End` | `move:boundary` | `last` | Pindahkan kolom ke posisi paling akhir |

### 3.4. Window State & Canvas Display
| Shortcut | Semantic Intent | Aksi / State | Deskripsi |
| :--- | :--- | :--- | :--- |
| `$MOD + q` | `window:action` | `close` | Tutup window aktif secara aman |
| `$MOD + f` | `window:action` | `maximize_column` | Maksimalkan lebar kolom aktif |
| `$MOD + Shift + f` | `window:action` | `fullscreen` | Toggle fullscreen sejati |
| `$MOD + Ctrl + v` | `window:action` | `toggle_float` | Toggle mode floating pada window aktif |
| `$MOD + Shift + v` | `window:action` | `switch_focus_floating_tiling` | Tukar fokus antara layer floating & tiling |
| `$MOD + Shift + o` | `canvas:action` | `toggle_overview` | Buka / tutup tampilan overview kanvas |

### 3.5. Layout & Sizing Adjustments
| Shortcut | Semantic Intent | Parameter | Deskripsi |
| :--- | :--- | :--- | :--- |
| `$MOD + r` | `size:preset` | `switch_width_preset`| Rotasi preset lebar kolom (1/3, 1/2, 2/3) |
| `$MOD + Ctrl + r` | `size:reset` | `reset_window_height`| Reset tinggi window ke default |
| `$MOD + [` | `column:group` | `consume_or_expel_left`| Masukkan / keluarkan window dari kolom kiri |
| `$MOD + ]` | `column:group` | `consume_or_expel_right`| Masukkan / keluarkan window dari kolom kanan |
| `$MOD + ,` | `column:group` | `consume_into_column`| Tarik window kanan ke bawah kolom aktif |
| `$MOD + .` | `column:group` | `expel_from_column`| Lepas window paling bawah ke kolom baru |
| `$MOD + -` / `$MOD + =` | `size:adjust_width` | `-10%` / `+10%` | Kecilkan / lebarkan kolom sebesar 10% |
| `$MOD + Shift + -` / `=` | `size:adjust_height`| `-10%` / `+10%` | Pendekkan / tinggikan window sebesar 10% |

### 3.6. Workspace Navigation & Organization
| Shortcut | Semantic Intent | Target | Deskripsi |
| :--- | :--- | :--- | :--- |
| `$MOD + 1..9` | `workspace:goto` | `index 1..9` | Pindah fokus ke workspace nomor 1..9 |
| `$MOD + Shift + 1..9`| `workspace:send` | `index 1..9` | Pindahkan kolom/window ke workspace 1..9 |
| `$MOD + Page_Down` / `u` | `workspace:cycle` | `down / next` | Pindah fokus ke workspace bawah/berikutnya |
| `$MOD + Page_Up` / `i` | `workspace:cycle` | `up / prev` | Pindah fokus ke workspace atas/sebelumnya |
| `$MOD + Shift + Page_Down` / `Shift + u` | `workspace:move_item` | `down / next` | Pindahkan kolom ke workspace bawah |
| `$MOD + Shift + Page_Up` / `Shift + i` | `workspace:move_item` | `up / prev` | Pindahkan kolom ke workspace atas |
| `$MOD + Ctrl + Page_Down` / `Ctrl + u` | `workspace:reorder` | `down` | Geser urutan workspace ke arah bawah |
| `$MOD + Ctrl + Page_Up` / `Ctrl + i` | `workspace:reorder` | `up` | Geser urutan workspace ke arah atas |

### 3.7. Quick Recent Windows Switcher
Popup switcher berbasis riwayat fokus baru-baru ini:
| Shortcut | Semantic Intent | Deskripsi |
| :--- | :--- | :--- |
| `$MOD + Tab` / `$MOD + n` | `recent_windows:next` | Pilih window berikutnya di daftar recent |
| `$MOD + Shift + Tab` / `$MOD + p` / `$MOD + c` | `recent_windows:prev` | Pilih window sebelumnya di daftar recent |

### 3.8. System, Session, & Hardware Fallbacks
Hanya aksi level sistem fundamental yang dipertahankan di level flat:

| Shortcut | Semantic Intent | Target / Payload | Deskripsi |
| :--- | :--- | :--- | :--- |
| `Print` | `screenshot:screen_file` | `file` | Tombol hardware fallback: tangkap layar penuh ke file |
| `$MOD + Alt + s` | `accessibility` | `toggle_screen_reader` | Toggle Orca screen reader |
| `$MOD + Escape` | `system:input` | `toggle_key_inhibit` | Toggle keyboard shortcuts inhibitor |
| `Ctrl + $MOD + Delete`| `session:quit` | `confirm_exit` | Tampilkan konfirmasi keluar sesi |

> **Catatan Mnemonic Chord:**
> - Aksi **Screenshot** (Area, Full, Window) dipindahkan ke `$LEADER ➜ [s]`.
> - Aksi **Lock Screen** dan **Suspend** dipindahkan ke `$LEADER ➜ [p]` (agar `$MOD + l` mutlak untuk Vim Focus Right).
> - Aksi **Power off monitors** dipindahkan ke `$LEADER ➜ [p] ➜ [m]`.

---

## 4. Mouse & Touchpad Bindings

| Event / Gesture | Semantic Intent | Deskripsi |
| :--- | :--- | :--- |
| `MiddleClick` | `canvas:action:toggle_overview` | Klik tengah mouse membuka overview |
| `$MOD + WheelDown` / `WheelUp` | `workspace:cycle:down` / `up` | Ganti workspace lewat scroll |
| `$MOD + Ctrl + WheelDown` / `WheelUp` | `workspace:move_item:down` / `up`| Pindahkan kolom ke workspace via scroll |
| `$MOD + WheelRight` / `WheelLeft` | `focus:direction:right` / `left` | Pindah kolom horizontal via scroll |
| `$MOD + Ctrl + WheelRight` / `WheelLeft`| `move:direction:right` / `left` | Pindahkan kolom horizontal via scroll |

---

## 5. Hierarchical Chord / Leader Key Tree

> **Trigger:** `$MOD + e` (`$LEADER`)
> **Instruksi untuk AI:**
> - Jika target mendukung GUI helper (seperti `wlr-which-key`), hasilkan format menu/submenu YAML yang sesuai.
> - Jika target adalah WM native tanpa helper (Hyprland / Sway / i3), terjemahkan hirarki ini menjadi rantai `submap` / `mode` native.
> - Pastikan tombol `Escape` di setiap level mengembalikan state ke default.

```
$LEADER ($MOD + e)
├── [e] ➜ Launch (Aplikasi Khusus)
│   ├── [b] ➜ Web Browser: launch($BROWSER)
│   ├── [a] ➜ Ask AI: launch($AI_PROMPT)
│   └── [p] ➜ Productivity: launch_or_focus($TASK_TRACKER)
│
├── [s] ➜ Screenshot
│   ├── [a] ➜ Area: screenshot:area (seleksi interaktif ke clipboard)
│   ├── [s] ➜ Screen: screenshot:screen (seluruh layar ke clipboard)
│   └── [w] ➜ Window: screenshot:window (jendela aktif ke clipboard)
│
├── [f] ➜ Files & Search
│   ├── [m] ➜ File Manager GUI: launch($FILE_MANAGER)
│   └── [p] ➜ File Picker Fuzzy: launch($FILE_PICKER)
│
├── [r] ➜ Rename
│   ├── [w] ➜ Rename Window: launch($WINDOW_RENAMER)
│   └── [s] ➜ Rename Workspace: launch($WORKSPACE_RENAMER)
│
├── [t] ➜ Toggle UI & Layout
│   ├── [b] ➜ Toggle Status Bar: toggle($BAR_TOGGLER)
│   └── [t] ➜ Toggle Tabbed Column: layout:action(toggle_tabbed_display)
│
├── [n] ➜ Notification Center: toggle($NOTIFICATION_CENTER)
│
├── [p] ➜ Power & Session
│   ├── [l] ➜ Lock: system:lock
│   ├── [s] ➜ Sleep / Suspend: system:suspend
│   ├── [m] ➜ Monitors Off: system:power(power_off_monitors)
│   └── [o] ➜ Danger Layer (Aksi Kritis)
│       ├── [r] ➜ Reboot: system:reboot
│       └── [o] ➜ Power Off: system:poweroff
│
└── [l] ➜ Laptop Display Controls (Internal eDP-1)
    └── [s] ➜ Display Scale
        ├── [1] ➜ Scale 1.0 (100%)
        ├── [2] ➜ Scale 1.1 (110%)
        ├── [3] ➜ Scale 1.2 (120%)
        └── [4] ➜ Scale 1.3 (130%)
```

---

## 6. Paradigm Translation Matrix for AI

Gunakan matriks ini saat menerjemahkan konsep unik antar paradigma window manager:

| Konsep di Dokumen Ini | Niri (Scrollable Ribbon) | Hyprland (Dynamic Tiling) | Sway / i3 (Manual Tiling) | DE Biasa (KDE/GNOME) |
| :--- | :--- | :--- | :--- | :--- |
| `focus:left / right` | `focus-column-left / right` | `movefocus, l / r` | `focus left / right` | Switch active window / cycle |
| `focus:up / down` | `focus-window-or-workspace-up/down` | `movefocus, u / d` | `focus up / down` | Switch active window |
| `column:group:consume` | `consume-or-expel-window` | `togglegroup` / move into group | `layout tabbed` / split | N/A (abaikan atau beri komentar) |
| `window:maximize_column` | `maximize-column` | `fullscreen, 1` (maximize) | `fullscreen toggle` | Maximize window toggle |
| `window:fullscreen` | `fullscreen-window` | `fullscreen, 0` (true full) | `fullscreen toggle` | Fullscreen toggle |
| `workspace:goto` | `focus-workspace <id>` | `workspace, <id>` | `workspace number <id>` | Switch virtual desktop |
| `$CHORD_HELPER` | Exec `wlr-which-key` | Native `submap = leader` atau `wlr-which-key` | Native `mode "leader"` | Rofi/Fuzzel dmenu script |
| `canvas:overview` | `toggle-overview` | Plugin Hyprspace / hycov | Workspace overview | Expose / Overview shortcut |
