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
        chsh -s $(which zsh)
      elif [ -n "$( yum --version 2> /dev/null )" ]
      then
        # RPM version
        sudo yum install zsh wget
        chsh -s $(which zsh)
      fi
    else
      mkdir -p "$HOME/opt/zsh" && \
      ( wget "http://www.zsh.org/pub/zsh.tar.gz" -O "$HOME/opt/zsh.tar.gz" || curl -o "$HOME/opt/zsh.tar.gz" "http://www.zsh.org/pub/zsh.tar.gz" ) && \
      tar -xvzf "$HOME/opt/zsh.tar.gz" -C "$HOME/opt/zsh" --strip-components 1
      bash -c "cd $HOME/opt/zsh/ && ./configure --bindir=\"$HOME/opt/zsh/bin\" && make && make install.bin"
      chsh -s "$HOME/opt/zsh/bin/zsh"
    fi
  fi
  echo "Using $( zsh --version ) ...    "

  echo "Installing oh-my-zsh ..."
  sh -c "$(wget https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -  2>/dev/null || curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

  echo "done!"
fi

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
  echo "Installing bash Git prompt ..."
  if [ ! -d "$HOME/opt/bash-git-prompt" ] ; then
    mkdir -p "$HOME/opt"
    git clone https://github.com/magicmonty/bash-git-prompt.git "$HOME/opt/bash-git-prompt" --depth=1
  fi
  echo "done!"
}
# install bash-it
function install-bash-it() {
  echo "Installing bash-it ..."
  if [ ! -d "$HOME/bash-git-prompt" ] ; then
    mkdir -p "$HOME/opt"
    if [ ! -d "$HOME/opt/.bash_it" ];then
      git clone --depth=1 https://github.com/Bash-it/bash-it.git "$HOME/opt/.bash_it"
    fi
    if grep -q '^source "$BASH_IT"/bash_it.sh$' ~/.bashrc; then
      echo "It seems the .bashrc file is already configured for bash-it." # You dont have to append bash-it templates at the end of .bashrc ...
      answer=$(yes_no "Do you want to keep the existing configuration of bash-it?")
      if [ "y" == "$answer" ]; then
        bash "$HOME/opt/.bash_it/install.sh" "--no-modify-config"
      else
        bash "$HOME/opt/.bash_it/install.sh"
        echo 'Setting up plugins and extension ...'
        if grep -q "^export BASH_IT_THEME='nwinkler'$" ~/.bashrc; then
          echo "'nwinkler'-theme already selected ..."
        else
          sed -i "s|^\(export BASH_IT_THEME=.*\)$|#\1\nexport BASH_IT_THEME='nwinkler'|" ~/.bashrc
        fi
      fi
    fi
    (bash "$HOME/opt/.bash_it/bash_it.sh" enable completion todo tmux ssh pip pip3 maven git_flow git_flow_avh git docker 'export' dirs conda awscli)
    # additional completions: (bash "$HOME/opt/.bash_it/bash_it.sh" enable virtualbox svn npm makefile)
    (bash "$HOME/opt/.bash_it/bash_it.sh" enable plugin xterm z_autoenv todo tmux tmuxinator ssh sshagent java history git extract explain docker dirs browser boot2docker battery aws autojump python)
    # additional plugins: (bash "$HOME/opt/.bash_it/bash_it.sh" enable plugin subversion node nvm nginx)
    (bash "$HOME/opt/.bash_it/bash_it.sh" enable alias git todo.txt-cli vagrant curl clipboard apt tmux systemd)

    answer=$(yes_no "Do you want to try installing fasd?")
    if [ "y" == "$answer" ]; then
      sudo -- bash -c 'add-apt-repository ppa:aacebedo/fasd; apt-get update; apt-get install fasd'
      (bash "$HOME/opt/.bash_it/bash_it.sh" enable plugin fasd)
    fi
  fi
  echo "done!"
}
answer=$(yes_no "Do you want to install additional software utilities?")
if [ "y" == "$answer" ]; then
  answer=$(yes_no "Do you want to install git-latexdiff?")
  if [ "y" == "$answer" ]; then
    install-git-latexdiff
  fi

  if [ -n "$(echo $ZSH)" ]; then
    echo "oh-my-zsh found ..."
  fi
  answer=$(yes_no "Do you want to install bash-it?")
  if [ "y" == "$answer" ]; then
    install-bash-it
    # uninstall 'old' bash-git-prompt installations
    if [ -e "$HOME/opt/bash-git-prompt/gitprompt.sh" ] ; then
      mkdir -p "$HOME/opt/trash"
      rm -rf "$HOME/opt/trash/bash-git-prompt"
      mv "$HOME/opt/bash-git-prompt" "$HOME/opt/trash/"
    fi
  else
    # bash git prompt is contained in bash-it
    answer=$(yes_no "Do you want to install bash-git-prompt?")
    if [ "y" == "$answer" ]; then
      install-bash-git-prompt
    fi
  fi
fi

echo "Setup finished!"

answer=$(yes_no "Do you want to activate the new cofiguration (exec bash)?")
if [ "y" == "$answer" ]; then
  exec bash
fi
