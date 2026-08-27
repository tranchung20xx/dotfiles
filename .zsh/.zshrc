# Start configuration added by Zim Framework install {{{
#
# User configuration sourced by interactive shells
#

# -----------------
# Zsh configuration
# -----------------

#
# History
#

# Remove older command from the history if a duplicate is to be added.
setopt HIST_IGNORE_ALL_DUPS

autoload -U select-word-style
select-word-style bash

#
# Input/output
#

# Set editor default keymap to emacs (`-e`) or vi (`-v`)
bindkey -e

# Prompt for spelling correction of commands.
#setopt CORRECT

# Customize spelling correction prompt.
#SPROMPT='zsh: correct %F{red}%R%f to %F{green}%r%f [nyae]? '

# Remove path separator from WORDCHARS.
WORDCHARS=${WORDCHARS//[\/]}

# --------------------
# Module configuration
# --------------------

#
# git
#

# Set a custom prefix for the generated aliases. The default prefix is 'G'.
#zstyle ':zim:git' aliases-prefix 'g'

#
# input
#

# Append `../` to your input for each `.` you type after an initial `..`
#zstyle ':zim:input' double-dot-expand yes

#
# termtitle
#

# Set a custom terminal title format using prompt expansion escape sequences.
# See http://zsh.sourceforge.net/Doc/Release/Prompt-Expansion.html#Simple-Prompt-Escapes
# If none is provided, the default '%n@%m: %~' is used.
#zstyle ':zim:termtitle' format '%1~'

#
# zsh-autosuggestions
#

# Disable automatic widget re-binding on each precmd. This can be set when
# zsh-users/zsh-autosuggestions is the last module in your ~/.zimrc.
ZSH_AUTOSUGGEST_MANUAL_REBIND=1

# Customize the style that the suggestions are shown with.
# See https://github.com/zsh-users/zsh-autosuggestions/blob/master/README.md#suggestion-highlight-style
#ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=242'

#
# zsh-syntax-highlighting
#

# Set what highlighters will be used.
# See https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/docs/highlighters.md
# ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)

# Customize the main highlighter styles.
# See https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/docs/highlighters/main.md#how-to-tweak-it
#typeset -A ZSH_HIGHLIGHT_STYLES
#ZSH_HIGHLIGHT_STYLES[comment]='fg=242'

# ------------------
# Initialize modules
# ------------------

ZIM_HOME=${ZDOTDIR:-${HOME}}/.zim
# Download zimfw plugin manager if missing.
if [[ ! -e ${ZIM_HOME}/zimfw.zsh ]]; then
  if (( ${+commands[curl]} )); then
    curl -fsSL --create-dirs -o ${ZIM_HOME}/zimfw.zsh \
        https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
  else
    mkdir -p ${ZIM_HOME} && wget -nv -O ${ZIM_HOME}/zimfw.zsh \
        https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
  fi
fi
# Install missing modules, and update ${ZIM_HOME}/init.zsh if missing or outdated.
if [[ ! ${ZIM_HOME}/init.zsh -nt ${ZIM_CONFIG_FILE:-${ZDOTDIR:-${HOME}}/.zimrc} ]]; then
  source ${ZIM_HOME}/zimfw.zsh init
fi
# Initialize modules.
source ${ZIM_HOME}/init.zsh
# }}} End configuration added by Zim Framework install
#

export PATH="$HOME/.local/bin:$PATH"

# export PS1="%B%{$(tput setaf 226)%}[%n%{$(tput setaf 214)%}@%{$(tput setaf 219)%}%m %{$(tput setaf 227)%}%~]%{$(tput sgr0)%}$%b "
#

autoload -Uz add-zsh-hook
zstyle ':zim:git-info:branch' format '(%b)'
zstyle ':zim:git-info:dirty'  format '*'
zstyle ':zim:git-info:indexed'   format '+'
zstyle ':zim:git-info:unindexed' format '*'
# Assemble what shows up in the prompt.
# Matches your old behavior exactly (branch only):
zstyle ':zim:git-info:keys' format 'prompt' ' %b'
# --- If you actually want staged(+)/unstaged(*) markers like the
#     zstyle names implied, use this instead (needs verbose mode
#     for indexed/unindexed counts):
# zstyle ':zim:git-info' verbose yes
# zstyle ':zim:git-info:keys' format 'prompt' ' (%b%i%I)'
add-zsh-hook precmd git-info
prompt_suse_setup () {
  local user_color="%(#.%F{red}.%F{yellow})"
  local host_color="%F{green}"
  local dir_color="%F{blue}"
  local git_color="%F{yellow}"   # see note below on 8-color limits
  PS1="%B${user_color}%n%f%b@%B${host_color}%m%f%b:%B${dir_color}%~%f%b%B${git_color}\${(e)git_info[prompt]}%f%b > "
  PS2="%B${user_color}>%f%b "
  prompt_opts=( cr percent )
}
prompt_suse_setup "$@"
