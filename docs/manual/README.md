# User manual

[`manual.pdf`](manual.pdf) is the complete user manual (English, about 35 pages): installation,
terminal apps and copy/paste, the shell, tmux and the status bar, Neovim, web apps and Cloudflare
Tunnel, ROS containers and robots, customization, troubleshooting and a quick reference.

It is written in LaTeX:

| File | Contents |
|---|---|
| `manual.tex` | title page, table of contents, chapter list |
| `preamble.tex` | layout, fonts, colours, table and code styles |
| `chapters/*.tex` | one file per chapter |
| `figures/` | logo and screenshots used only here (the others come from `../../assets/`) |

Build with `make` (TeX Live with `latexmk`; on macOS `brew install --cask mactex-no-gui`).
CI builds it on every push and uploads the PDF as an artifact.
