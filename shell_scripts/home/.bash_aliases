\# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
  test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
  alias ls='ls --color=auto'
  alias grep='grep --color=auto'
  alias fgrep='fgrep --color=auto'
  alias egrep='egrep --color=auto'
fi

# some more ls aliases
alias ll='ls -hlF'
alias la='ls -a'
alias lla='ll -a'

alias cd..='cd ..'
alias cd...='cd ../..'
alias cd....='cd ../../..'
alias cd.....='cd ../../../..'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# get the PID(s) of commands matching the query (found w/ ps)
#get_pid() { ps axf | grep "$*" | grep -v grep | awk '{print $1}'; }
alias psgrep="ps ux -U $USER | grep -v grep | grep"
alias psgrepa="ps aux | grep -v grep | grep"
alias psg="psgrep"
pidgrep() { psgrep "$*" | awk '{print $2}'; }
pidgrepa() { psgrepa "$*" | awk '{print $2}'; }
alias pidg="pidgrep"


# zip and unzip with progress indicator
tgz() { tar -cf - $@ | pv -s $(wc -c $@ | tail -n1 | awk '{print $1}') |  gzip; }
tgzfast() { tar -cf - $@ | pv -s $(wc -c $@ | tail -n1 | awk '{print $1}') |  gzip --fast; }
untgz() {
  # check input file parameter
  if [ -z "$1" ] ; then >&2 echo "Usage: untgz tyz_file [output_dir]"; return 1; fi
  if [ ! -f "$1" ] ; then >&2 echo "Error: Archive $1 does not exist"'!'; return 1; fi
  # output file given
  if [ ! -z "$2" ]; then
    # mkdir
    if [ ! -e "$2" ] ; then mkdir -p "$2" || return 2; fi
    # check for dir
    if [ ! -d "$2" ] ; then >&2 echo "Error: $2 is not a directory"'!'; return 2; fi
    # extract to $2

    zcat "$1" | pv -s $(gzip -l "$1" | tail -n+2 | awk '{sum+=$2}END{printf "%1.0f",sum}') | tar -x -C "$2";
  else
    # extract to stdout
    zcat "$1" | pv -s $(gzip -l "$1" | tail -n+2 | awk '{sum+=$2}END{printf "%1.0f",sum}') | tar -x;
  fi
}

#
# ssh shortcuts
#
# open ssh session and start tmux remotely
ssh_tmux() {
  if [ -z "$1" ]; then
    >&2 echo "SSH host missing!"
    return 1
  fi
  if [ -n "$2" ]; then
    if [ "ls" == "$2" ]; then
      ssh -t $1 "tmux ls"
    elif [ "lsopts" == "$2" ]; then
      # internal command to provide autocompletion
      ssh -t $1 "tmux ls" 2> /dev/null | awk -F":" 'BEGIN{printf "ls"}{printf " "$1}'
    else
#      echo ssh -t $1 "tmux attach -d -t ${@:2} || tmux new -s ${@:2}"
      ssh -t $1 "tmux attach -d -t ${@:2}  2> /dev/null || tmux new -s ${@:2}"
    fi
  else
    ssh -t $1 'tmux attach -d  2> /dev/null || tmux new'
  fi
}

# define an alias for each host in the ~/.ssh/config
eval $(awk '$1=="Host" {print "alias " $2 "=\47ssh_tmux " $2 "\47;" }' $HOME/.ssh/config)
# enable auto completion for this alias (continue ssh_tmux sessions)
eval $(awk '$1=="Host" {print "_" $2 "() { local cur opts; cur=\"${COMP_WORDS[COMP_CWORD]}\";opts=\"$(" $2 " lsopts)\";COMPREPLY=($(compgen -W \"${opts}\" -- ${cur}) ); return 0; }; complete -F _" $2 " " $2 "; " }' $HOME/.ssh/config)

# proxy for tunneled localhost connections
sshproxy() {
  if [ "$#" -le "0" ]; then
    >&2 echo "Error: host missing"'!';
    >&2 echo "USAGE: $FUNCNAME HOST open|close [PORT]";
    return 1;
  fi
  local HOST=$1
  local PORT=${3:-56423}
  local PROXY_PID=`pidgrep "ssh -f -qTnN -D $PORT $HOST"`
  echo pidgrep "ssh -f -qTnN -D $PORT $HOST"
  if [ "$#" -gt "1" ]; then
    if [ "$2" == "open" ]; then
      if [ "$PROXY_PID" != "" ]; then
        >&2 echo "Open connection found (PID: $PROXY_PID), try: $FUNCNAME $HOST close"; return 2;
      else
        ssh -f -qTnN -D $PORT $HOST
      fi
    elif [ "$2" == "close" ]; then
      if [ "$PROXY_PID" != "" ]; then
        kill $PROXY_PID
      else
        >&2 echo "No open connections found, try: $FUNCNAME $HOST open"; return 3;
      fi
    else
      >&2 echo "Unknown option $2"; return 4;
    fi
  else
    if [ "$PROXY_PID" != "" ]; then
      # no option found, but connection open
      echo "Open connection found, try: $FUNCNAME $HOST close"
    else
      # no option and no open connection(s) found
      echo "No open connections found, try: $FUNCNAME $HOST open"
    fi
  fi
}
#kill `pidgrep 'ssh -f -qTnN -D 56423'`
_sshproxy() { cur="${COMP_WORDS[COMP_CWORD]}"; if [ "$COMP_CWORD" -gt "1" ]; then COMPREPLY=($(compgen -W "open close" -- ${cur}) ); return 0; fi; COMPREPLY=($(compgen -W "$(awk '$1=="Host" { print $2 }' $HOME/.ssh/config)" -- ${cur}) ); return 0; }
complete -F _sshproxy sshproxy
