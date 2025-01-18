# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="jovial"

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to enable command auto-correction.
ENABLE_CORRECTION="true"

# Add wisely, as too many plugins slow down shell startup.
plugins=(
  git
  urltools
  bgnotify
  zsh-autosuggestions
  zsh-syntax-highlighting
  zsh-history-enquirer
  zsh-fzf-history-search
  fzf-tab
  jovial
)

source $ZSH/oh-my-zsh.sh

# User configuration

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

export BEMOJI_PICKER_CMD="fuzzel -d"
export EDITOR="nvim"
export HOMEBREW_NO_AUTO_UPDATE=true
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="/usr/local/opt/flameshot/bin:$PATH"
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"
export PATH="$PATH:/usr/local/Cellar/john-jumbo/1.9.0_1/share/john"
export PATH="$HOME/bins:$PATH"

#####
# Aliases
#####
alias c='clear'
alias cat='bat --theme=base16 --number --color=always --paging=never --tabs=2 --wrap=never'
alias cp='cp -iv'
alias du='dust'
alias grep='rg'
alias tree='eza --tree --icons --tree'
alias ytmp3='yt-dlp --ignore-errors -x --audio-format mp3 -f bestaudio --audio-quality 0 --embed-metadata --embed-thumbnail --output '\''%(title)s.%(ext)s'\'''
alias ls='exa -L=1 -lhTag'
alias zc='zellij -s'
alias zl='zellij ls'
alias nnn='NNN_FIFO=/tmp/nnn.fifo NNN_SPLIT='h' NNN_PLUG='p:preview-tui' nnn'
alias search='fzf --preview "bat --color=always --style=numbers --line-range=:500 {}" | xargs nvim'
alias cd='z'
#alias ssh='kitty +kitten ssh'
alias ssh='TERM=xterm-256color ssh'
alias mkpost='go run . artisan create:post'
alias refreshenv='source ~/.zshrc'
alias weather='curl wttr.in'

export PATH=$PATH:~/.spicetify


export "MICRO_TRUECOLOR=1"


# nnn stuff

#alias nnn='NNN_FIFO=/tmp/nnn.fifo NNN_SPLIT='h' NNN_PLUG='p:preview-tui' nnn'
NNN_FIFO='/tmp/nnn.fifo'
NNN_PLUG='p:preview-tui'
NNN_SPLIT='h'


# Shell integrations
eval "$(starship init zsh)"
eval "$(zoxide init --cmd z --hook prompt zsh)"
eval "$(fzf --zsh)"

# Pomodoro timer aliases 

declare -A pomo_options
pomo_options["work"]="25"
pomo_options["break"]="10"

pomodoro () {
  if [ -n "$1" -a -n "${pomo_options["$1"]}" ]; then
  val=$1
  echo $val | lolcat
  timer ${pomo_options["$val"]}m
  notify-send --app-name=Pomodoro🍅 "'$val' session done"
  fi
}

alias wo="pomodoro 'work'"
alias br="pomodoro 'break'"

# Functions 

pip() {
    local output
    output=$(~/bins/pyenv.sh "$@")
    if [[ $output == source* ]] || [[ $output == deactivate* ]]; then
        eval "$output"
    else
        echo "$output"
    fi
}

0x0 () {
  d=$(curl -fsSL -F"file=@$1" -Fexpires=1 -Fsecret= https://0x0.st)
  echo "$d/$1"
}

zd() {
  if [ -z $1 ]; then
    SELECTION=$(
      zellij list-sessions \
        --no-formatting \
        | awk '{ print $1 }' \
        | gum choose \
          --cursor="▌" \
          --header="Select a session to delete" \
          --selected="ide" \
          --ordered --select-if-one --cursor.foreground="139"
    )
  else
    SELECTION=$1
  fi

  if [ -z $SELECTION ]; then
    return 0
  fi

  zellij d "$(echo -e $SELECTION)"
}

stream_video() {
    local host="$1"
    local video_path="$2"
    
    if [ -z "$host" ] || [ -z "$video_path" ]; then
        echo "Usage: stream_video <host> <remote_path_to_video>"
        return 1
    fi
    
    ssh "$host" "ffmpeg -i '$video_path' -c:v libx264 -c:a aac -b:v 1M -b:a 150k -f mpegts -" | mpv -
}

# Created by `pipx` on 2024-08-13 06:32:12
export PATH="$PATH:/home/grimm/.local/bin"

# bun completions
[ -s "/home/grimm/.bun/_bun" ] && source "/home/grimm/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Completion styling

zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
zstyle ':fzf-tab:somplete:__zoxide_z:*' fzf-preview 'eza -1 --color=always $realpath'

# Keybinings
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward

# History
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

source /home/grimm/.config/broot/launcher/bash/br

## [Completion]
## Completion scripts setup. Remove the following line to uninstall
[[ -f /home/grimm/.dart-cli-completion/zsh-config.zsh ]] && . /home/grimm/.dart-cli-completion/zsh-config.zsh || true
## [/Completion]

