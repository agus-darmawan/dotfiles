# Web apps: app, Cloudflare Tunnel, PM2

Three helpers for running the web apps you already have on the Mac or a home server, defined in
[`zsh/.config/zsh/50-web.zsh`](../zsh/.config/zsh/50-web.zsh):

| Helper | For |
|---|---|
| `app` | start an app in its own tmux window, from a short list of your projects |
| `tun` | see and change what your Cloudflare Tunnel serves, or share a port for a moment |
| `pml` `pmlog` `pmr` `pms` | PM2 shortcuts |

## The app list

`install.sh` creates `~/.config/apps` from [`templates/apps.example`](../templates/apps.example).
One line per app: a name, its folder, and optionally the command that starts it.

```text
# name        folder                      [command]
molly         ~/apps/molly-dashboard
gcs           ~/apps/nextgen-gcs
netra         ~/apps/netra                scripts/local.sh up
database      ~/apps/database
```

Without a command, the folder decides how the app starts:

| The folder has | `app` runs | Kind |
|---|---|---|
| `ecosystem.config.js` / `.cjs` / `.json` | `pm2 start <file>`, then follows `pm2 logs` | `pm2` |
| `compose.yaml` / `docker-compose.yml` | `docker compose up -d`, then follows the logs | `compose` |
| `package.json` | `pnpm dev`, `bun run dev`, `yarn dev` or `npm run dev`, picked from the lockfile | `node` |
| none of these | only opens a shell in the folder | `shell` |

Another file location: `export APPS_FILE=~/somewhere/apps` in `~/.zshrc.local`.

## app

| Command | Action |
|---|---|
| `app` or `C-a a` | pick an app → new tmux window named after it, in its folder, started |
| `app <name>` | the same without the picker |
| `app ls` | every app with its kind and folder (`missing` when the folder is gone) |
| `app up <name>` | start in the background (PM2 and compose); foreground kinds run in this shell |
| `app down <name>` | `pm2 stop` or `docker compose down` |
| `app logs <name>` | `pm2 logs` or `docker compose logs -f` |
| `app cd <name>` | `cd` into the folder |

Outside tmux, `app <name>` changes into the folder and runs the start command in the current shell.

A typical morning:

```bash
t                 # tmux session main
app molly         # window "molly": pnpm dev
app database      # window "database": docker compose up -d + logs
tun               # are the public hostnames up?
```

## tun: Cloudflare Tunnel

`tun` works on a **locally managed** tunnel: one `config.yml` with ingress rules, run by
`cloudflared` as a service. Tunnels managed in the Cloudflare dashboard (token based) have no local
config; change those in the dashboard.

### One-time setup

```bash
cloudflared tunnel login                  # browser login, writes ~/.cloudflared/cert.pem
cloudflared tunnel create mac             # writes ~/.cloudflared/<tunnel-id>.json
```

`~/.cloudflared/config.yml`:

```yaml
tunnel: <tunnel-id>
credentials-file: /Users/<you>/.cloudflared/<tunnel-id>.json

ingress:
  - hostname: molly.example.com
    service: http://localhost:3000
  - service: http_status:404          # must stay last: tun adds routes above it
```

```bash
cloudflared tunnel route dns mac molly.example.com
sudo brew services start cloudflared
```

### Commands

| Command | Action |
|---|---|
| `tun` | running or not, the tunnel name, and every `hostname → service` route |
| `tun add <host> <port\|url>` | add a route (a bare port becomes `http://localhost:<port>`), create its DNS record, restart |
| `tun rm <host>` | remove a route and restart; the DNS record stays (delete it in the dashboard) |
| `tun test <host>` | which rule a request for that hostname would hit |
| `tun share <port>` | temporary `*.trycloudflare.com` URL for a local port, no account needed; `Ctrl-C` ends it |
| `tun log` | follow the cloudflared log |
| `tun restart` | restart the service |
| `tun edit` | open `config.yml` in Neovim |

```bash
tun add gcs.example.com 5173
tun add api.example.com http://localhost:8080
tun share 3000                       # show a teammate what you're working on
```

Every change copies the config to `config.yml.bak` first and runs
`cloudflared tunnel ingress validate` afterwards; an invalid result is rolled back.

### Settings

| Variable (in `~/.zshrc.local`) | Default |
|---|---|
| `CLOUDFLARED_CONFIG` | `~/.cloudflared/config.yml` |
| `CLOUDFLARED_RESTART` | macOS: `sudo brew services restart cloudflared` · Linux: `sudo systemctl restart cloudflared` |

Running cloudflared with `cloudflared service install` instead of Homebrew? Then use
`export CLOUDFLARED_RESTART='launchctl kickstart -k gui/$(id -u)/com.cloudflare.cloudflared'`.

The tmux status bar shows **☁ tunnel** while a `cloudflared` process is running.

## PM2

Available when `pm2` is installed (`npm install -g pm2`):

| Alias | Command |
|---|---|
| `pml` | `pm2 ls` |
| `pmlog` | `pm2 logs --lines 100` |
| `pmr <name>` | `pm2 restart <name>` |
| `pms` | `pm2 save` (the list `pm2 resurrect` restores) |

To start the saved apps at login: `pm2 startup` once, then `pm2 save` whenever the list changes.

## Docker

The Docker helpers (`dps`, `dcu`, `dcl`, `dsh`, `lzd`, …) are listed in
[COMMANDS.md](COMMANDS.md#docker). `C-a D` opens lazydocker in a popup, and the status bar counts
running containers.
