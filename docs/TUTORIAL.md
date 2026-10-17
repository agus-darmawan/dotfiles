# Tutorial — dari nol sampai lancar

Tutorial ini urut dari yang paling dasar. Jangan dipelajari sekaligus. Ikuti per hari, kerjakan sambil ngoding beneran, dan dalam 1–2 minggu semuanya bakal jadi muscle memory.

> **Konvensi**
> `C-a` = Ctrl+a (prefix tmux) · `Space` = leader Neovim · `M-` / `A-` = Option
> Lupa keymap? Di Neovim tekan `Space` lalu tunggu, nanti **which-key** muncul. Atau `Space sk` buat cari keymap.

---

## Hari 0 — Install

```bash
git clone https://github.com/agus-darmawan/dotfiles ~/dotfiles
cd ~/dotfiles && ./install.sh
```

1. Buka **Ghostty**. Font dan theme langsung aktif.
2. Kasih izin *Accessibility* ke Ghostty (System Settings → Privacy & Security), supaya `` cmd+` `` (quick terminal) bisa dipakai dari mana saja.
3. Edit IP robot di `~/.ssh/config.d/robots`.
4. Ketik `nvim` sekali, lalu tunggu Mason selesai install LSP (cek progresnya dengan `:Mason`).
5. Cek hasil instalasi dengan `~/dotfiles/tests/smoke.sh`. Semua baris harus ✓.

---

## Hari 1 — Shell (zsh)

| Coba ini | Hasilnya |
|---|---|
| `cd proj` lalu `Tab` | fzf-tab: completion jadi fuzzy, lengkap dengan preview isi folder |
| ketik sebagian command | saran abu-abu muncul; `→` atau `C-Space` untuk menerima |
| `C-r` | cari history dengan fzf |
| `C-t` | cari file lalu tempel path-nya |
| `M-c` | fuzzy cd ke subfolder |
| `cd elips` | zoxide melompat ke folder yang sering dikunjungi (cukup sebagian nama) |
| `cdi` | zoxide interaktif |
| `ll`, `lt` | ls dengan ikon, git status, dan tree |
| `C-x C-e` | edit command panjang di nvim |

**Kebiasaan yang perlu dibangun:** berhenti ketik path panjang. Pakai `cd <sebagian-nama>`.

---

## Hari 2 — tmux (multi terminal)

Mulai dengan `t`, yang membuat atau attach ke session `main`. Status bar ada **di atas**:

```
[ main ] 1 netra  2 humble │ cpu 12%  ram 9.1/24G  docker 2  192.168.1.7  85%  01:10
```

Latihan:

1. `C-a |` split kanan, `C-a -` split bawah
2. `C-h/j/k/l` pindah pane (nanti juga dipakai untuk pindah split Neovim)
3. `C-a m` zoom pane, tekan lagi untuk balik
4. `C-a c` window baru, `C-a 1..9` pindah window, `C-a Tab` window terakhir
5. `C-a g` lazygit, `C-a b` btop, `C-a D` lazydocker. Semuanya popup, tutup dengan `q`
6. `C-a t` **scratch terminal** mengambang. Isinya tidak hilang walau ditutup
7. `C-a v` masuk copy mode, `v` mulai seleksi, `y` copy ke clipboard Mac
8. Tutup Ghostty, buka lagi, ketik `t`. Session tmux masih jalan selama Mac tidak di-restart.

### Satu session per project

`C-a f` membuka **sessionizer**: pilih folder project, otomatis jadi session baru dengan nama folder itu. Pindah antar project pakai `C-a s`.


---

## Hari 3 — Neovim: navigasi dan edit

Belum lancar motion Vim? Jalankan `:Tutor` dulu (30 menit), lalu lanjut ke sini.

### Buka dan cari file
| Keys | Pakai buat |
|---|---|
| `Space Space` | cari file (urutannya pintar: recent dan frecency) |
| `Space /` | grep seluruh project |
| `Space ,` | daftar buffer yang terbuka |
| `Space e` | explorer di kanan (`a` buat file, `d` hapus, `r` rename) |
| `-` | **oil**: folder dibuka sebagai teks. Rename = edit nama lalu `:w`. Hapus = `dd` lalu `:w` |
| `S-h` / `S-l` | pindah buffer |
| `Space sr` | buka lagi picker terakhir |

### Gerak cepat
| Keys | Pakai buat |
|---|---|
| `s` + 2 huruf | **flash**: lompat ke mana saja di layar |
| `S` | pilih node treesitter (fungsi, blok, dll) |
| `]]` / `[[` | ke pemakaian berikutnya dari kata di kursor |
| `C-d` / `C-u` | scroll setengah layar, kursor tetap di tengah |

### Edit
| Keys | Pakai buat |
|---|---|
| `gsaiw"` | bungkus kata dengan `"` |
| `gsd"` / `gsr"'` | hapus / ganti pembungkus |
| `gcc` / `gc` (visual) | comment |
| `A-j` / `A-k` | pindah baris ke bawah / atas |
| `ciq` `daa` `vif` | mini.ai: dalam quote, argumen, fungsi |
| `Space sR` | search & replace se-project |

---

## Hari 4 — Neovim: LSP (coding beneran)

Buka file C++ atau Python, lalu:

| Keys | Pakai buat |
|---|---|
| `gd` | ke definisi |
| `gr` | semua referensi |
| `K` | dokumentasi |
| `Space ca` | code action (auto import, quick fix) |
| `Space cr` | rename simbol di seluruh project |
| `Space cf` | format manual (format on save sudah aktif; matikan dengan `Space uf`) |
| `]d` / `[d` | diagnostik berikutnya / sebelumnya |
| `Space xx` | semua error project di panel Trouble |
| `Space ch` | pindah header ↔ source (C++) |
| `Space uh` | tampilkan inlay hints (tipe parameter) |

Completion: `Tab`/`S-Tab` untuk pilih, `Enter` untuk accept, `C-Space` untuk paksa muncul.

**Kalau LSP tidak jalan**: buka `Space cl` (health check LSP), lalu cek `:Mason` apakah servernya sudah terinstall.

---

## Hari 5 — Workflow ROS 2 🤖

### Setup sekali per workspace

```bash
cp ~/dotfiles/templates/ros2/.clangd ~/elips_ws/
cp ~/dotfiles/templates/ros2/.clang-format ~/elips_ws/   # opsional: format C++ otomatis
```

### Di shell (dalam container atau robot)

```bash
cd ~/elips_ws
ros                  # source /opt/ros/<distro> + overlay terdekat (install/ atau devel/)
rosdomain 42         # ROS 2: ROS_DOMAIN_ID, langsung tampil di prompt
rosmaster robot      # ROS 1: ROS_MASTER_URI=http://robot:11311 + ROS_IP

cbp elips_patrol     # build package + dependensinya (+ compile_commands untuk clangd)
cb                   # build semua
ct elips_patrol      # test + hasilnya
rcl                  # hapus build/ install/ devel/ log/

rtopic               # fzf topic → echo (ada preview info)
rnode                # fzf node → info
```

Semua perintah di atas otomatis pakai **colcon** di ROS 2 dan **catkin** (`catkin build` kalau ada catkin_tools, kalau tidak `catkin_make`) di ROS 1.

### Di Neovim

1. Buka file di package, lalu `Space rb` untuk build package itu di background. Hasilnya muncul sebagai notifikasi.
2. Kalau error, quickfix terbuka otomatis. `]q`/`[q` lompat antar error, `Space rL` untuk log lengkap.
3. Setelah build, `compile_commands.json` di-merge dan clangd di-restart. Autocomplete untuk `rclcpp::` dan msg custom langsung jalan.
4. `Space rt`: pilih topic, lalu pilih aksi (echo / hz / bw / info). Output-nya di terminal bawah.
5. `Space rl`: pilih launch file di package, lalu `ros2 launch`.
6. `Space rr`: pilih executable, lalu `ros2 run`.
7. Kursor di `sensor_msgs::msg::LaserScan`, tekan `Space ri` untuk lihat definisinya.
8. File `.msg`/`.srv`/`.action` sudah dapat syntax highlight. URDF/xacro/launch.xml dapat LSP XML.

### Debug node C++

1. Build dengan `Space rb` (default-nya `RelWithDebInfo`, jadi ada debug symbol)
2. `Space db` untuk pasang breakpoint
3. `F5`, pilih **ROS2: launch node from install/**, pilih executable, lalu isi args (misal `--ros-args -p rate:=10`)
4. `F10` step over, `F11` step into, `Space de` evaluasi variabel. Panel UI terbuka otomatis
5. Untuk node yang sudah jalan: `F5`, pilih **Attach to process**

Python node: buka file `.py`, `Space db`, lalu `F5`. debugpy sudah terpasang.

---

## Hari 6 — Session per container / robot

### Dev container (dari Mac)

```bash
dev humble
```

Hasilnya satu session `humble` dengan window `code`, `build`, dan `run`. **Tiap window SSH ke container**, jadi ROS-nya sudah tersource di sana. Detail container ada di [CONTAINER.md](CONTAINER.md).

### Turun ke lapangan (robot via SSH)

```bash
dev go2
```

Sama, tapi ke robot. Karena SSH multiplexing, window kedua dan seterusnya langsung konek tanpa login ulang.

Banyak robot sekaligus:

```bash
sall go2 lite3 genisom     # 1 window, 1 pane per robot, input tersinkron
```

`C-a y` untuk mematikan atau menyalakan sinkronisasi.

---

## Hari 7 — SSH dan Docker harian

| Command / keys | Fungsi |
|---|---|
| `s` atau `C-a S` | pilih host. `enter` = window baru, `ctrl-v` = split, `ctrl-o` = di pane ini |
| `sfwd lite3 8080` | buka dashboard robot di `localhost:8080` |
| `skey go2` | copy SSH key ke robot (sekali saja) |
| `dsh` atau `C-a d` | masuk container (otomatis pilih zsh > bash > sh) |
| `dlog` · `dps` · `dstat` · `lzd` | log · daftar · resource · lazydocker |
| `F12` | **SSH ke robot yang juga pakai tmux**: matikan tmux Mac biar semua tombol diteruskan ke tmux robot. Tekan `F12` lagi untuk balik |

Tmux di robot tetap pakai prefix default `C-b`, sedangkan punyamu `C-a`, jadi tidak bentrok.

---

## Hari 8 — Web dan Flutter

**Next.js / React**: LSP (vtsls), Tailwind class completion, ESLint, emmet. Format pakai biome kalau ada `biome.json`, kalau tidak pakai prettier. `Space cR` rename file dan update import-nya otomatis.

**Flutter**:
| Keys | Fungsi |
|---|---|
| `Space Fd` | pilih device (HP, emulator, macOS) |
| `Space Fr` | `flutter run` |
| `Space Fh` / `Space FR` | hot reload / hot restart |
| `Space Fo` | outline widget tree |
| `Space Fl` | dev log |

Closing tag widget muncul sebagai virtual text (`→ Column`), dan widget guide tampil di samping.

---

## Hari 9 — Git

| Keys | Fungsi |
|---|---|
| `Space gg` / `C-a g` | lazygit. `space` stage, `c` commit, `P` push, `?` bantuan |
| `]h` / `[h` | lompat antar perubahan |
| `Space ghp` | preview perubahan inline |
| `Space ghs` / `Space ghr` | stage / reset hunk |
| `Space ub` | blame inline |
| `Space gd` | diffview (review sebelum commit) |
| `Space gH` | history file ini |
| `Space go` | buka baris ini di GitHub |

Di shell: `gs`, `gd`, `glog`, `gcm "feat: ..."`, `git lg`.

---

## Kustomisasi

| Mau | Edit |
|---|---|
| Tambah bahasa / LSP / formatter | `nvim/.config/nvim/lua/config/languages.lua` |
| Tambah plugin | file baru di `nvim/.config/nvim/lua/plugins/` |
| Keymap Neovim | `lua/config/keymaps.lua` atau di spec plugin terkait |
| Alias / fungsi shell | `zsh/.config/zsh/40-aliases.zsh` (atau `~/.zshrc.local` untuk yang privat) |
| Isi status bar tmux | `tmux/.config/tmux/tmux.conf` (bagian `status-right`) dan `scripts/status.sh` |
| Folder yang dicari sessionizer | `export TMUX_SESSIONIZER_PATHS="$HOME/Projects $HOME/ros"` di `~/.zshrc.local` |
| Email kerja untuk repo kantor | `~/.config/git/config.local` → `[includeIf "gitdir:~/ezra/"] path = ~/.config/git/work` |

Setelah edit: `zr` reload zsh, `C-a r` reload tmux, `cmd+shift+,` reload Ghostty. Untuk Neovim, cukup buka ulang.

## Troubleshooting

| Masalah | Solusi |
|---|---|
| Ikon jadi kotak | Font Ghostty harus `JetBrainsMono Nerd Font` (`brew install --cask font-jetbrains-mono-nerd-font`) |
| Theme Ghostty error | `ghostty +list-themes \| grep -i catppuccin`, lalu samakan namanya di config |
| Backspace / warna aneh saat SSH | sudah ditangani `ssh-terminfo`. Kalau masih, `export TERM=xterm-256color` di host itu |
| clangd tidak kenal header ROS | build dulu (`cbp pkg` / `Space rb`). Pastikan `compile_commands.json` ada di root workspace |
| Treesitter parser gagal install | perlu `tree-sitter` CLI dan compiler C (`xcode-select --install`) |
| Copy dari container tidak masuk clipboard | pastikan lewat tmux ini (OSC52 sudah aktif). Di Ghostty `clipboard-write = allow` |
| Neovim lambat start pertama kali | normal, Mason dan treesitter sedang install. Cek dengan `:Lazy` dan `:Mason` |
