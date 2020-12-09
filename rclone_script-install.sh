#!/bin/bash

# global variables
repo="makmonty/rclone_script"
url="https://raw.githubusercontent.com/${repo}"
branch="master"
path=~/scripts/rclone_script

if ! command -v git &> /dev/null
then
	sudo apt-get install git
fi

git clone https://github.com/${repo}.git ${path}

{$path}/rclone_script-install.sh