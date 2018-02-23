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

# snappy compression (assumes snappy-python is installed)
alias snappy='python -m snappy'

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

#
# fixes for annoying ubuntu problems
#
# restart network manager in case of wifi problems after suspend
alias restart-network-manager="sudo service network-manager restart"

# try to list old linux images to free stpace in /boot (ubuntu issue)
purge_linux_images() {
  printf "avaliable images:\n%s\n" "$(dpkg -l | grep linux-image)"
  printf "\ncleanup using:\n"
  for img in $(dpkg -l | grep linux-image | awk '$1=$1' | cut -d' ' -f2 | grep -v extra | sort | head -n-2); do
    printf "sudo apt-get purge %s; " "${img}";
  done
  printf "\n"
}
alias trim_boot="purge_linux_images"

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
if [ -f "$HOME/.ssh/config" ] ; then
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

#kill `pidgrep 'ssh -f -qTnN -D 56423'`
_sshproxy() { cur="${COMP_WORDS[COMP_CWORD]}"; if [ "$COMP_CWORD" -gt "1" ]; then COMPREPLY=($(compgen -W "open close" -- ${cur}) ); return 0; fi; if [ -f "$HOME/.ssh/config" ] ; then COMPREPLY=($(compgen -W "$(awk '$1=="Host" { print $2 }' $HOME/.ssh/config)" -- ${cur}) ); fi; return 0; }
complete -F _sshproxy sshproxy

# calculate a server port number (5____) given a host name (param $1)
function server_port { printf "5%-4s%s\n" "$(echo $((0x$(echo -n $1 | md5sum | cut -f1 -d' '))) | cut -c2-5)" | tr ' ' '0'; }

# create an entry for the tunneled connection to a server in .ssh/config
# --> read the config, change hostname ($1) to "__host" HostName to "127.0.0.1" port to ```server_port $1``` and write the entry
add_tunneled_host() {
  local orig_host=$1
  local start_line=""
  local end_line=""
  local config_file='.ssh/config'
  if [ ! -f "$HOME/.ssh/config" ] ; then
    return 1
  fi
  for hostline in $(grep -n '^Host[[:space:]]*' $config_file | sed 's/Host[[:space:]]*//'); do
    local host="$(echo $hostline | cut -f2 -d':')"
    if [[ "__${orig_host}" == "$host" ]]; then
      >&2 echo "Error: Tunneled host already exists"'!'
      return 1
    elif [[ "$orig_host" == "$host" ]]; then
      start_line="$(echo $hostline | cut -f1 -d':')"
      end_line=""
    elif [[ -n "$start_line" && -z "$end_line" ]]; then
      end_line="$(echo $hostline | cut -f1 -d':')"
    fi
  done
  if [[ -z "$start_line" && -z "$end_line" ]]; then
      >&2 echo "Error: No config for ${orig_host} found"'!'
     return 1
  fi
  echo "Creating tunneled host based on: $orig_host (line ${start_line} -- ${end_line} in ${config_file})"
  echo "" >> $config_file
  echo "Host __${orig_host}" >> $config_file
  echo "    HostName 127.0.0.1" >> $config_file
  echo "    Port $(server_port ${orig_host})" >> $config_file
  head "-$(echo "$end_line-1" | bc)" $config_file | tail "-$(echo "$end_line-$start_line" | bc)" | grep -v "^Host[[:space:]]*\|^[[:space:]]*HostName[[:space:]]*\|^[[:space:]]*Port[[:space:]]*" >> $config_file
}

