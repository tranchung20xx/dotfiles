export ZDOTDIR="$HOME/.zsh"
[[ -f "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"

export PATH="$HOME/.local/bin:$PATH"
export QT_QPA_PLATFORMTHEME=qt6ct
export QT_FONT_DPI=144

export XMODIFIERS=@im=fcitx
export QT_IM_MODULE=fcitx
export QT_IM_MODULES="wayland;fcitx"
export GLFW_IM_MODULE=ibus
