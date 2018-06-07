# try to identify the session type
if [ -z "$SESSION_TYPE" ]; then
  #default: local
  SESSION_TYPE=local
  if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
    SESSION_TYPE=remote/ssh
  # many other tests omitted
  else
    case $(ps -o comm= -p $PPID) in
      sshd|*/sshd) SESSION_TYPE=remote/ssh;;
    esac
  fi
fi

# on remote connections: immediately open tmux
if [[ "$SESSION_TYPE" = "remote/ssh" && -z "$TMUX" ]]; then
  ZSH_TMUX_AUTOSTART=true
  ZSH_TMUX_AUTOCONNECT=true
  ZSH_TMUX_AUTOSTART_ONCE=true
  #ZSH_TMUX_FIXTERM=true
  $ZSH_TMUX_AUTOQUIT=false
fi

# load aliases if they exist
if [ -f "$HOME/.zsh_aliases" ]; then
    . "$HOME/.zsh_aliases"
fi

## load user-defined keyboard mapping
#if [ -e "$HOME/.Xmodmap" ] ; then
#  # is a display available?
#  if [ -n "${DISPLAY+x}" ]; then
#    # check if xmodmap is available
#    command -v xmodmap >/dev/null 2>&1 && xmodmap "$HOME/.Xmodmap"
#  fi
#fi

# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load. Optionally, if you set this to "random"
# it'll load a random theme each time that oh-my-zsh is loaded.
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
# ZSH_THEME="robbyrussell"
# ZSH_THEME="bira"
# ZSH_THEME="gnzh"
# ZSH_THEME="amuse"
# ZSH_THEME="junkfood"
#custom linked theme
ZSH_THEME="my_junkfood"

# Change the command execution timestamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
HIST_STAMPS="yyyy-mm-dd"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  git
  git-flow
  tmux
  docker
  colored-man-pages
  extract
)
#aws
#cp
#rsync

source $ZSH/oh-my-zsh.sh

