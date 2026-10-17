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
   Pakai iTerm2? Pilih profile **dotfiles (Catppuccin Mocha)** lalu *Set as Default*. Terminal VS Code: salin [`vscode/settings.json`](../vscode/settings.json) ke settings-mu.
2. Kasih izin *Accessibility* ke Ghostty (System Settings → Privacy & Security), supaya `` cmd+` `` (quick terminal) bisa dipakai dari mana saja.
3. Edit host di `~/.ssh/config.d/containers` (port container) dan `~/.ssh/config.d/robots` (IP robot).
4. Daftarkan web app-mu di `~/.config/apps` (lihat Hari 8).
5. Ketik `nvim` sekali, lalu tunggu Mason selesai install LSP (cek progresnya dengan `:Mason`).
6. Cek hasil instalasi dengan `~/dotfiles/tests/smoke.sh`. Semua baris harus ✓.

Langkah lengkapnya ada di [INSTALL-MACOS.md](INSTALL-MACOS.md).

---

## Hari 1 — Shell (zsh)

Prompt-nya polos tanpa ikon: nama folder terakhir dan branch git, misalnya `molly main*` lalu `>` di baris bawah. Nama host ada di judul tab dan nama window tmux (`macbook:~/apps/molly`, `humble:~/ros2_ws`), jadi tetap kelihatan kamu lagi di Mac, di container, atau di robot.

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

| Kiri | Kanan |
|---|---|
| nama session, lalu window (`1 molly`, `2 humble`) | `tunnel` (kalau cloudflared jalan), `CPU`, `GPU`, `RAM`, suhu CPU, `D`/`U` (kecepatan download/upload), jumlah container, `BAT`, jam. Semua teks biasa, tanpa ikon |

Window otomatis dinamai sesuai folder, atau sesuai host kalau pane-nya sedang SSH.

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

`C-a f` membuka **sessionizer**: pilih folder project (dari `~/apps`, `~/web`, `~/Projects`, dll.), otomatis jadi session baru dengan nama folder itu. Pindah antar session pakai `C-a s`.


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
| `Space xx` | semua error project di picker diagnostics |
| `Space ch` | pindah header ↔ source (C++) |
| `Space uh` | tampilkan inlay hints (tipe parameter) |

Completion: `Tab`/`S-Tab` untuk pilih, `Enter` untuk accept, `C-Space` untuk paksa muncul.

**Kalau LSP tidak jalan**: buka `Space cl` (health check LSP), lalu cek `:Mason` apakah servernya sudah terinstall.

---

## Hari 5 — Workflow ROS 🤖

ROS cuma ada di container dan robot, tidak di Mac. Masuk dulu dengan `dev humble` (ROS 2) atau `dev noetic` (ROS 1), lihat Hari 6.

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
   Menu `Space r` cuma muncul di container/robot yang punya ROS; di Mac tidak ada.
3. Setelah build, `compile_commands.json` di-merge dan clangd di-restart. Autocomplete untuk `rclcpp::` dan msg custom langsung jalan.
4. `Space rt`: pilih topic, lalu pilih aksi (echo / hz / info). Output-nya di terminal bawah.
5. `Space rl`: pilih launch file di package, lalu `ros2 launch` (ROS 1: `roslaunch`).
6. `Space rr`: pilih executable, lalu `ros2 run` (ROS 1: `rosrun`).
7. File `.msg`/`.srv`/`.action` sudah dapat syntax highlight. URDF/xacro/launch.xml dapat LSP XML.

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

## Hari 8 — Web app: app, Cloudflare Tunnel, PM2

### Jalankan app

Daftar app ada di `~/.config/apps`, satu baris per app: nama, folder, dan (opsional) command:

```text
molly         ~/apps/molly-dashboard
netra         ~/apps/netra                scripts/local.sh up
```

| Command / keys | Fungsi |
|---|---|
| `app` atau `C-a a` | pilih app, lalu app itu jalan di window tmux baru |
| `app molly` | sama, tanpa picker |
| `app ls` | daftar app dan cara start-nya (pm2 / compose / node) |
| `app logs molly` · `app down molly` | log · stop (PM2 dan docker compose) |

Tanpa command, folder yang menentukan: ada `ecosystem.config.js` → PM2, ada `compose.yaml` → docker compose, ada `package.json` → `pnpm dev` / `npm run dev`.

### Cloudflare Tunnel

| Command | Fungsi |
|---|---|
| `tun` | status tunnel dan daftar hostname → port |
| `tun add gcs.domainmu.com 5173` | tambah hostname, bikin DNS, restart cloudflared |
| `tun rm gcs.domainmu.com` | hapus hostname |
| `tun share 3000` | URL publik sementara (`*.trycloudflare.com`) buat demo |
| `tun log` | log cloudflared |

Setup tunnel pertama kali dan detail lainnya: [WEB.md](WEB.md).

### Di editor

**Next.js / React**: LSP (vtsls), Tailwind class completion, ESLint. Format pakai biome kalau ada `biome.json`, kalau tidak pakai prettier. `Space cR` rename file dan update import-nya otomatis.

---

## Hari 9 — Git

| Keys | Fungsi |
|---|---|
| `Space gg` / `C-a g` | lazygit. `space` stage, `c` commit, `P` push, `?` bantuan |
| `]h` / `[h` | lompat antar perubahan |
| `Space ghp` | preview perubahan inline |
| `Space ghs` / `Space ghr` | stage / reset hunk |
| `Space ub` | blame inline |
| `Space go` | buka baris ini di GitHub |

Di shell: `gs`, `gd`, `glog`, `gcm "feat: ..."`, `git lg`.

---

## Selanjutnya

- Semua shortcut: [KEYMAPS.md](KEYMAPS.md) · semua command shell: [COMMANDS.md](COMMANDS.md)
- Ubah config tanpa merusak repo: [CUSTOMIZE.md](CUSTOMIZE.md)
- Ada yang error: [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

Setelah edit config: `zr` reload zsh, `C-a r` reload tmux, `cmd+shift+,` reload Ghostty. Untuk Neovim, cukup buka ulang.
