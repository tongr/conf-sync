# enable color support of ls and also add handy aliases
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

# unmount all network shares
alias umount-all-cfis="sudo umount -a -t cifs -l"

# cleanup swap
alias unswap='sudo sh -c "swapoff -a; swapon -a; echo done!"'

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
sshtmux() {
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
      # debug:
      #echo ssh -t $1 "tmux attach -d -t ${@:2} || tmux new -s ${@:2}"
      ssh -t $1 "tmux attach -d -t ${@:2}  2> /dev/null || tmux new -s ${@:2}"
    fi
  else
    ssh -t $1 'tmux attach -d  2> /dev/null || tmux new'
  fi
}

# define an alias for each host in the ~/.ssh/config
if [ -e "$HOME/.ssh/config" ] ; then
  eval $(awk '$1=="Host" {print "alias " $2 "=\47sshtmux " $2 "\47;" }' $HOME/.ssh/config)
  # enable auto completion for this alias (continue sshtmux sessions)
  eval $(awk '$1=="Host" {print "_" $2 "() { local cur opts; cur=\"${COMP_WORDS[COMP_CWORD]}\";opts=\"$(" $2 " lsopts)\";COMPREPLY=($(compgen -W \"${opts}\" -- ${cur}) ); return 0; }; complete -F _" $2 " " $2 "; " }' $HOME/.ssh/config)  
fi

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
  # debug:
  #echo pidgrep "ssh -f -qTnN -D $PORT $HOST"
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

# calculate a server port number (5____) given a host name (param $1)
function server_port { printf "5%-4s%s\n" "$(echo $((0x$(echo -n $1 | md5sum | cut -f1 -d' '))) | cut -c2-5)" | tr ' ' '0'; }

#kill `pidgrep 'ssh -f -qTnN -D 56423'`
_sshproxy() { cur="${COMP_WORDS[COMP_CWORD]}"; if [ "$COMP_CWORD" -gt "1" ]; then COMPREPLY=($(compgen -W "open close" -- ${cur}) ); return 0; fi; COMPREPLY=($(compgen -W "$(awk '$1=="Host" { print $2 }' $HOME/.ssh/config)" -- ${cur}) ); return 0; }
complete -F _sshproxy sshproxy

tunnel_ssh() {
  if [ "$#" -le "1" ]; then
    >&2 echo "Error: host(s) missing"'!';
    >&2 echo "USAGE: $FUNCNAME TUNNEL_HOST REMOTE_HOST";
    return 1;
  fi
  # get parameters
  tunnel_host="$1"
  remote_host="$2"
  # use always the same port for one remote host?
  lport=`server_port $remote_host`
  if [ "0" -lt "$( netstat -tlpn 2> /dev/null | grep ":$lport " | wc -l )" ]; then
    # port not free
    echo "port $lport not free"
    >&2 echo "Error: port $lport not free"'!';
    return 1;
  else
    echo "free port to connect to $remote_host found: $lport"
  fi
  # pick a random port
  #while true ; do
  #  let "lport = $RANDOM % 10000 + 50000"
  #  if [ "0" -lt "$( netstat -tlpn 2> /dev/null | grep ":$lport " | wc -l )" ]; then
  #    # port not free
  #    echo "port $lport not free"
  #  else
  #    echo "free port found: $lport"
  #    break
  #  fi
  #done
  # get remote host configs
  rhost="$(ssh -G $remote_host | grep '^hostname ' | cut -d' ' -f2)"
  rport="$(ssh -G $remote_host | grep '^port ' | cut -d' ' -f2)"
  ruser="$(ssh -G $remote_host | grep '^user ' | cut -d' ' -f2)"
  # get first existing identity file
  ridentityfile="$(ssh -G $remote_host | grep '^identityfile ' | cut -d' ' -f2 | while read line ; do
    # eval path (i.e., ~/...)
    file=$(eval echo $line)
    if [ -e "$file" ] ; then
      echo "$file"
      break
    fi
  done)"
  # open tunnel
  ssh -f $tunnel_host -L "$lport:$rhost:$rport" -N
  # remote connection via tunnel
  if [ -n "$ridentityfile" ] ; then
    ssh -i $ridentityfile -p "$lport" -t "$ruser@localhost" 'tmux attach -d  2> /dev/null || tmux new'
  else
    ssh -p "$lport" -t "$ruser@localhost" 'tmux attach -d  2> /dev/null || tmux new'
  fi
  echo "trying to close tunnel to $tunnel_host from local port $lport of process $(pidgrep "ssh -f $1 -L "$lport:$rhost:$rport" -N") ..."
  kill $(pidgrep "ssh -f $1 -L "$lport:$rhost:$rport" -N")
}
_tunnel_ssh() { cur="${COMP_WORDS[COMP_CWORD]}"; if [ "$COMP_CWORD" -lt "2" ]; then COMPREPLY=($(compgen -W "$(awk '$1=="Host" { print $2 }' $HOME/.ssh/config)" -- ${cur}) ); elif [ "$COMP_CWORD" -lt "3" ]; then COMPREPLY=($(compgen -W "$(awk '$1=="Host" { print $2 }' $HOME/.ssh/config)" -- ${cur}) ); fi; return 0; }
complete -F _tunnel_ssh tunnel_ssh

# opening a sinlge port to a ssh host (same local port than on the remote machine)
tunnel_port() {
  if [ "$#" -lt "1" ]; then
    >&2 echo "Error: port (and host) missing"'!';
    >&2 echo "USAGE: $FUNCNAME TARGET_PORT [TARGET_HOST]";
    return 1;
  fi

  # get parameters
  local port="$1"
  local host="$2"
  local PROXY_PID=`pidgrep ssh -f -N -L $port:localhost:$port`
  if [ "$PROXY_PID" != "" ]; then
    echo "closing tunneled port $port (killing \"$(psgrep "ssh -f -N -L $port:localhost:$port" | cut -c66-)\") ..."
    kill $PROXY_PID
  else
    if [ "$#" -le "1" ]; then
      >&2 echo "Error: host missing to create a connection"'!';
      >&2 echo "USAGE: $FUNCNAME TARGET_PORT TARGET_HOST";
      return 1;
    fi

    echo "opening port $port to $host ..."
    ssh -f -N -L "$port:localhost:$port" isfet
  fi
}
_tunnel_port() { cur="${COMP_WORDS[COMP_CWORD]}"; if [ "$COMP_CWORD" -eq "2" ]; then COMPREPLY=($(compgen -W "$(awk '$1=="Host" { print $2 }' $HOME/.ssh/config)" -- ${cur}) ); fi; return 0; }
complete -F _tunnel_port tunnel_port

