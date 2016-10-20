# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

# activate bash auto-completion for tmux cli
if [ -e "/usr/share/doc/tmux/examples/bash_completion_tmux.sh" ] ; then
    source "/usr/share/doc/tmux/examples/bash_completion_tmux.sh"
fi

# load user-defined keyboard mapping
if [ -e "$HOME/.Xmodmap" ] ; then
    # check if xmodmap is available
    command -v xmodmap >/dev/null 2>&1 && xmodmap "$HOME/.Xmodmap"
fi

# activate bash-git-prompt if installed (in ~/opt/bash-git-prompt)
if [ -e "$HOME/opt/bash-git-prompt/gitprompt.sh" ] ; then
  source "$HOME/opt/bash-git-prompt/gitprompt.sh"
  GIT_PROMPT_ONLY_IN_REPO=1
fi
