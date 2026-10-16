# Semantic Keymaps Specification (SSOT)

> **Directive for AI / LLM Generator:**
> Dokumen ini adalah *Single Source of Truth* (SSOT) untuk konfigurasi keyboard shortcut dan workflow desktop saya.
> Ketika saya meminta kamu untuk menghasilkan (*generate*) konfigurasi untuk Window Manager atau Desktop Environment tertentu (seperti Niri, Hyprland, Sway, i3, River, KDE, GNOME, dll.):
> 1. Terjemahkan setiap **Semantic Intent** di bawah ini ke dalam sintaks dan modul native target secara idiomatik.
> 2. Gantikan setiap **Role Token** (`$TERMINAL`, `$APP_LAUNCHER`, dll.) dengan executable atau tool yang sesuai profil target.
> 3. Jika target tidak memiliki padanan fitur 1:1 (misalnya *scrollable column* Niri vs *dwindle tiling* Hyprland), gunakan panduan di [Section 6: Paradigm Translation Matrix](#6-paradigm-translation-matrix-for-ai) untuk mengadaptasinya secara logis.

---

## 1. Filosofi & Konteks Ergonomi

* **Modifier Utama (`$MOD`):** Default adalah **`Alt`** (karena saya menggunakan layout ergonomis 36-key / Miryoku dengan thumb modifier). Pada keyboard laptop biasa tanpa split, tombol Alt tetap menjadi modifier utama di jempol. Jika profil target mensyaratkan keyboard standar tanpa remap jempol, AI dapat mengubah `$MOD` menjadi `Super`.
* **Secondary Modifier (`$SUPER`):** Digunakan untuk fungsi global level sistem yang kritis (Lock, Suspend, Screenshot, Screen reader).
* **Filosofi Navigasi:** 
  * Menjaga tangan tetap di *home row* (Vim navigation `h / j / k / l`).
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

### 3.1. Application Launchers & System Utilities
| Shortcut | Semantic Intent | Target Role / Command | Deskripsi |
| :--- | :--- | :--- | :--- |
| `$MOD + Return` | `launch` | `$TERMINAL` | Buka terminal utama |
| `$MOD + d` | `launch` | `$APP_LAUNCHER` | Buka launcher aplikasi |
| `$MOD + e` | `helper` | `$CHORD_HELPER` | Buka leader key menu (lihat Section 5) |
| `$MOD + w` | `launch` | `$WINDOW_SWITCHER` | Buka switcher window aktif |
| `$MOD + \` | `launch` | `$FILE_MANAGER` | Buka file manager GUI |
| `$MOD + Shift + e` | `launch` | `$FILE_PICKER` | Buka file picker cepat |
| `$MOD + Shift + a` | `toggle` | `$BAR_TOGGLER` | Toggle / reload bar sistem |
| `$MOD + Shift + r` | `rename` | `$WINDOW_RENAMER` | Ganti alias window yang sedang aktif |
| `$MOD + Shift + t` | `rename` | `$WORKSPACE_RENAMER`| Ganti nama workspace saat ini |
| `$MOD + o` | `launch` | `$MOUSELESS_POINTER` | Aktifkan keyboard pointer navigation |
| `$MOD + Shift + /` | `help` | `show_hotkey_overlay` | Tampilkan overlay daftar shortcut |

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
| `$MOD + g` | `layout:action` | `toggle_tabbed_display`| Ubah kolom menjadi tampilan tab vertikal |
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

### 3.8. System, Session, & Screen Capture
Semua shortcut di bawah ini menggunakan modifier sistem (`$SUPER`):
| Shortcut | Semantic Intent | Target / Payload | Deskripsi |
| :--- | :--- | :--- | :--- |
| `$SUPER + l` | `session:lock` | `$SCREEN_LOCKER` | Kunci sesi layar |
| `$SUPER + Shift + l` | `session:suspend`| `lock_and_suspend` | Kunci layar lalu suspend sistem |
| `$SUPER + s` | `screenshot:screen` | `clipboard` | Screenshot seluruh layar ke clipboard |
| `$SUPER + Shift + s` | `screenshot:area` | `clipboard` | Screenshot area interaktif ke clipboard |
| `$SUPER + Ctrl + s` | `screenshot:window` | `clipboard` | Screenshot jendela aktif ke clipboard |
| `$SUPER + Alt + s` | `accessibility` | `toggle_screen_reader` | Toggle Orca screen reader |
| `$MOD + Escape` | `system:input` | `toggle_key_inhibit` | Toggle keyboard shortcuts inhibitor |
| `Ctrl + Alt + Delete`| `session:quit` | `confirm_exit` | Tampilkan konfirmasi keluar sesi |
| `$MOD + Shift + p` | `system:power` | `power_off_monitors` | Matikan monitor seketika |

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
├── [n] ➜ Notification Center: toggle($NOTIFICATION_CENTER)
│
├── [p] ➜ Power & Session
│   ├── [s] ➜ Sleep: system:suspend
│   ├── [l] ➜ Lock: system:lock
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
