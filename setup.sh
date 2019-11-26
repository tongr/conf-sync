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


#
# install software packages
#
answer=$(yes_no "Do you want to install various software packages?")
if [ "y" == "$answer" ]; then
  python $ROOT_DIR/configure.py
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

echo "Setup finished!"

answer=$(yes_no "Do you want to activate the new shell environment?")
if [ "y" == "$answer" ]; then
  exec $SHELL -l
fi
