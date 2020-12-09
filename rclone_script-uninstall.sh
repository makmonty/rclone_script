#!/bin/bash

currDir=`realpath $(dirname $0)`

# include common helpers file
source ${currDir}/rclone_script-common.sh
source ${currDir}/rclone_script.ini

backtitle="RCLONE_SCRIPT uninstaller (https://github.com/Jandalf81/rclone_script)"
logfile=${currDir}/rclone_script-uninstall.log
logLevel=2

oldRemote=""


##################
# WELCOME DIALOG #
##################
dialog \
	--stdout \
	--backtitle "${backtitle}" \
	--title "Welcome" \
	--colors \
	--no-collapse \
	--cr-wrap \
	--yesno \
		"\nThis script will ${RED}uninstall RCLONE_SCRIPT${NORMAL}. If you do this, your savefiles will no longer be synchronized! All changes made by RCLONE_SCRIPT installer will be reverted. This includes removal of RCLONE, PNGVIEW and IMAGEMAGICK. Also, all configuration changes will be undone. Your local savefiles and savestates will be moved to the ROMS directory again.\nYour remote savefiles and statefiles will ${YELLOW}not${NORMAL} be removed.\n\nAre you sure you wish to continue?" \
	20 90 2>&1 > /dev/tty \
    || exit
	

####################
# DIALOG FUNCTIONS #
####################


