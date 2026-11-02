# Fastfetch every session.
[[ -z "$ZED_TERM" ]] && fastfetch

# Starship Prompt.
eval "$(starship init zsh)"

# Aliases.
alias c="clear"
alias ls="ls --color=auto"
alias grep="grep --color=auto"
alias v="micro"
alias sv="sudo micro"

# Auto-refresh Waybar package counter after update.
alias up='yay && qs ipc call stats refreshUpdates'


# Full system cleanup.
alias sysclean='sudo pacman -Rns $(pacman -Qtdq) 2>/dev/null; sudo paccache -rk1; sudo paccache -ruk0; yay -Sc --aur --noconfirm; sudo journalctl --vacuum-size=50M; rm -rf ~/.cache/thumbnails/* ~/.local/share/Trash/*; echo "System Cleaned Successfully"'


# FPL RUNNER
alias fpl='cd ~/FPL && source venv/bin/activate'

# Show the active venv in the right prompt (RPROMPT)
setopt prompt_subst
show_virtual_env() {
    if [[ -n "$VIRTUAL_ENV" ]]; then
        echo "(%F{cyan}$(basename "$VIRTUAL_ENV")%f) "
    fi
}
RPROMPT='$(show_virtual_env)'
export PATH="$HOME/.local/bin:$PATH"
export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"
ssh-add -l >/dev/null 2>&1; [[ $? -eq 1 ]] && ssh-add ~/.ssh/id_ed25519
setopt interactive_comments
