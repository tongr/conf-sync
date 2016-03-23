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
    xmodmap "$HOME/.Xmodmap"
fi
