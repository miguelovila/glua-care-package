#!/bin/bash

#
# GLOBAL FUNCTIONS
#

custom_print() {
	# $1 = type (info, error, debug, *); $2 = content (message); $3 = show prefix (true, false)
	local prefix
	$3 && {
		case "$1" in
		"debug") {
			prefix="\e[1;33m[ DEBUG ]\e[0m " # Yellow
		} ;;
		"error") {
			prefix="\e[1;31m[ ERROR ]\e[0m " # Red
		} ;;
		"information") {
			prefix="\e[1;34m[ INFOR ]\e[0m " # Blue
		} ;;
		*) {
			prefix="\e[1;35m[ $1 ]\e[0m " # Magenta
		} ;;
		esac
	}

	case "$1" in
	"debug") {
		$enable_debugging && printf "$prefix%s\n" "$2" # Yellow
		$enable_logging && printf "$prefix%s\n" "$2" >>log.txt
	} ;;
	"error") {
		printf "$prefix%s\n" "$2" # Red
		$enable_logging && printf "$prefix%s\n" "$2" >>log.txt
	} ;;
	"information") {
		printf "$prefix%s\n" "$2" # Blue
		$enable_logging && printf "$prefix%s\n" "$2" >>log.txt
	} ;;
	*) {
		printf "$prefix%s\n" "$2" # Magenta
		$enable_logging && printf "$prefix%s\n" "$2" >>log.txt
	} ;;
	esac
}

custom_read() {
	# $1 = type (yesno, range, *); $2 = content; $3 = lower; $4 = upper
	$enable_logging && printf "[ INPUT ] %s" "$2" >>log.txt

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
	$enable_logging && echo "$answer" >>log.txt
}

#
# HOST FUNCTIONS
#

check_dependencies() {
		custom_print "debug" "Checking for missing dependencies..." true
		command -v distrobox >/dev/null || { has_distrobox=false; }
		command -v curl >/dev/null || { has_curl=false; }
		command -v podman >/dev/null || { has_podman=false; }
		command -v docker >/dev/null || { has_docker=false; }
		custom_print "debug" "Here are the results: has_distrobox=$has_distrobox, has_curl=$has_curl, has_podman=$has_podman, has_docker:$has_docker" true
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
# DEFAULTS & ARGUMENT PARSING
#

enable_debugging=false # Enable debugging messages
enable_logging=false # Enable logging everything to a log.txt file
operation_mode="on-host" # on-host or on-box (default: on-host) 

while :; do
	case $1 in
		-ob | --on-box)
			shift
			operation_mode="on-box"
			;;
		-oh | --on-host)
			shift
			operation_mode="on-host"
			;;
		-ed | --enable-debugging)
			shift
			enable_debugging=true
			;;
		-el | --enable-logging)
			shift
			enable_logging=true
			;;
		-*)
			custom_print "error" "Unknown option: $1" true
			exit 1
			;;
		*)
			break
			;;
	esac
done

custom_print "debug" "" true
custom_print "debug" "########## STARTING THE SCRIPT ##########" true

