set -gx fish_greeting
set -gx fish_prompt_pwd_dir_length 0

set -gx TERM xterm-256color
set -gx COLORTERM truecolor

set -gx RUSTUP_UPDATE_ROOT https://rsproxy.cn/rustup
set -gx RUSTUP_DIST_SERVER https://rsproxy.cn

set -gx PNPM_HOME ~/.local/share/pnpm

alias ls='ls -h --classify --color=auto'
alias l='ls'
alias ll='ls -l'
alias la='ls -A'
alias lla='ls -lA'
alias df='df -h'
alias du='du --apparent-size --summarize -h'
alias free='free -h'
alias pgrep='pgrep --list-full'
alias tree='tree --gitignore --metafirst --du -puhDF'
alias bat='bat --wrap=never'
alias tokei='tokei --hidden --compact --sort=lines'
alias su='su --shell=$SHELL'
alias aria2c='aria2c --max-connection-per-server=16 --continue'

alias jrnl-vacuum='sudo journalctl --flush --rotate --vacuum-time'
alias cpv='rsync -r -h --perms --owner --group --partial --progress'
alias unzip-zh='unzip -O GB18030'
