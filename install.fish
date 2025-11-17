#!/usr/bin/env fish
cd (status dirname)
for arg in $argv
    switch $arg
        case fish yazi
            mkdir -p ~/.config/$arg
            ln -sfr $arg/* ~/.config/$arg/
        case mpv
            mkdir -p ~/.config/mpv/scripts
            ln -sfr mpv/{script-opts, *.conf} ~/.config/mpv/
            ln -sfr mpv/scripts/* ~/.config/mpv/scripts
        case cargo
            envsubst <cargo/config.toml >~/.cargo/config.toml
        case pip
            pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
        case pnpm
            pnpm config set registry https://registry.npmmirror.com
        case go
            go env -w GOPATH="$HOME/.go"
            go env -w GOMODCACHE="$HOME/.go/pkg/mod"
            go env -w GO111MODULE=on
            go env -w GOPROXY=https://goproxy.cn,direct
        case '*'
            echo unknown target: $arg
    end
end
