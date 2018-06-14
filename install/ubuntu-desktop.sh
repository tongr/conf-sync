# create ssh key
ssh-keygen
echo -e "new public key:\n$(cat ~/.ssh/id_rsa.pub)"

# install basic software
sudo apt install htop git tmux openjdk-8-jre openjdk-8-jdk wget curl guake
sudo snap install wavebox spotify skype
sudo apt install ttf-mscorefonts-installer
mkdir -p ~/.config/autostart
echo -e '[Desktop Entry]\nType=Application\nName=Guake\nExec=guake\nX-GNOME-Autostart-enabled=true' > ~/.config/autostart/Guake.desktop

# zsh environment
mkdir -p ~/opt
bash -c "$(curl -fsSL http://git.io/va5Ka)"

# anaconda
anaconda_version="Anaconda3-5.2.0-Linux-x86_64" && wget --show-progress "https://repo.anaconda.com/archive/${anaconda_version}.sh" && bash "${anaconda_version}.sh"
echo -e '# added by Anaconda3 installer\nexport PATH="/home/tongr/anaconda3/bin:$PATH"' >> ~/.zshrc

# some more development tools
sudo apt install maven git-flow docker.io
sudo usermod -aG docker $USER
sudo snap install intellij-idea-community pycharm-community --classic
sudo snap install gitkraken
mkdir -p ~/.config/autostart
echo -e '[Desktop Entry]\nType=Application\nName=Wavebox\nExec=wavebox\nX-GNOME-Autostart-enabled=true' > ~/.config/autostart/Wavebox.desktop

# add AltGr+aous keyboard combinations to create an "Umlaut"
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

    // and some other keys

    key <AE11> {    [     minus,    underscore, endash, endash  ]   };
    key <AB09> {    [    period,    greater,    ellipsis,   ellipsis    ]   };
    key <AB10> {    [     slash,    question,   emdash, emdash  ]   };

    // have ALT_R as level 3 switch

    include "level3(ralt_switch)"
};
EOM


sudo sed -i -e 's|^\(\s*<description>English (US, euro on 5)<\/description>.*\)$|\1\n</configItem>\n</variant>\n<variant>\n<configItem>\n<name>us-de</name>\n<description>English (US, with german umlauts)</description>|' /usr/share/X11/xkb/rules/evdev.xml

# additional software
sudo snap install gimp