# open or close a tunnel to a specific remote host
tunnel_host() {
  if [ "$#" -lt "1" ]; then
    >&2 echo "Error: host(s) missing"'!';
    >&2 echo "USAGE: $FUNCNAME REMOTE_HOST TUNNEL_HOST|close";
    return 1;
  fi
  # get parameters
  local remote_host="$1"
  # use always the same port for one remote host?
  local lport=`server_port $remote_host`
  local open_connections="$( netstat -tlpn 2> /dev/null | grep ":$lport " | wc -l )"
  if [[ "$#" -lt "2" ]]; then
    if [[ "0" -lt "$open_connections" ]]; then
      # port not free
      >&2 echo "Open connection found (port $lport not free)"
      >&2 echo "Try closing: $FUNCNAME $remote_host close"
      return 1;
    else
      >&2 echo "Free port for the connect to $remote_host found: $lport"
      >&2 echo "Open connection using: $FUNCNAME $remote_host TUNNEL_HOST"
      return 1;
    fi
  else
    # get remote host configs
    local rhost="$(ssh -G $remote_host | grep '^hostname ' | cut -d' ' -f2)"
    local rport="$(ssh -G $remote_host | grep '^port ' | cut -d' ' -f2)"
    if [[ "$2" == "close" ]]; then
      if [[ "0" -eq "$open_connections" ]]; then
        >&2 echo "No open connection found (port $lport is free), cannot close a connection!"
        return 1
      fi

      echo "Trying to close tunnel to $remote_host from local port $lport of process $(pidgrep "ssh -f .* -L "$lport:$rhost:$rport" -N") ..."
      kill $(pidgrep "ssh -f .* -L "$lport:$rhost:$rport" -N")
    else
      if [[ "0" -lt "$open_connections" ]]; then
        >&2 echo "Open connection found (port $lport not free), try to close the connection first: $FUNCNAME $remote_host close"
        return 1
      fi
      local tunnel_host="$2"
      # open tunnel
      echo "Opening tunnel to $remote_host from local port $lport via $tunnel_host ..."
      ssh -f $tunnel_host -L "$lport:$rhost:$rport" -N || local ssh_error=1
      if [[ -n "$ssh_error" ]]; then 
        >&2 echo "Error! Unable to connect!"
        return 1
      fi
      echo "Tunnel opened!"

      # check local config:
      local configport="$(ssh -G __${remote_host} | grep '^port ' | cut -d' ' -f2)"
      if [[ "$configport" != "$lport" && "$configport" == "22" ]]; then
        echo "Invalid tunneled host config for __${remote_host}! Trying to fix the issue ..."
        add_tunneled_host $remote_host
      fi
      configport="$(ssh -G __${remote_host} | grep '^port ' | cut -d' ' -f2)"
      if [[ "$configport" == "$lport" ]]; then
        echo "Tunneled connection enabled via host: __${remote_host}"
      else
        >&2 echo "Error! Please try to update tunneled host config __${remote_host} from port $configport to $lport (see ssh config)"
        return 1
      fi
    fi
  fi
}
_tunnel_host() { cur="${COMP_WORDS[COMP_CWORD]}"; if [ -f "$HOME/.ssh/config" ] ; then if [ "$COMP_CWORD" -lt "2" ]; then COMPREPLY=($(compgen -W "$(awk '$1=="Host" { print $2 }' $HOME/.ssh/config)" -- ${cur}) ); elif [ "$COMP_CWORD" -lt "3" ]; then COMPREPLY=($(compgen -W "close $(awk '$1=="Host" { print $2 }' $HOME/.ssh/config)" -- ${cur}) );  fi; fi; return 0; }
complete -F _tunnel_host tunnel_host

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
_tunnel_ssh() { cur="${COMP_WORDS[COMP_CWORD]}"; if [ -f "$HOME/.ssh/config" ] ; then if [ "$COMP_CWORD" -lt "2" ]; then COMPREPLY=($(compgen -W "$(awk '$1=="Host" { print $2 }' $HOME/.ssh/config)" -- ${cur}) ); elif [ "$COMP_CWORD" -lt "3" ]; then COMPREPLY=($(compgen -W "$(awk '$1=="Host" { print $2 }' $HOME/.ssh/config)" -- ${cur}) ); fi; fi; return 0; }
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
    ssh -f -N -L "$port:localhost:$port" $host
  fi
}
_tunnel_port() { cur="${COMP_WORDS[COMP_CWORD]}"; if [ -f "$HOME/.ssh/config" ] ; then if [ "$COMP_CWORD" -eq "2" ]; then COMPREPLY=($(compgen -W "$(awk '$1=="Host" { print $2 }' $HOME/.ssh/config)" -- ${cur}) ); fi; fi; return 0; }
complete -F _tunnel_port tunnel_port

