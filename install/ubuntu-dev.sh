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
# create ssh key
#
if [ "y" == "$(yes_no 'Do you want to run ssh-keygen?')" ]; then
  ssh-keygen
  echo -e "new public key:\n$(cat ~/.ssh/id_rsa.pub)"
fi


#
# install Java
#
if [ "y" == "$(yes_no 'Do you want to install Java/JDK8?')" ]; then
  sudo apt install openjdk-8-jre openjdk-8-jdk openjdk-8-source
fi


#
# install Anaconda
#
if [ "y" == "$(yes_no 'Do you want to install Anaconda?')" ]; then
  anaconda_version="Anaconda3-5.2.0-Linux-x86_64"
  read -p "  Set anaconda version (default: Anaconda3-5.2.0-Linux-x86_64): " anaconda_version
  anaconda_version="${version_name:-Anaconda3-5.2.0-Linux-x86_64}"
  wget --show-progress "https://repo.anaconda.com/archive/${anaconda_version}.sh" && bash "${anaconda_version}.sh"
  if [ "y" == "$(yes_no '  Add ~/anaconda3/bin to .zshrc path?')" ]; then
    echo -e '# add Anaconda3\nexport PATH="${HOME}/anaconda3/bin:${PATH}"' >> ~/.zshrc
  fi
fi


#
# install dev tools
#
if [ "y" == "$(yes_no 'Do you want to install different dev tools (e.g., maven, git-flow, docker, ...)?')" ]; then
  sudo apt install maven git-flow docker.io
  sudo usermod -aG docker $USER
fi


#
# install Intellij
#
if [ "y" == "$(yes_no 'Do you want to install Intellij?')" ]; then
  sudo snap install intellij-idea-community --classic
fi


#
# install PyCharm
#
if [ "y" == "$(yes_no 'Do you want to install PyCharm?')" ]; then
  sudo snap install pycharm-community --classic
fi


#
# install git-cola
#
if [ "y" == "$(yes_no 'Do you want to install git-cola?')" ]; then
  sudo snap install git-cola
fi


#
# install GitKraken
#
if [ "y" == "$(yes_no 'Do you want to install GitKraken?')" ]; then
  sudo snap install gitkraken
fi