# Build progress from array $STEPS()
# INPUT
#	$steps()
# OUTPUT
#	$progress
function buildProgress ()
{
	progress=""
	
	for ((i=0; i<=${#steps[*]}; i++))
	do
		progress="${progress}${steps[i]}\n"
	done
}

# Show Progress dialog
# INPUT
#	1 > Percentage to show in dialog
#	$backtitle
#	$progress
function dialogShowProgress ()
{
	local percent="$1"
	
	buildProgress
	
	clear
	clear
	
	echo "${percent}" | dialog \
		--stdout \
		--colors \
		--no-collapse \
		--cr-wrap \
		--backtitle "${backtitle}" \
		--title "Uninstaller" \
		--gauge "${progress}" 36 90 0 \
		2>&1 > /dev/tty
		
	sleep 1
}


##################
# STEP FUNCTIONS #
##################

# Initialize array $STEPS()
# OUTPUT
#	$steps()
function initSteps ()
{
	steps[1]="1. RCLONE"
	steps[2]="	1a. Remove RCLONE configuration			[ waiting...  ]"
	steps[3]="	1b. Remove RCLONE binary			[ waiting...  ]"
	steps[4]="2. PNGVIEW"
	steps[5]="	2a. Remove PNGVIEW binary			[ waiting...  ]"
	steps[6]="3. IMAGEMAGICK"
	steps[7]="	3a. apt-get remove IMAGEMAGICK			[ waiting...  ]"
	steps[8]="4. RCLONE_SCRIPT"
	steps[9]="	4a. Remove RCLONE_SCRIPT files			[ waiting...  ]"
	steps[10]="	4b. Remove RCLONE_SCRIPT menu item		[ waiting...  ]"
	steps[11]="5. RUNCOMMAND"
	steps[12]="	5a. Remove call from RUNCOMMAND-ONSTART		[ waiting...  ]"
	steps[13]="	5b. Remove call from RUNCOMMAND-ONEND		[ waiting...  ]"
	steps[14]="6. Local SAVEFILE directory"
	steps[15]="	6a. Move savefiles to default			[ waiting...  ]"
	steps[16]="	6b. Remove local SAVEFILE directory		[ waiting...  ]"
	steps[17]="7. Configure RETROARCH"
	steps[18]="	7a. Reset local SAVEFILE directories		[ waiting...  ]"
	steps[19]="8 Finalizing"
	steps[20]="	8a. Remove UNINSTALL script			[ waiting...  ]"
}

# Update item of $STEPS() and show updated progress dialog
# INPUT
#	1 > Number of step to update
#	2 > New status for step
#	3 > Percentage to show in progress dialog
#	$steps()
# OUTPUT
#	$steps()
function updateStep ()
{
	local step="$1"
	local newStatus="$2"
	local percent="$3"
	local oldline
	local newline
	
	# translate and colorize $NEWSTATUS
	case "${newStatus}" in
		"waiting")     newStatus="[ ${NORMAL}WAITING...${NORMAL}  ]"  ;;
		"in progress") newStatus="[ ${NORMAL}IN PROGRESS${NORMAL} ]"  ;;
		"done")        newStatus="[ ${GREEN}DONE${NORMAL}        ]"  ;;
		"found")       newStatus="[ ${GREEN}FOUND${NORMAL}       ]"  ;;
		"not found")   newStatus="[ ${RED}NOT FOUND${NORMAL}   ]"  ;;
		"created")     newStatus="[ ${GREEN}CREATED${NORMAL}     ]"  ;;
		"failed")      newStatus="[ ${RED}FAILED${NORMAL}      ]"  ;;
		"skipped")     newStatus="[ ${YELLOW}SKIPPED${NORMAL}     ]"  ;;
		*)             newStatus="[ ${RED}UNDEFINED${NORMAL}   ]"  ;;
	esac
	
	# search $STEP in $STEPS
	for ((i=0; i<${#steps[*]}; i++))
	do
		if [[ ${steps[i]} =~ .*$step.* ]]
		then
			# update $STEP with $NEWSTATUS
			oldline="${steps[i]}"
			oldline="${oldline%%[*}"
			newline="${oldline}${newStatus}"
			steps[i]="${newline}"
			
			break
		fi
	done
	
	# show progress dialog
	dialogShowProgress ${percent}
}

# Show summary dialog
function dialogShowSummary ()
{
	dialog \
		--backtitle "${backtitle}" \
		--title "Summary" \
		--colors \
		--no-collapse \
		--cr-wrap \
		--yesno \
			"\n${GREEN}All done!${NORMAL}\n\nRCLONE_SCRIPT and its components have been removed. From now on, your saves and states will ${RED}NOT${NORMAL} be synchronized any longer. Your local savefiles have been moved to their default directories (inside each ROMS directory). Your remote files on\n	${YELLOW}${oldRemote}${NORMAL}\nhave ${GREEN}NOT${NORMAL} been removed.\n\nTo finish the uninstaller you should reboot your RetroPie now.\n\n${RED}Reboot RetroPie now?${NORMAL}" 25 90
	
	case $? in
		0) sudo shutdown -r now  ;;
	esac
}

#########################
# UNINSTALLER FUNCTIONS #
#########################

# Uninstaller
function uninstaller ()
{
	initSteps
	dialogShowProgress 0
	
	saveRemote
	
	1RCLONE
	2PNGVIEW
	3IMAGEMAGICK
	4RCLONE_SCRIPT
	5RUNCOMMAND
	6LocalSAVEFILEDirectory
	7RetroArch
	8Finalize
	
	dialogShowSummary
}

function saveRemote ()
{
	# list all remotes and their type
	remotes=$(rclone listremotes -l)
	
	# get line with RETROPIE remote
	retval=$(grep -i "^retropie:" <<< ${remotes})

	remoteType="${retval#*:}"
	remoteType=$(echo ${remoteType} | xargs)
	
	oldRemote="retropie:${remotebasedir} (${remoteType})"
}

function 1RCLONE ()
{
	log 2 "START"
	
# 1a. Remove RCLONE configuration
	updateStep "1a" "in progress" 0
	
	if [ -d ~/.config/rclone ]
	then
		{ #try
			sudo rm -r ~/.config/rclone >> "${logfile}" &&
			log 2 "DONE" &&
			updateStep "1a" "done" 8
		} || { #catch
			log 0 "ERROR" &&
			updateStep "1a" "failed" 0 &&
			exit
		}
	else
		log 2 "NOT FOUND"
		updateStep "1a" "not found" 8
	fi
	
# 1b. Remove RCLONE binary
	log 2 "START"
	updateStep "1b" "in progress" 8
	
	if [ -f /usr/bin/rclone ]
	then
		{ #try
			sudo rm /usr/bin/rclone >> "${logfile}" &&
			log 2 "DONE" &&
			updateStep "1b" "done" 16
		} || { #catch
			log 0 "ERROR" &&
			updateStep "1b" "failed" 8 &&
			exit
		}
	else
		log 2 "NOT FOUND"
		updateStep "1b" "not found" 16
	fi
	
	log 2 "END"
}

function 2PNGVIEW ()
{
	log 2 "START"
	
# 2a. Remove PNGVIEW binary
	log 2 "START"
	updateStep "2a" "in progress" 16
	
	if [ -f /usr/bin/pngview ]
	then
		{ #try
			sudo rm /usr/bin/pngview >> "${logfile}" &&
			sudo rm /usr/lib/libraspidmx.so.1 >> "${logfile}" &&
			log 2 "DONE" &&
			updateStep "2a" "done" 24
		} || { # catch
			log 0 "ERROR" &&
			updateStep "2a" "failed" 16 &&
			exit
		}
	else
		log 2 "NOT FOUND" &&
		updateStep "2a" "not found" 24
	fi
	
	log 2 "DONE"
}

function 3IMAGEMAGICK ()
{
	log 2 "START"
	
# 3a. Remove IMAGEMAGICK binary
	log 2 "START"
	updateStep "3a" "in progress" 24
	
	if [ -f /usr/bin/convert ]
	then
		{ # try
			sudo apt-get --yes remove imagemagick* >> "${logfile}" &&
			log 2 "DONE" &&
			updateStep "3a" "done" 32
		} || { # catch
			log 0 "ERROR" &&
			updateStep "3a" "failed" 24 &&
			exit
		}
	else
		log 2 "NOT FOUND"
		updateStep "3a" "not found" 32
	fi
	
	log 2 "DONE"
}

function 4RCLONE_SCRIPT ()
{
	log 2 "START"

# 4a. Remove RCLONE_SCRIPT
	log 2 "START"
	updateStep "4a" "in progress" 32
	
	if [ -f ${currDir}/rclone_script.sh ]
	then
		{ # try
			sudo rm -f ${currDir}/rclone_script-install.* >> "${logfile}" &&
			sudo rm -f ${currDir}/rclone_script.* >> "${logfile}" &&
			log 2 "DONE" &&
			updateStep "4a" "done" 40
		} || { # catch
			log 0 "ERROR" &&
			updateStep "4a" "failed" 32 &&
			exit
		}
	else
		log 2 "NOT FOUND"
		updateStep "4a" "not found" 40
	fi
	
# 4b. Remove RCLONE_SCRIPT menu item
	log 2 "START"
	updateStep "4b" "in progress" 40
	
	local found=0
		
	if [[ $(xmlstarlet sel -t -v "count(/gameList/game[path='./rclone_script-redirect.sh.sh'])" ~/.emulationstation/gamelists/retropie/gamelist.xml) -ne 0 ]]
	then
		found=$(($found + 1))
		
		log 2 "FOUND"
		
		xmlstarlet ed \
			--inplace \
			--delete "//game[path='./rclone_script-redirect.sh']" \
			~/.emulationstation/gamelists/retropie/gamelist.xml
			
		log 2 "REMOVED"
	else
		log 2 "NOT FOUND"
	fi
	
	if [ -f ~/RetroPie/retropiemenu/rclone_script-redirect.sh ]
	then
		found=$(($found + 1))
		
		log 2 "FOUND"
		
		sudo rm ~/RetroPie/retropiemenu/rclone_script-redirect.sh >> "${logfile}"
		sudo rm ${currDir}/rclone_script-menu.sh >> "${logfile}"
		
		log 2 "REMOVED"
	else
		log 2 "NOT FOUND"
	fi
	
	case $found in
		0) updateStep "4b" "not found" 48  ;;
		1) updateStep "4b" "done" 48  ;;
		2) updateStep "4b" "done" 48  ;;
	esac
	
	log 2 "DONE"
}

