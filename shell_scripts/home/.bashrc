# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
  PATH="$HOME/bin:$PATH"
fi
# add snapcraft k9s to path because it is not properly supported
if [ -f "/snap/k9s/current/bin/k9s" ]; then
  PATH="${PATH}:/snap/k9s/current/bin"
fi

# activate bash auto-completion for tmux cli
if [ -e "/usr/share/doc/tmux/examples/bash_completion_tmux.sh" ] ; then
  source "/usr/share/doc/tmux/examples/bash_completion_tmux.sh"
fi

## load user-defined keyboard mapping
#if [ -e "$HOME/.Xmodmap" ] ; then
#  # is a display available?
#  if [ -n "${DISPLAY+x}" ]; then
#    # check if xmodmap is available
#    command -v xmodmap >/dev/null 2>&1 && xmodmap "$HOME/.Xmodmap"
#  fi
#fi

# activate bash-git-prompt if installed (in ~/opt/bash-git-prompt)
if [ -e "$HOME/opt/bash-git-prompt/gitprompt.sh" ] ; then
  GIT_PROMPT_ONLY_IN_REPO=0
  GIT_PROMPT_THEME=TruncatedPwd_WindowTitle_Ubuntu
  source "$HOME/opt/bash-git-prompt/gitprompt.sh"
fi

export BASH_IT_THEME='nwinkler'

# make `host.docker.internal` available via docker run ... $DOCKER_HOST_INTERNAL ...
DOCKER_HOST_INTERNAL="--add-host=host.docker.internal:host-gateway"

# activate miniconda3 (if exists)
if [ -f "${HOME}/miniconda3/etc/profile.d/conda.sh" ]; then
    source "${HOME}/miniconda3/etc/profile.d/conda.sh"
fi

