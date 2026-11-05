# ---------------------------------------------------------------------------
# Homebrew (must come first: sheldon and starship are installed through it)
# ---------------------------------------------------------------------------
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# ---------------------------------------------------------------------------
# PATH
# ---------------------------------------------------------------------------
[[ -d /opt/homebrew/opt/openjdk/bin ]] && export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

# ---------------------------------------------------------------------------
# History
# ---------------------------------------------------------------------------
HISTFILE="$HOME/.zsh_history"   # set explicitly: only macOS provides a default
HISTSIZE=50000
SAVEHIST=50000
setopt SHARE_HISTORY            # append on exit and share between sessions
setopt EXTENDED_HISTORY         # save timestamps + durations
setopt HIST_IGNORE_DUPS         # skip consecutive duplicates
setopt HIST_IGNORE_SPACE        # commands starting with a space aren't saved
setopt HIST_EXPIRE_DUPS_FIRST   # trim duplicates first when the file is full
setopt HIST_VERIFY              # !! expands into the prompt instead of running

# ---------------------------------------------------------------------------
# Completion - run before plugins so any plugin that calls compdef works
# ---------------------------------------------------------------------------
autoload -Uz compinit && compinit

# ---------------------------------------------------------------------------
# Plugins (sheldon) - plugin list lives in ~/.config/sheldon/plugins.toml
# ---------------------------------------------------------------------------
eval "$(sheldon source)"

# ---------------------------------------------------------------------------
# Aliases
# ---------------------------------------------------------------------------
alias lg="lazygit"
alias history="fc -l 1"         # plain zsh `history` shows only the last 16
if [[ "$OSTYPE" == darwin* ]]; then
  alias ls="ls -G"
else
  alias ls="ls --color=auto"
fi

# ---------------------------------------------------------------------------
# Prompt (starship)
# ---------------------------------------------------------------------------
export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"
if (( $+commands[starship] )); then
  eval "$(starship init zsh)"
fi

# ---------------------------------------------------------------------------
# Machine-specific overrides (not tracked in this repo; loaded last so it can
# override anything above). Put work-only PATHs, env vars and secrets here.
# ---------------------------------------------------------------------------
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