function 5RUNCOMMAND ()
{
	log 2 "START"
	
# 5a. Remove call from RUNCOMMAND-ONSTART
	log 2 "START"
	updateStep "5a" "in progress" 48
	
	if [[ $(grep -c "${currDir}/rclone_script.sh" /opt/retropie/configs/all/runcommand-onstart.sh) -gt 0 ]]
	then
	{ #try
		sed -i "/~\/scripts\/rclone_script\/rclone_script.sh /d" /opt/retropie/configs/all/runcommand-onstart.sh &&
		log 2 "DONE" &&
		updateStep "5a" "done" 56
	} || { # catch
		log 0 "ERROR" &&
		updateStep "5a" "failed" 48
	}
	else
		log 2 "NOT FOUND"
		updateStep "5a" "not found" 56
	fi
	
# 5b. Remove call from RUNCOMMAND-ONEND
	log 2 "START"
	updateStep "5b" "in progress" 56
	
	if [[ $(grep -c "${currDir}/rclone_script.sh" /opt/retropie/configs/all/runcommand-onend.sh) -gt 0 ]]
	then
		{ #try
			sed -i "/~\/scripts\/rclone_script\/rclone_script.sh /d" /opt/retropie/configs/all/runcommand-onend.sh &&
			log 2 "DONE" &&
			updateStep "5b" "done" 64
		} || { # catch
			log 0 "ERROR" &&
			updateStep "5b" "failed" 56
		}
	else
		log 2 "NOT FOUND"
		updateStep "5b" "not found" 64
	fi
	
	log 2 "DONE"
}

