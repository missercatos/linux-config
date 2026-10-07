source /usr/share/cachyos-fish-config/cachyos-config.fish

# cachyos 的 eza 别名保留颜色，但 ls 去掉 -al（不再默认长列表/全显隐藏文件）
alias ls='eza --color=always --group-directories-first --icons=always'
alias la='eza -a --color=always --group-directories-first --icons=always'
alias ll='eza -l --color=always --group-directories-first --icons=always'
alias lt='eza -aT --color=always --group-directories-first --icons=always'
alias l.="eza -a | grep -e '^\.'"

set -gx HF_HOME /data/ai/cache/huggingface
set -gx TORCH_HOME /data/ai/cache/torch
set -gx OLLAMA_MODELS /data/ai/cache/ollama
set -gx UV_CACHE_DIR /data/ai/cache/uv

if status is-interactive
    # Commands to run in interactive sessions can go here
end
set fish_greeting ""
fish_vi_key_bindings
function fish_mode_prompt; end

# ===== 自动建议(幽灵文本)颜色：淡灰，与 nvim 补全保持一致，能看清又不与已输入内容混淆 =====
set -g fish_color_autosuggestion 8a94a8
# 补全候选列表选中项也要清晰可辨
set -g fish_color_selection --background=2f3d5e
set -g fish_color_search_match --background=2f3d5e

# ===== Clash 终端自动代理 =====
# 仅交互终端生效: 检测到 clash 端口(7890)开启 -> 自动启用代理加速
# 未开启 -> 不设代理, 走默认网络 (不影响 Chrome/Firefox 等 GUI)
if status is-interactive
    function __proxy_apply -a host port
        set -gx http_proxy http://$host:$port
        set -gx https_proxy http://$host:$port
        set -gx all_proxy socks5://$host:$port
        set -gx HTTP_PROXY http://$host:$port
        set -gx HTTPS_PROXY http://$host:$port
        set -gx ALL_PROXY socks5://$host:$port
        set -gx no_proxy localhost,127.0.0.1,::1
    end

    # 自动检测(仅在未手动指定时生效)
    function __proxy_auto
        if set -q __proxy_manual; return; end
        if command -v ss >/dev/null 2>&1; and ss -tln 2>/dev/null | grep -q ':7890 '
            __proxy_apply 127.0.0.1 7890
        else
            set -e http_proxy https_proxy all_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY no_proxy 2>/dev/null
        end
    end

    # 每次提示符前刷新(使开关即时生效)
    function __proxy_auto_hook --on-event fish_prompt
        __proxy_auto
    end
    # 初始执行一次
    __proxy_auto

    # 手动指定当前终端走某端口: proxyon [端口]; 之后自动检测不再覆盖
    function proxyon
        set -l p $argv[1]
        if test -z "$p"; set p 7890; end
        set -g __proxy_manual 1
        __proxy_apply 127.0.0.1 $p
        echo "代理已启用 -> 127.0.0.1:$p (仅当前终端, 手动锁定)"
    end
    function proxyoff
        set -e __proxy_manual 2>/dev/null
        set -e http_proxy https_proxy all_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY no_proxy 2>/dev/null
        echo "代理已关闭, 走默认网络"
    end
    function proxycheck
        if set -q __proxy_manual
            echo "代理模式: 手动锁定 http_proxy=$http_proxy"
        else if command -v ss >/dev/null 2>&1; and ss -tln 2>/dev/null | grep -q ':7890 '
            echo "代理模式: 自动 (clash 运行中)"
        else
            echo "代理模式: 默认网络 (clash 未运行)"
        end
    end
end

set -gx MANPATH /usr/share/man/zh_CN:
set -gx LANGUAGE zh_CN.UTF-8
set -p PATH ~/hackingtools/bin ~/.local/bin ~/.cargo/bin
set -gx STARSHIP_CONFIG /home/misser/.config/starship/starship-fish.toml
starship init fish | source
#zoxide init fish --cmd cd | source  # 未安装 zoxide，先注释；装好 sudo pacman -S zoxide 后取消注释
# 111
function y
	set tmp (mktemp -t "yazi-cwd.XXXXXX")
	yazi $argv --cwd-file="$tmp"
	if read -z cwd < "$tmp"; and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
		builtin cd -- "$cwd"
	end
	rm -f -- "$tmp"
end

# ls/cat/lt 不再覆盖为 eza/bat，恢复系统原版
# grub
abbr grub 'LANGUAGE=en_US.UTF-8 LANG=en_US.UTF-8 sudo grub-mkconfig -o /boot/grub/grub.cfg'
# 小黄鸭补帧 需要steam安装正版小黄鸭
abbr lsfg 'LSFG_PROCESS="miyu"'


abbr reboot 'systemctl reboot'
function sl 
	command sl | lolcat	
end
function 滚
	sysup 
end
function 安装
	command yay -S $argv
end

function 卸载
	command yay -Rns $argv
end 


#终端自动开启CUDA
set -gx CUDA_HOME /opt/cuda
set -gx PATH $CUDA_HOME/bin $PATH

#自行训练模型的模型和缓存自动导向到data目录下面
set -gx COMFY_CLI_WORKSPACE /data/ai/comfyui
set -gx HF_HOME /data/ai/cache/huggingface
set -gx TORCH_HOME /data/ai/cache/torch
set -gx OLLAMA_MODELS /data/ai/cache/ollama

set -lx CUDA_HOME /opt/cuda
set -lx LD_LIBRARY_PATH /opt/cuda/lib64 $LD_LIBRARY_PATH

#默认python-agent相关的缓存和库下载导向到/data分区下面
set -gx UV_CACHE_DIR /data/ai/cache/uv
set -gx UV_TOOL_DIR /data/ai/uv/tools
set -gx UV_PYTHON_INSTALL_DIR /data/ai/uv/python
set -gx PIP_CACHE_DIR /data/ai/cache/pip
set -gx PIP_INDEX_URL https://pypi.tuna.tsinghua.edu.cn/simple

#在显示管理器因为权限问题卡死后，可以直接在TTY进入plasma环境
if status is-interactive; and test "$XDG_VTNR" = 2; and test -z "$WAYLAND_DISPLAY"; and test -z "$DISPLAY"
    exec dbus-run-session startplasma-wayland
end

# tty3 进入 niri 环境
if status is-interactive; and test "$XDG_VTNR" = 3; and test -z "$WAYLAND_DISPLAY"; and test -z "$DISPLAY"
    exec niri-session
end

# conda 已通过 /opt/miniconda3/etc/fish/conf.d/conda.fish 自动加载，无需重复初始化

