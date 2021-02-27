# add user binaries to paths if it exists
if [ -d "${HOME}/opt/bin" ] ; then
  PATH="${HOME}/opt/bin:${PATH}"
fi
if [ -d "${HOME}/bin" ] ; then
  PATH="${HOME}/bin:${PATH}"
fi

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
if [[ -e "${HOME}/.oh-my-zsh/custom/themes/powerlevel10k/" ]]; then
  ZSH_THEME="powerlevel10k/powerlevel10k"
else
  #custom linked theme
  ZSH_THEME="my_junkfood"
fi

# Change the command execution timestamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
HIST_STAMPS="yyyy-mm-dd"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  aws
  colored-man-pages
  common-aliases
  docker
  docker-compose
  extract
  git
  git-flow-avh
  git-extras
  history-substring-search
  minikube
  rsync
  tmux
  zsh-autosuggestions
  zsh-syntax-highlighting
)

#deactivate/override the recent branch extraction for git (very slow)
__git_recent_branches() {}

source $ZSH/oh-my-zsh.sh

export fpath=(${HOME}/.zsh/autocomplete $fpath)

# show completion menu when number of options is at least 2
zstyle ':completion:*' menu select=2

# select first option for git co(checkout)  automatically (same as `setopt menu_complete` but only for checkout)
zstyle ':completion:*:git*c(o|heckout):*' menu yes select

# Show message while waiting for completion
zstyle ':completion:*:git*c(o|heckout):*' show-completer true

# compsys initialization
autoload -U compinit promptinit
compinit



# activate miniconda3 (if exists)
if [ -f "${HOME}/miniconda3/etc/profile.d/conda.sh" ]; then
    source "${HOME}/miniconda3/etc/profile.d/conda.sh"
fi
