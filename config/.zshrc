source ~/.local/share/zsh-config.zsh

# zsh 自启补全
autoload -Uz compinit && compinit

export STARSHIP_CONFIG=~/.config/starship-repos/starship-themes/viking.toml
eval "$(starship init zsh)"

# 和 fish 保持一致的文件着色（eza）
alias ls='eza --color=always --group-directories-first --icons=always'
alias la='eza -a --color=always --group-directories-first --icons=always'
alias ll='eza -l --color=always --group-directories-first --icons=always'
alias lt='eza -aT --color=always --group-directories-first --icons=always'
