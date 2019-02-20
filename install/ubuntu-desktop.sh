#! /bin/bash
set -e


#
# Update software repositories
#
echo "Updating Ubuntu software repository ..."
sudo apt update
echo "Installing basics ..."
sudo apt install -y git htop tmux wget curl openssh-client


#
# util functions
#
yes_no () {
  MSG="$1"
  RESULT=""
  while [ "y" != "$RESULT" -a "n" != "$RESULT" ]; do
    read -p "  $MSG: " input
    RESULT=${input:-$DEFAULT}
  done
  echo "$RESULT"
}


#
# add AltGr+aous keyboard combinations to create an german special chars
#
if [ "y" == "$(yes_no 'Do you creat an US keyboard layout with Alt+A/O/U/.. combinations to create german special chars?')" ]; then
  cat | sudo tee -a /usr/share/X11/xkb/symbols/us <<- EOM

partial alphanumeric_keys
xkb_symbols "us-de" {

    // include all the definitions from us(basic), I just want to add to it

    include "us(basic)"
    name[Group1]= "English (US, with german umlauts)";

    // support euro sign (AltGr+4)

    include "eurosign(4)"

    // add german umlauts (AltGr+aous)

    key <AC01> {    [     a,    A,  adiaeresis, Adiaeresis      ]   };
    key <AD07> {    [     u,    U,  udiaeresis, Udiaeresis      ]   };
    key <AD09> {    [     o,    O,  odiaeresis, Odiaeresis      ]   };
    key <AC02> {    [     s,    S,  ssharp,     ssharp          ]   };
    key <AD03> {    [     e,    E,  EuroSign,   cent            ]   };

    // and some other keys

    key <AE11> {    [     minus,    underscore, endash, endash  ]   };
    key <AB09> {    [    period,    greater,    ellipsis,   ellipsis    ]   };
    key <AB10> {    [     slash,    question,   emdash, emdash  ]   };

    // have ALT_R as level 3 switch

    include "level3(ralt_switch)"
};
EOM

  sudo sed -i -e 's|^\(\s*<description>English (US, euro on 5)<\/description>.*\)$|\1\n</configItem>\n</variant>\n<variant>\n<configItem>\n<name>us-de</name>\n<description>English (US, with german umlauts)</description>|' /usr/share/X11/xkb/rules/evdev.xml
  sudo systemctl restart keyboard-setup.service
  echo 'You can now select "English (US, with german umlauts)" in Settings > Region & Language.'
fi


#
# create ssh key
#
if [ "y" == "$(yes_no 'Do you want to run ssh-keygen?')" ]; then
  ssh-keygen
  echo -e "new public key:\n$(cat ~/.ssh/id_rsa.pub)"
fi


#
# install Tilda/Guake
#
if [ "y" == "$(yes_no 'Do you want to install dropdown terminal Tilda?')" ]; then
  sudo apt install tilda
  mkdir -p ~/.config/autostart
  echo -e '[Desktop Entry]\nType=Application\nName=Dropdown Terminal (Guake/Tilda)\nExec=tilda\nX-GNOME-Autostart-enabled=true' > ~/.config/autostart/Terminal.desktop
elif [ "y" == "$(yes_no 'Do you want to install dropdown terminal Guake?')" ]; then
  sudo apt install guake
  mkdir -p ~/.config/autostart
  echo -e '[Desktop Entry]\nType=Application\nName=Dropdown Terminal (Guake/Tilda)\nExec=guake\nX-GNOME-Autostart-enabled=true' > ~/.config/autostart/Terminal.desktop
fi


#
# install Wavebox
#
if [ "y" == "$(yes_no 'Do you want to install Wavebox?')" ]; then
  # addadditional font types
  sudo apt install ttf-mscorefonts-installer
  # isntall
  sudo snap install wavebox
  # enable printing
  sudo snap connect wavebox:cups-control
  # setup autostart
  mkdir -p ~/.config/autostart
  echo -e '[Desktop Entry]\nType=Application\nName=Wavebox\nExec=wavebox\nX-GNOME-Autostart-enabled=true' > ~/.config/autostart/Wavebox.desktop
fi


#
# install Spotify
#
if [ "y" == "$(yes_no 'Do you want to install Spotify?')" ]; then
  sudo snap install spotify
fi


#
# install Skype
#
if [ "y" == "$(yes_no 'Do you want to install Skype?')" ]; then
  sudo snap install skype
fi


#
# install Gimp
#
if [ "y" == "$(yes_no 'Do you want to install Gimp?')" ]; then
  sudo snap install gimp
fi


#
# install Bitwarden
#
if [ "y" == "$(yes_no 'Do you want to install Bitwarden?')" ]; then
  sudo snap install bitwarden
fi


#
# install Xournal
#
if [ "y" == "$(yes_no 'Do you want to install Xournal')" ]; then
  sudo snap install xournal
fi


#
# bash extensions
#
# installer for bash-git-prompt
function install_bash_git_prompt() {
  echo "Installing bash Git prompt ..."
  if [ ! -d "$HOME/opt/bash-git-prompt" ] ; then
    mkdir -p "$HOME/opt"
    git clone https://github.com/magicmonty/bash-git-prompt.git "$HOME/opt/bash-git-prompt" --depth=1
  fi
  echo "done!"
}
# installer for bash-it
function install_bash_it() {
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
if [ "y" == "$(yes_no 'Do you want to install the bash extension bash-it?')" ]; then
   install_bash_it
elif [ "y" == "$(yes_no 'Do you want to install the bash extension git-prompt?')" ]; then
  install_bash_git_prompt
fi


#
# deactivate wireless power management permanently
#
if [ "y" == "$(yes_no 'Do you want to deactivate wireless power management?')" ]; then
  # see also: https://unix.stackexchange.com/questions/269661/how-to-turn-off-wireless-power-management-permanently
  sudo sed -i 's|wifi.powersave = [^2]|wifi.powersave = 2|' /etc/NetworkManager/conf.d/default-wifi-powersave-on.conf
fi