function 6LocalSAVEFILEDirectory ()
{
	log 2 "START"
	
# 6a. Move savefiles to default
	log 2 "START"
	updateStep "6a" "in progress" 64
	
	if [ -d ~/RetroPie/saves ]
	then
		# start copy task in background, pipe numbered output into COPY.TXT and to LOGFILE
		$(cp -v -r ~/RetroPie/saves/* ~/RetroPie/roms | cat -n | tee copy.txt | cat >> "${logfile}") &
		
		# show content of COPY.TXT
		dialog \
			--backtitle "${backtitle}" \
			--title "Copying savefiles to default..." \
				--colors \
			--no-collapse \
			--cr-wrap \
			--tailbox copy.txt 40 120
			
		wait
		
		rm copy.txt
		
		updateStep "6a" "done" 72
	else
		log 2 "NOT FOUND"
		updateStep "6a" "not found" 72
	fi
	
# 6b. Remove local SAVEFILE directory
	log 2 "START"
	updateStep "6b" "in progress" 72
	
	if [ -d ~/RetroPie/saves ]
	then
		# start remove task in background, pipe numbered output into DELETE.TXT and to LOGFILE
		$(sudo rm --recursive --force --verbose ~/RetroPie/saves | cat -n | tee delete.txt | cat >> "${logfile}") &
		
		# show content of REMOVE.TXT
		dialog \
			--backtitle "${backtitle}" \
			--title "Removing savefiles from local base dir..." \
			--colors \
			--no-collapse \
			--cr-wrap \
			--tailbox delete.txt 40 120
			
		wait
		
		rm delete.txt
		
		# check if that directory is shared
		local retval=$(grep -n "\[saves\]" /etc/samba/smb.conf)
		if [ "${retval}" != "" ]
		then
			# extract line numbers
			local lnStart="${retval%%:*}"
			local lnEnd=$(( $lnStart + 7 ))
			
			# remove network share
			sudo sed -i -e "${lnStart},${lnEnd}d" /etc/samba/smb.conf
			
			# restart SAMBA service
			sudo service smbd restart
			
			log 2 "REMOVED network share"
		fi	

		
		log 2 "DONE"
		updateStep "6b" "done" 80
	else
		log 2 "NOT FOUND"
		updateStep "6b" "skipped" 80
	fi
	
	log 2 "DONE"
}

function 7RetroArch ()
{
	log 2 "START"

# 7a. Reset local SAVEFILE directories
	log 2 "START"
	updateStep "7a" "in progress" 80
	
	local found=0
	
	# for each directory...
	for directory in /opt/retropie/configs/*
	do
		system="${directory##*/}"
		
		# skip system "all"
		if [ "${system}" == "all" ]
		then
			continue
		fi
		
		# check if there'a system specific RETROARCH.CFG
		if [ -f "${directory}/retroarch.cfg" ]
		then
			log 2 "FOUND retroarch.cfg for ${system}"
			
			# check if RETROARCH.CFG contains SAVEFILE pointing to ~/RetroPie/saves/<SYSTEM>
			if fileHasKeyWithValue "savefile_directory" "~/RetroPie/saves/${system}" "${directory}/retroarch.cfg";
			then
				log 2 "FOUND savefile_directory"
				found=$(($found + 1))
				# replace parameter
				setKeyValueInFile "savefile_directory" "default" "${directory}/retroarch.cfg"
				log 2 "REPLACED savefile_directory"
			else
				log 2 "NOT FOUND savefile_directory"
			fi
			
			# check if RETROARCH.CFG contains SAVESTATE pointing to ~/RetroPie/saves/<SYSTEM>
			if fileHasKeyWithValue "savestate_directory" "~/RetroPie/saves/${system}" "${directory}/retroarch.cfg";
			then
				log 2 "FOUND savestate_directory"
				found=$(($found + 1))
				# replace parameter
				setKeyValueInFile "savestate_directory" "default" "${directory}/retroarch.cfg"
				log 2 "REPLACED savestate_directory"
			else
				log 2 "NOT FOUND savestate_directory"
			fi
		fi
	done

	log 2 "DINE"
	if [[ $found -eq 0 ]]
	then
		updateStep "7a" "not found" 88
	else
		updateStep "7a" "done" 88
	fi

	log 2 "DONE"
}

function 8Finalize ()
{
	log 2 "START"

# 8a. Remove UNINSTALL script
	log 2 "START"
	updateStep "8a" "in progress" 88
	
	log 2 "DONE"
	updateStep "8a" "done" 100
	
	log 2 "DONE"
	
	# move LOGFILE to HOME
	mv ${currDir}/rclone_script-uninstall.log ~
	
	# remove RCLONE_SCRIPT directory
	rm -rf ${currDir}
}


########
# MAIN #
########

uninstaller