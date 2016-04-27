#! /bin/bash
set -e
ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SH_SCRIPT_DIR="$ROOT_DIR/shell_scripts"
LN_DIR="$ROOT_DIR/links"
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

echo "Setting up synchronized scripts from $SCRIPT_DIR ..."

#
# setup symbolic links
#
answer=$(yes_no "Do you want to install config links?")
if [ "y" == "$answer" ]; then
  IFS=' ' read -a cfgs <<< $(grep -vE "^\s*#.*$" "$LN_DIR/sync.conf")
  for i in "${cfgs[@]}"; do
    KV=(${i//=/ })
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
# setup shell scripts
#
# install git-latexdiff
install-git-latexdiff() {
  echo "Installing git-latexdiff ..."
  if [ ! -d "$HOME/bin/git-latexdiff" ] ; then
    if [ ! -d "$HOME/opt" ] ; then
      mkdir "$HOME/opt"
    fi
    if [ ! -d "$HOME/bin" ] ; then
     mkdir "$HOME/bin"
    fi
    cd "$HOME/opt"
    if [ ! -d "$HOME/opt/git-latexdiff" ] ; then
      git clone https://gitlab.com/git-latexdiff/git-latexdiff.git --depth=1
      # install latexdiff
      if [ ! -d "$HOME/opt/git-latexdiff/latexdiff" ] ; then
        wget -qO- -O /tmp/latexdiff.zip http://mirrors.ctan.org/support/latexdiff.zip && unzip /tmp/latexdiff.zip -d "$HOME/opt/git-latexdiff" && rm /tmp/latexdiff.zip
      fi
    fi
    if [ ! -e "$HOME/bin/latexdiff" ] ; then
      ln -s "$HOME/opt/git-latexdiff/latexdiff/latexdiff" "$HOME/bin/latexdiff"
    fi
    if [ ! -e "$HOME/bin/git-latexdiff" ] ; then
      ln -s "$HOME/opt/git-latexdiff/git-latexdiff" "$HOME/bin/git-latexdiff"
    fi
  fi
  echo "done!"
  echo "Example usage:"
  echo "git latexdiff --main .git latexdiff --main main.tex --output ./diff.pdf --bibtex HEAD~1 && evince diff.pdf"
}
# install bash-git-prompt
function install-bash-git-prompt() {
  echo "Installing git-latexdiff ..."
  if [ ! -d "$HOME/opt/bash-git-prompt" ] ; then
    mkdir -p "$HOME/opt"
    git clone https://github.com/magicmonty/bash-git-prompt.git "$HOME/opt/bash-git-prompt" --depth=1
  fi
  echo "done!"
}
answer=$(yes_no "Do you want to install additional software utilities?")
if [ "y" == "$answer" ]; then
  answer=$(yes_no "Do you want to install git-latexdiff?")
  install-git-latexdiff
  answer=$(yes_no "Do you want to install bash-git-prompt?")
  install-bash-git-prompt
fi

echo "Setup finished!"
