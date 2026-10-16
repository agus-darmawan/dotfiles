# ─────────────────────────────────────────────────────────────
#  zsh — agus-darmawan/dotfiles
#  Modules live in ~/.config/zsh/*.zsh (loaded in order).
#  Machine-specific stuff → ~/.zshrc.local (not in git).
# ─────────────────────────────────────────────────────────────

ZDOTCFG="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"

for _f in "$ZDOTCFG"/*.zsh(N); do
  source "$_f"
done
unset _f

[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
