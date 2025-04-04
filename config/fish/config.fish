source /usr/share/cachyos-fish-config/cachyos-config.fish

# overwrite greeting
# potentially disabling fastfetch
function fish_greeting
    # smth smth
end

# Add ~/.cargo/bin to PATH
#if test -d ~/.cargo/bin
#    if not contains -- ~/.carg/bin $PATH
#        set -p PATH ~/.cargo/bin
#    end
#end

set -Ux fifc_editor nvim
# Bind fzf completions to ctrl-x
#set -U fifc_keybinding \cx

set -x BEMOJI_PICKER_CMD "fuzzel -d"
set -gx EDITOR nvim
set -gx SYSTEMD_EDITOR nvim
set -gx VOLTA_HOME $HOME/.volta
set -gx GOPATH $HOME/go
set -gx PATH $VOLTA_HOME/bin $HOME/.cargo/bin /usr/local/opt/flameshot/bin $GOPATH/bin /usr/local/Cellar/john-jumbo/1.9.0_1/share/john $HOME/bins $PATH
set -gx PATH $PATH:~/.spicetify
set -gx PATH $PATH:/home/grimm/.local/bin
set -gx BUN_INSTALL $HOME/.bun
set -gx PATH $BUN_INSTALL/bin $PATH
set -gx MICRO_TRUECOLOR 1

# Aliases
alias c='clear'
#alias cat='bat --theme=base16 --number --color=always --paging=never --tabs=2 --wrap=never'
alias cat='see'
alias cp='cp -iv'
alias du='dust'
alias grep='rg'
alias tree='eza --tree --icons --tree'
alias ytmp3='yt-dlp --ignore-errors -x --audio-format mp3 -f bestaudio --audio-quality 0 --embed-metadata --embed-thumbnail --output \'%(title)s.%(ext)s\''
#alias ls='exa -L=1 -lhTag'
alias zc='zellij -s'
alias zl='zellij ls'
alias zac='za-no-dap pick'
alias hx='helix'
alias nnn='NNN_FIFO=/tmp/nnn.fifo NNN_SPLIT=h NNN_PLUG=p:preview-tui nnn'
alias search='sk --preview "bat --color=always --style=numbers --line-range=:500 {}" | xargs nvim'
alias mkpost='go run . artisan create:post'
alias refreshenv='source ~/.config/fish/config.fish'
alias weather='curl wttr.in'
alias gitui='gitui -t catppuccin-frappe.ron'

# nnn stuff
set -gx NNN_FIFO /tmp/nnn.fifo
set -gx NNN_PLUG p:preview-tui
set -gx NNN_SPLIT h


# Zoxide
zoxide init fish --cmd cd | source

# Starship
starship init fish | source

# Functions
function pip
    set output (~/bins/pyenv.sh $argv)
    if string match -q 'source*' $output; or string match -q 'deactivate*' $output
        eval $output
    else
        echo $output
    end
end

function 0x0
    set d (curl -fsSL -F"file=@$argv[1]" -Fexpires=1 -Fsecret= https://0x0.st)
    echo "$d/$argv[1]"
end

function zd
    if test -z "$argv[1]"
        set SELECTION (zellij list-sessions --no-formatting | awk '{ print $1 }' | gum choose --cursor="▌" --header="Select a session to delete" --selected="ide" --ordered --select-if-one --cursor.foreground="139")
    else
        set SELECTION $argv[1]
    end
    if test -z "$SELECTION"
        return 0
    end
    zellij d $SELECTION
end

function stream_video
    set host $argv[1]
    set video_path $argv[2]
    
    if test -z "$host" -o -z "$video_path"
        echo "Usage: stream_video <host> <remote_path_to_video>"
        return 1
    end
    
    ssh $host "ffmpeg -i '$video_path' -c:v libx264 -c:a aac -b:v 1M -b:a 150k -f mpegts -" | mpv -
end

function fish_should_add_to_history
    string match -qr "^\s" -- $argv; and return 1
    string match -qr "^clear\$" -- $argv; and return 1
    return 0
end

# Completion styling
set -U fish_color_autosuggestion brblack
set -U fish_color_command green
set -U fish_color_error red
set -U fish_color_param cyan
set -U fish_color_quote yellow
set -U fish_color_redirection magenta

set -U fish_history_ignore_space yes
set -U fish_history_ignore_dups yes

# Added by LM Studio CLI (lms)
set -gx PATH $PATH /home/grimm/.lmstudio/bin
