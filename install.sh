#! /bin/bash
set -e
echo "Running install script ..."

read_input () {
  MSG="$1"
  DEFAULT=""
  if [[ -n $2 ]]; then
    DEFAULT=$2
    MSG="$1 (default: $DEFAULT)"
  fi
  RESULT=""
  while [[ -z $RESULT ]]; do
    read -p "$MSG: " input
    RESULT=${input:-$DEFAULT}
  done
  echo "$RESULT"
}

# repository set up
# set default repo to:
REPO="https://github.com/tongr/conf-sync.git"
if [ ! -z $1 ]
then
  echo "setting repository URL to $1"
  REPO=$1
elif [ ! -z $REPO ]
then
  REPO=$(read_input "Enter the repository URL" $REPO)
else
  while [ -z $REPO ]
  do
    REPO=$(read_input "Enter the repository URL" )
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
  FOLDER=$(read_input "Enter the script folder" $FOLDER)
else
  while [ -z $FOLDER ]
  do
    FOLDER=$(read_input "Enter the script folder")
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
git clone $REPO $FOLDER

chmod u+x $FOLDER/setup.sh
. $FOLDER/setup.sh
