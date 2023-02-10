#!/bin/bash

ENABLE_DEBUGGING=true
ENABLE_LOGGING=true

custom_print() {
	# $1 = type (info, error, debug, *); $2 = content
	case "$1" in
	"debug") {
		$ENABLE_DEBUGGING && printf "\e[1;33m[ DEBUG ]\e[0m %s\n" "$2" # Yellow
		$ENABLE_LOGGING && printf "\e[1;33m[ DEBUG ]\e[0m %s\n" "$2" >>log.txt
	} ;;
	"error") {
		printf "\e[1;31m[ ERROR ]\e[0m %s\n" "$2" # Red
		$ENABLE_LOGGING && printf "\e[1;31m[ ERROR ]\e[0m %s\n" "$2" >>log.txt
	} ;;
	"information") {
		printf "\e[1;34m[ INFORMATION ]\e[0m %s\n" "$2" # Blue
		$ENABLE_LOGGING && printf "\e[1;34m[ INFORMATION ]\e[0m %s\n" "$2" >>log.txt
	} ;;
	*) {
		printf "\e[1;35m[ $1 ]\e[0m %s\n" "$2" # Magenta
		$ENABLE_LOGGING && printf "\e[1;35m[ $1 ]\e[0m %s\n" "$2" >>log.txt
	} ;;
	esac
}

custom_read() {
	# $1 = type (yesno, range, *); $2 = content; $3 = lower; $4 = upper
	$ENABLE_LOGGING && printf "\e[1;32m[ INPUT ]\e[0m %s" "$2" >>log.txt

	local answer

	case "$1" in
	"yesno") {
		while true; do
			read -rp "$(echo -e "\e[1;32m[ INPUT ]\e[0m $2")" answer
			case $answer in
			[yY]) {
				answer="y"
				break
			} ;;
			[nN]) {
				answer="n"
				break
			} ;;
			esac
		done
	} ;;
	"range") {
		while true; do
			read -rp "$(echo -e "\e[1;32m[ INPUT ]\e[0m $2")" answer
			[[ $answer == ?(-)+([0-9]) ]] && (($3 <= answer)) && ((answer <= $4)) && {
				break
			}
		done
	} ;;
	*) {
		read -rp "$(echo -e "\e[1;32m[ INPUT ]\e[0m $2")" answer
	} ;;
	esac
	echo "$answer"
	$ENABLE_LOGGING && echo "$answer" >>log.txt
}

check_dependencies() {
	custom_print "debug" "Checking for missing dependencies..."
	command -v distrobox > /dev/null || { has_distrobox=false; }
	command -v curl      > /dev/null || {      has_curl=false; }
	command -v podman    > /dev/null || {    has_podman=false; }
	command -v docker    > /dev/null || {    has_docker=false; }
	custom_print "debug" "Here are the results: has_distrobox=$has_distrobox, has_curl=$has_curl, has_podman=$has_podman, has_docker:$has_docker"
}

custom_print "debug" "########## STARTING THE SCRIPT ##########"

# Checking for sudo privileges
custom_print "debug" "Checking for sudo privileges..."
[ "$(id -u)" == 0 ] || {
    custom_print "error" "Execute this script with sudo privileges."
    exit 1;
}
custom_print "debug" "I'm running as a super user"

# Checking for compatibility TODO: verify from a list of tested distros 
custom_print "debug" "Checking where I'm running..."
distribution_name="$(lsb_release -is)"
distribution_release="$(lsb_release -sr)"
custom_print "debug" "I'm running in a $distribution_name $distribution_release machine"

# Checking for missing dependencies

has_curl=true
has_podman=true
has_docker=true
has_distrobox=true

check_dependencies

# Missing dependencies prompt
( $has_distrobox && $has_curl && ( $has_podman || $has_docker ) ) || {
	missing_dependencies=""
	$has_distrobox || { missing_dependencies="${missing_dependencies} distrobox"; }
	$has_curl || {
		[ -z "$missing_dependencies" ] || missing_dependencies="${missing_dependencies},"
		missing_dependencies="${missing_dependencies} curl";
	}
	$has_podman || $has_docker || {
		[ -z "$missing_dependencies" ] || missing_dependencies="${missing_dependencies},"
		missing_dependencies="${missing_dependencies} podman, docker (optional)";
	}
	custom_print "error" "Missing dependencies:$missing_dependencies."
}



#	# Installing missing dependencies
#	$has_curl || {
#		$DEBUG && { echo -e "\e[1;33m[ Debug ]\e[0m Asking to install curl..."; };
#		while true; do
#			read -rp $'\e[1;32m[ Input ]\e[0m Install curl automatically? [y/n] ' yn
#			case $yn in
#				[yY] )
#					has_curl=true
#					echo -e "\e[1;34m[  Log  ]\e[0m Installing curl, it may take a while.";
#					if [[ $os_distro_name =~ ^(Ubuntu|Lubuntu|Xubuntu|Debian)$ ]]
#					then
#    						sudo apt update -y &> /dev/null
#    						sudo apt install curl -y &> /dev/null
#					fi
#					if [[ $os_distro_name =~ ^(Fedora)$ ]]
#					then
#    						sudo dnf update -y &> /dev/null
#    						sudo dnf install curl -y &> /dev/null
#					fi
#					command -v curl > /dev/null || { has_curl=false; }
#					$has_curl || {
#						echo -e "\e[1;31m[ Error ]\e[0m Unable to install curl. Install it manually and run this script again.";
#						exit 1;
#					}
#					break;;
#				[nN]   )
#					echo -e "\e[1;34m[  Log  ]\e[0m Installing curl is required. Install it manually and run this script again.";
#					exit 0;;
#				* )
#			esac
#
#		done
#	};
#	$has_distrobox || {
#		$DEBUG && { echo -e "\e[1;33m[ Debug ]\e[0m Asking to install distrobox..."; };
#		while true; do
#			read -rp $'\e[1;32m[ Input ]\e[0m Install distrobox automatically? [y/n] ' yn
#			case $yn in
#				[yY] )
#					has_distrobox=true
#					echo -e "\e[1;34m[  Log  ]\e[0m Installing distrobox, it may take a while.";
#					curl -s https://raw.githubusercontent.com/89luca89/distrobox/main/install | sudo sh &> /dev/null
#					command -v distrobox > /dev/null || { has_distrobox=false; }
#					$has_distrobox || {
#						echo -e "\e[1;31m[ Error ]\e[0m Unable to install distrobox, install it manually and run this script again. Instructions are available here: https://github.com/89luca89/distrobox";
#						exit 1;
#					}
#					break;;
#				[nN]   )
#					echo -e "\e[1;34m[  Log  ]\e[0m Installing distrobox is required, install it manually and run this script again. Instructions are available here: https://github.com/89luca89/distrobox";
#					exit 0;;
#				* )
#			esac
#
#		done
#	};
#	echo "cest fini"
#}
