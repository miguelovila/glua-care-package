#!/bin/bash

#
# CONFIGURATION & FUNCTIONS
#

ENABLE_DEBUGGING=true
ENABLE_LOGGING=true

custom_print() {
	# $1 = type (info, error, debug, *); $2 = content
	case "$1" in
	"debug") {
		$ENABLE_DEBUGGING && printf "\e[1;33m[ DEBUG ]\e[0m %s\n" "$2" # Yellow
		$ENABLE_LOGGING && printf "[ DEBUG ] %s\n" "$2" >>log.txt
	} ;;
	"error") {
		printf "\e[1;31m[ ERROR ]\e[0m %s\n" "$2" # Red
		$ENABLE_LOGGING && printf "[ ERROR ] %s\n" "$2" >>log.txt
	} ;;
	"information") {
		printf "\e[1;34m[ INFOR ]\e[0m %s\n" "$2" # Blue
		$ENABLE_LOGGING && printf "[ INFOR ] %s\n" "$2" >>log.txt
	} ;;
	*) {
		printf "\e[1;35m[ $1 ]\e[0m %s\n" "$2" # Magenta
		$ENABLE_LOGGING && printf "[ $1 ] %s\n" "$2" >>log.txt
	} ;;
	esac
}

custom_read() {
	# $1 = type (yesno, range, *); $2 = content; $3 = lower; $4 = upper
	$ENABLE_LOGGING && printf "[ INPUT ] %s" "$2" >>log.txt

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
	command -v distrobox >/dev/null || { has_distrobox=false; }
	command -v curl >/dev/null || { has_curl=false; }
	command -v podman >/dev/null || { has_podman=false; }
	command -v docker >/dev/null || { has_docker=false; }
	custom_print "debug" "Here are the results: has_distrobox=$has_distrobox, has_curl=$has_curl, has_podman=$has_podman, has_docker:$has_docker"
}

determine_install_command() {
	# $1 = distribution (Ubuntu, Fedora, Debian, Alpine, ...) TODO: Add support for more distros
	local distribution
	distribution="$(echo "$1" | tr '[:upper:]' '[:lower:]')"
	[[ $distribution =~ ^(ubuntu|xubuntu|debian)$ ]] && echo "sudo apt install -y"
	[[ $distribution =~ ^(alpine)$ ]] && echo "sudo apk --update add"
	[[ $distribution =~ ^(fedora)$ ]] && echo "sudo dnf install -y"
}

#
# MAIN - START OF THE SCRIPT
#

custom_print "debug" ""
custom_print "debug" "########## STARTING THE SCRIPT ##########"

# Checking for sudo privileges
custom_print "debug" "Checking for sudo privileges..."
[ "$(id -u)" == 0 ] && {
	custom_print "error" "Execute this script without sudo privileges."
	exit 1
}
custom_print "debug" "I'm running as a normal user"

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
($has_distrobox && $has_curl && ($has_podman || $has_docker)) || {
	missing_dependencies=""
	$has_distrobox || { missing_dependencies="${missing_dependencies} distrobox"; }
	$has_curl || {
		[ -z "$missing_dependencies" ] || missing_dependencies="${missing_dependencies},"
		missing_dependencies="${missing_dependencies} curl"
	}
	$has_podman || $has_docker || {
		[ -z "$missing_dependencies" ] || missing_dependencies="${missing_dependencies},"
		missing_dependencies="${missing_dependencies} podman, docker (optional)"
	}
	custom_print "error" "Missing dependencies:$missing_dependencies."

	# Installing missing dependencies
	$has_curl || {
		answer="$(custom_read "yesno" "Install curl automatically? [y/n] ")"
		[ "$answer" = "y" ] && {
			custom_print "information" "Installing curl, this may take a while."
			while read -r line
			do
			    custom_print "debug" "$line"
			done < <($(determine_install_command "$distribution_name") curl 2>&1)
			has_curl=true
			check_dependencies
			$has_curl || {
				custom_print "error" "Failed to install curl. Install it manually and try again."
				exit 1
			}
			$has_curl && {
				custom_print "information" "Successfully installed curl."
			}
		}
		[ "$answer" = "n" ] && {
			custom_print "information" "Installing curl is required. Install it manually and try again."
			exit 0
		}
	}
	$has_distrobox || {
		answer="$(custom_read "yesno" "Install distrobox automatically? [y/n] ")"
		[ "$answer" = "y" ] && {
			custom_print "information" "Installing distrobox, this may take a while."
			while read -r line
			do
			    custom_print "debug" "$line"
			done < <(curl -s https://raw.githubusercontent.com/89luca89/distrobox/main/install | sudo sh 2>&1)
			has_distrobox=true
			check_dependencies
			$has_distrobox || {
				custom_print "error" "Failed to install distrobox. Install it manually and try again. Instructions are available here: https://github.com/89luca89/distrobox"
				exit 1
			}
			$has_distrobox && {
				custom_print "information" "Successfully installed distrobox."
			}
		}
		[ "$answer" = "n" ] && {
			custom_print "information" "Installing distrobox is required. Install it manually and try again. Instructions are available here: https://github.com/89luca89/distrobox"
			exit 0
		}
	}
	$has_podman || $has_docker || {
		answer="$(custom_read "range" "Install podman (0 recommended) or docker (1)? [0-1] " "0" "1")"
		[ "$answer" = "0" ] && {
			custom_print "information" "Installing podman, this may take a while."
			while read -r line
			do
			    custom_print "debug" "$line"
			done < <($(determine_install_command "$distribution_name") podman 2>&1)
			has_podman=true
			check_dependencies
			$has_podman || {
				custom_print "error" "Failed to install podman. Install it manually and try again. Instructions are available here: https://podman.io/getting-started/installation"
				exit 1
			}
			$has_podman && {
				custom_print "information" "Successfully installed podman."
			}
		}
		[ "$answer" = "1" ] && {
			custom_print "information" "Installing docker, this may take a while."
			while read -r line
			do
			    custom_print "debug" "$line"
			done < <($(determine_install_command "$distribution_name") docker.io 2>&1)
			has_docker=true
			check_dependencies
			$has_docker || {
				custom_print "error" "Failed to install docker. Install it manually and try again. Instructions are available here: https://docs.docker.com/engine/install/"
				exit 1
			}
			custom_print "debug" "Adding the current user to the docker group."
			sudo groupadd docker &> /dev/null
			sudo usermod -aG docker "$USER" &> /dev/null
			$has_docker && {
				custom_print "information" "Successfully installed docker."
			}
			custom_print "information" "RESTART your computer to fully apply the changes and re-run this script."
			exit 0
		}
	}
}

# Managing the box MVP

distrobox-create --image docker.io/library/archlinux:latest --name glua-care-package --yes
distrobox-enter --name glua-care-package << EOF
pacman --version
exit
EOF