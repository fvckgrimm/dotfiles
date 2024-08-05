# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="jovial"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  git
  urltools
  bgnotify
  zsh-autosuggestions
  zsh-syntax-highlighting
  zsh-history-enquirer
  jovial
)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

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

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
export HOMEBREW_NO_AUTO_UPDATE=true
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"
export PATH="~/.cargo/bin:$PATH"
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

export PATH=$PATH:~/.spicetify


export "MICRO_TRUECOLOR=1"

#####
# nnn stuff
#####
#alias nnn='NNN_FIFO=/tmp/nnn.fifo NNN_SPLIT='h' NNN_PLUG='p:preview-tui' nnn'
NNN_FIFO='/tmp/nnn.fifo'
NNN_PLUG='p:preview-tui'
NNN_SPLIT='h'

####
# zoxide
####

eval "$(zoxide init --cmd z --hook prompt zsh)"

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

za() {
  if [ -z $1 ]; then
    SELECTION=$(
      zellij list-sessions \
        --no-formatting \
        | awk '{ print $1 }' \
        | gum choose \
          --cursor="▌" \
          --header="Select a session to attach to" \
          --selected="ide" \
          --ordered --select-if-one --cursor.foreground="139"
    )
  else
    SELECTION=$1
  fi

  if [ -z $SELECTION ]; then
    return 0
  fi

  zellij attach "$(echo -e $SELECTION)"
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
