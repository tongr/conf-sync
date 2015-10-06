#! /bin/bash
set -e
echo "Running install script ..."

# repository set up
# set default repo to:
REPO="https://github.com/conf-sync/conf-sync.git"
if [ ! -z $1 ]
then
  echo "setting repository URL to $1"
  REPO=$1
elif [ ! -z $REPO ]
then
  read -p "Enter the repository URL (default: $REPO): " input
  REPO=${input:-$REPO}
else
  while [ -z $REPO ]
  do
    read -p "Enter the repository URL:" REPO
  done
fi


# output folder
# set default folder to:
FOLDER="$(pwd)/conf-sync"
if [ ! -z $2 ]
then
  echo "setting script folder to $2"
  FOLDER=$2
elif [ ! -z $FOLDER ]
then
  read -p "Enter the script folder (default: $FOLDER): " input
  FOLDER=${input:-$FOLDER}
else
  while [ -z $FOLDER ]
  do
    read -p "Enter the script folder:" FOLDER
  done
fi
#realpath
FOLDER="${FOLDER/#\~/$HOME}"
FOLDER="$(mkdir -p $FOLDER;cd $FOLDER;pwd)"

if [ -z "$( git --version 2> /dev/null )" ]
then
  echo "No git version found! Tying to instal git ..."
  if [ ! -z "$( apt-get )" ]
  then
    # APT system
    sudo apt-get install git
  elif [ ! -z "$( yum )" ]
  then
    # RPM version
    sudo apt-get install git
  fi
else
  echo "Using $( git --version ) ...	"
fi

echo "Checking out repository $REPO to $FOLDER ..."
# TODO select checkout dir
git clone $REPO $FOLDER

chmod u+x $FOLDER/setup.sh
. $FOLDER/setup.sh
