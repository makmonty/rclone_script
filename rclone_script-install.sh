#!/bin/bash

# global variables
repo="https://github.com/makmonty/rclone_script.git"
installPath=~/scripts/rclone_script
setupScript=${installPath}/rclone_script-setup.sh

if ! command -v git &> /dev/null
then
	sudo apt-get install git
fi

git clone ${repo} ${installPath}

$setupScript