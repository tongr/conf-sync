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
  # is a display available?
  if [ -n "${DISPLAY+x}" ]; then
    # check if xmodmap is available
    command -v xmodmap >/dev/null 2>&1 && xmodmap "$HOME/.Xmodmap"
  fi
fi

# activate bash-git-prompt if installed (in ~/opt/bash-git-prompt)
if [ -e "$HOME/opt/bash-git-prompt/gitprompt.sh" ] ; then
  GIT_PROMPT_ONLY_IN_REPO=0
  GIT_PROMPT_THEME=TruncatedPwd_WindowTitle_Ubuntu
  source "$HOME/opt/bash-git-prompt/gitprompt.sh"
fi
