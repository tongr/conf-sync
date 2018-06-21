#! /bin/bash
set -e
ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SH_SCRIPT_DIR="$ROOT_DIR/shell_scripts"
LN_DIR="$ROOT_DIR/links"
INSTALL_SCRIPT_DIR="$ROOT_DIR/install"
COMMENT="# executing synchronized script"

#
# util functions
#
yes_no () {
  MSG="$1"
  RESULT=""
  while [ "y" != "$RESULT" -a "n" != "$RESULT" ]; do
    read -p "$MSG: " input
    RESULT=${input:-$DEFAULT}
  done
  echo "$RESULT"
}

# install oh-my-zsh
answer=$(yes_no "Do you want to install zsh & oh-my-zsh?")
if [ "y" == "$answer" ]; then
  echo "Checking zsh installation ..."

  if [ -z "$( zsh --version 2> /dev/null )" ]
  then
    echo "No zsh version found! Trying to install zsh ..."
    answer=$(yes_no "Do you have sudo permissions to install software?")
    if [ "y" == "$answer" ]; then
      if [ -n "$( apt-get --version 2> /dev/null )" ]
      then
        # APT system
        sudo apt-get install zsh wget
      elif [ -n "$( yum --version 2> /dev/null )" ]
      then
        # RPM version
        sudo yum install zsh wget
      fi
    else
      mkdir -p "$HOME/opt/zsh" && \
      ( wget "http://www.zsh.org/pub/zsh.tar.gz" -O "$HOME/opt/zsh.tar.gz" || curl -o "$HOME/opt/zsh.tar.gz" "http://www.zsh.org/pub/zsh.tar.gz" ) && \
      tar -xvzf "$HOME/opt/zsh.tar.gz" -C "$HOME/opt/zsh" --strip-components 1
      bash -c "cd $HOME/opt/zsh/ && ./configure --bindir=\"$HOME/opt/zsh/bin\" && make && make install.bin"
      chsh -s "$HOME/opt/zsh/bin/zsh"
    fi
  fi
  echo "Using $( zsh --version ) ..."
  sudo usermod --shell $(which zsh) "$USER" || \
  sudo chsh -s $(which zsh)

  echo "Installing oh-my-zsh ..."
  omzs_url='https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh'
  sh -c "$(wget $omzs_url -O - 2>/dev/null | sed 's|if hash chsh|if false|' | sed 's|env zsh|#env zsh|' || curl -fsSL $omzs_url | sed 's|if hash chsh|if false|' | sed 's|env zsh|#env zsh|' )" || \
    (echo "... oh-my-zsh setup finished!")
fi

echo "Setting up synchronized scripts from $SCRIPT_DIR ..."

#
# setup symbolic links
#
answer=$(yes_no "Do you want to install config links?")
if [ "y" == "$answer" ]; then
  line_nr=0
  lines="$(sed -n '$=' $LN_DIR/sync.conf)"
  while [ $line_nr -lt $lines ]; do
    line_nr=$((line_nr + 1))
    line="$(sed -n ${line_nr}p $LN_DIR/sync.conf)"
    if [[ $line == \#* ]] ; then
      continue
    fi
    KV=(${line//=/ })
    SOURCE="$LN_DIR/${KV[0]}"
    DESTINATION="${KV[1]/#\~/$HOME}"
    DESTINATION="$(mkdir -p $DESTINATION;cd $DESTINATION;pwd)"
    for SCRIPT in $(ls -a "$SOURCE"); do
      if [ ! -d "${SCRIPT}" ];then
        if [ -e "$DESTINATION/$SCRIPT" ]; then
          if [[ ! -L "$DESTINATION/$SCRIPT" || "$(readlink $DESTINATION/$SCRIPT)" != "$SOURCE/$SCRIPT" ]]; then
            answer=$(yes_no "Do you want to overwrite the existing file $DESTINATION/$SCRIPT with $SOURCE/$SCRIPT?")
            if [ "y" = "$answer" ]; then
              rm "$DESTINATION/$SCRIPT"
              ln -s "$SOURCE/$SCRIPT" "$DESTINATION/$SCRIPT"
            fi
          fi
        else
          ln -s "$SOURCE/$SCRIPT" "$DESTINATION/$SCRIPT"
        fi
      fi
    done
  done
fi

#
# setup shell scripts
#
answer=$(yes_no "Do you want to install shell sources?")
if [ "y" == "$answer" ]; then
  if [ -e "$HOME/.zshrc" ] ; then
    # postpone the loading of oh-my-zsh in favor of the settings found in the custom .zshrc
    sed -i 's|^source \$\(ZSH/oh-my-zsh.sh\)$|#\1|' "$HOME/.zshrc"
  fi
  IFS=' ' read -a cfgs <<< $(grep -vE "^\s*#.*$" "$SH_SCRIPT_DIR/sync.conf")
  for i in "${cfgs[@]}"; do
    KV=(${i//=/ })
    SOURCE="$SH_SCRIPT_DIR/${KV[0]}"
    DESTINATION="${KV[1]/#\~/$HOME}"
    DESTINATION="$(mkdir -p $DESTINATION;cd $DESTINATION;pwd)"
    for SCRIPT in $(ls -a "$SOURCE"); do
      CALL_LINE="source $SOURCE/$SCRIPT"
      if [ ! -d "${SCRIPT}" ]; then
        if [ ! -e "$DESTINATION/$SCRIPT" ]; then
          answer=$(yes_no "Destination $DESTINATION/$SCRIPT for source script $SOURCE/$SCRIPT does not exist. Do you want to create the destination?")
          if [ "y" = "$answer" ]; then
            echo -e "\n$COMMENT\n$CALL_LINE\n" > "$DESTINATION/$SCRIPT"
          fi
        elif ! grep -q "$CALL_LINE" "$DESTINATION/$SCRIPT"; then
          echo -e "\n$COMMENT\n$CALL_LINE\n" >> "$DESTINATION/$SCRIPT"
        fi
      fi
    done
  done
fi

#
# system dependent installers
#
answer=$(yes_no "Do you want to install additional software utilities?")
if [ "y" == "$answer" ]; then
  if [ "y" == "$(yes_no 'Do you want to use the Ubuntu Desktop script?')" ]; then
    bash "${INSTALL_SCRIPT_DIR}/ubuntu-desktop.sh"
  fi
  if [ "y" == "$(yes_no 'Do you want to use the Ubuntu development script?')" ]; then
    bash "${INSTALL_SCRIPT_DIR}/ubuntu-dev.sh"
  fi
fi

echo "Setup finished!"

answer=$(yes_no "Do you want to activate the new cofiguration (su -)?")
if [ "y" == "$answer" ]; then
  sudo su - || su -
fi