if [ "${operation_mode}" == "on-host" ]; then
	custom_print "debug" "Working on host mode" true

	# Checking for sudo privileges
	custom_print "debug" "Checking for sudo privileges..." true
	[ "$(id -u)" == 0 ] && {
		custom_print "error" "Execute this script without sudo privileges." true
		exit 1
	}
	custom_print "debug" "I'm running as a normal user" true

	# Checking for compatibility TODO: verify from a list of tested distros
	custom_print "debug" "Checking where I'm running..." true
	distribution_name="$(lsb_release -is)"
	distribution_release="$(lsb_release -sr)"
	custom_print "debug" "I'm running in a $distribution_name $distribution_release machine" true

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
		custom_print "error" "Missing dependencies:$missing_dependencies." true

		# Installing missing dependencies
		$has_curl || {
			answer="$(custom_read "yesno" "Install curl automatically? [y/n] ")"
			[ "$answer" = "y" ] && {
				custom_print "information" "Installing curl, this may take a while." true
				while read -r line
				do
				    custom_print "debug" "$line" true
				done < <($(determine_install_command "$distribution_name") curl 2>&1)
				has_curl=true
				check_dependencies
				$has_curl || {
					custom_print "error" "Failed to install curl. Install it manually and try again." true
					exit 1
				}
				$has_curl && {
					custom_print "information" "Successfully installed curl." true
				}
			}
			[ "$answer" = "n" ] && {
				custom_print "information" "Installing curl is required. Install it manually and try again." true
				exit 0
			}
		}
		$has_distrobox || {
			answer="$(custom_read "yesno" "Install distrobox automatically? [y/n] ")"
			[ "$answer" = "y" ] && {
				custom_print "information" "Installing distrobox, this may take a while." true
				while read -r line
				do
				    custom_print "debug" "$line" true
				done < <(curl -s https://raw.githubusercontent.com/89luca89/distrobox/main/install | sudo sh 2>&1)
				has_distrobox=true
				check_dependencies
				$has_distrobox || {
					custom_print "error" "Failed to install distrobox. Install it manually and try again. Instructions are available here: https://github.com/89luca89/distrobox" true
					exit 1
				}
				$has_distrobox && {
					custom_print "information" "Successfully installed distrobox." true
				}
			}
			[ "$answer" = "n" ] && {
				custom_print "information" "Installing distrobox is required. Install it manually and try again. Instructions are available here: https://github.com/89luca89/distrobox" true
				exit 0
			}
		}
		$has_podman || $has_docker || {
			answer="$(custom_read "range" "Install podman (0 recommended) or docker (1)? [0-1] " "0" "1")"
			[ "$answer" = "0" ] && {
				custom_print "information" "Installing podman, this may take a while." true
				while read -r line
				do
				    custom_print "debug" "$line" true
				done < <($(determine_install_command "$distribution_name") podman 2>&1)
				has_podman=true
				check_dependencies
				$has_podman || {
					custom_print "error" "Failed to install podman. Install it manually and try again. Instructions are available here: https://podman.io/getting-started/installation" true
					exit 1
				}
				$has_podman && {
					custom_print "information" "Successfully installed podman." true
				}
			}
			[ "$answer" = "1" ] && {
				custom_print "information" "Installing docker, this may take a while." true
				while read -r line
				do
				    custom_print "debug" "$line" true
				done < <($(determine_install_command "$distribution_name") docker.io 2>&1)
				has_docker=true
				check_dependencies
				$has_docker || {
					custom_print "error" "Failed to install docker. Install it manually and try again. Instructions are available here: https://docs.docker.com/engine/install/" true
					exit 1
				}
				custom_print "debug" "Adding the current user to the docker group." true
				sudo groupadd docker &> /dev/null
				sudo usermod -aG docker "$USER" &> /dev/null
				$has_docker && {
					custom_print "information" "Successfully installed docker." true
				}
				custom_print "information" "RESTART your computer to fully apply the changes and re-run this script." true
				exit 0
			}
		}
	}

	# Creating or starting the container
	custom_print "information" "Creating the container, this may take a while." true
	while read -r line
	do
	    custom_print "debug" "$line" true
	done < <(distrobox-create --image docker.io/library/archlinux:latest --name glua-care-package --yes --no-entry --root 2>&1)

	# Setting up the container with git and yay and enabling multilib TODO: transpose flags to on-box mode

	custom_print "information" "Running the script inside the container, this may take a while." true
	while read -r line
	do
		custom_print " BOX " "$line" true
	done < <(printf " ./gluacp.sh -ob -ed" | distrobox-enter --root glua-care-package 2>&1)
	exit 0
fi

if [ "${operation_mode}" == "on-box" ]; then
	custom_print "debug" "The script is now working in on-box mode." true
	custom_print "debug" "Updating the box, this may take a while." true
	sudo pacman -Syyu --noconfirm
	custom_print "debug" "Preparing the box, this may take a while." true
	sudo pacman -Syu base-devel --noconfirm
	command -v git >/dev/null || {
		sudo pacman -Syu git --noconfirm
	}
	command -v fakeroot >/dev/null || {
		sudo pacman -Syu fakeroot --noconfirm
	}
	command -v yay >/dev/null || {
		git clone https://aur.archlinux.org/yay-bin.git
		cd yay-bin || {
			custom_print "error" "Failed to enter yay-bin directory." true
			exit 1
		}
		makepkg -si --noconfirm
		cd .. || {
			custom_print "error" "Failed to enter the parent directory." true
			exit 1
		}
		rm -rf yay-bin
	}
	custom_print "debug" "Done preparing the box." true
	
	exit
	#yay -Syu quartus-free-devinfo-cyclone --noconfirm
fi


# Setting up the container with git and yay and enabling multilib
#custom_print "information" "Setting up the container, this may take a while."
#while read -r line
#do
#	custom_print "debug" "$line"
#done < <(distrobox-enter --name glua-care-package 2>&1 << EOF
#
#echo -e "This is the original pacman.conf file:"
#cat /etc/pacman.conf
#grep -qxF '#[multilib]' /etc/pacman.conf || echo '#[multilib]
##Include = /etc/pacman.d/mirrorlist' | sudo tee -a /etc/pacman.conf
#sudo sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
#echo -e "This is the edited pacman.conf file:"
#cat /etc/pacman.conf
#
#pacman --version
#sudo pacman -Syyu --noconfirm
#sudo pacman -S --needed base-devel git --noconfirm
#
#git clone https://aur.archlinux.org/yay.git
#cd yay
#makepkg -si --noconfirm
#cd ..
#sudo rm -rf yay
#
#yay --version
#exit
#EOF
#)
#
## Installing Intel Quartus Prime Lite
#custom_print "information" "Installing Intel Quartus Prime Lite, this may take a while."
#custom_print "information" "Now seriously, this may take a really long while."
#while read -r line
#do
#	custom_print "debug" "$line"
#done < <(distrobox-enter --name glua-care-package 2>&1 << EOF
#yay -S --noconfirm quartus-free-quartus
#exit
#EOF
#)
#
#custom_print "information" "End of the script. :)"