#!/usr/bin/env bash

################################################
# Developed by: Andrey M.
# Purpose: Install python 3 packages, virtual enviroment manager.
# Create and activate virtual enviroment in given directory or in current directory if nothing given.
# Date: 21-03-2025
# Version: 1.1.0
################################################
set -o errexit
set -o pipefail
set -o nounset
################################################

script_version=1.1.0
script_name=python_machine.sh
work_directory="."
default_venv_directory=".venv"
real_user=${SUDO_USER:-$(whoami)}

. /etc/os-release

Destruct(){
	unset script_version
	unset script_name
	unset work_directory
	unset default_venv_directory
	unset real_user

	return 0    
}

Update_system(){
	# update repository to latest packages
	echo System update

	set +o errexit
	yum check-update; yum update -y
	set -o errexit
	
	return 0
}

Install_packages(){
	# Install python packages and venv manager
	local pre_requirement=(epel-release)
	local p_modules=(python3 python3-pip pipx makeself sqlite)
	
	for item in "${pre_requirement[@]}"; do
		Install_package "$item"
	done

	/usr/bin/crb enable
	
	for item in "${p_modules[@]}"; do
		Install_package "$item"
	done
	
	python3 -m pip install --upgrade pip setuptools wheel
	python -m pip install "setuptools<58.0.0" --no-cache-dir
	local loop_again="true"

	while [[ $loop_again != "false" ]]; do
		read -p " 
[1] venv 
[2] pipenv
[3] poetry
Choose virtual enviroment maneger for project: " venv_manager

		if [[ $venv_manager == "1" ]]; then
			loop_again="false"
			Create_venv_venv
		elif [[ $venv_manager == "2" ]]; then
			loop_again="false" 
			sudo -u "$real_user" python3.9 -m pip install -U pipenv
			export PATH=$PATH:home/${real_user}/.local/bin
			Create_venv_pipenv
		elif [[ $venv_manager == "3" ]]; then
			loop_again="false"
			sudo -u "$real_user" pipx install poetry
			sudo -u "$real_user" pipx ensurepath
			export PATH
			Create_venv_poetry
		else 
			echo "incorect choise"
		fi
	done

	return 0
}

Install_package(){
	# 1 - package name
	if ! rpm -q "$1" &>/dev/null; then
			echo "Installing $1"
			yum -y install "$1"
	else
			echo "$1 is already installed"
	fi

	return 0
}

Create_work_directory(){
	if [[ "$work_directory" == "." ]]; then
		return 0
	fi

	if [[ -d "$work_directory" ]]; then
		return 0
	fi

	sudo -u "$real_user" mkdir -p ${work_directory} 

	return 0
}

Create_venv_venv(){
	local venv_path=${work_directory}/"$default_venv_directory"
	Create_work_directory
	sudo -u "$real_user" python -m venv ${venv_path}

	return 0
}


Create_venv_pipenv(){
	Create_work_directory
	cd "$work_directory"
	su -c "/home/${real_user}/.local/bin/pipenv install" "$real_user"

	return 0
}


Create_venv_poetry(){
	Create_work_directory
	local project_name="demo"
	read -p "Project name? " project_name
	cd "$work_directory"
	sudo -u "$real_user" /home/${real_user}/.local/bin/poetry new "$project_name"
	cd "$work_directory"/"$project_name"
	return 0
}

Install_project_packages(){
	# depricated with 'use_2to3' dependecy, install first
	local packages_depricated="dictalchemy flask-alchemyview"
	local project_pack="flask flask-sqlalchemy bootstrap-flask quart db-sqlite3"
	local venv_path=${work_directory}/"$default_venv_directory"

	if [[ $venv_manager == "1" ]]; then
		sudo -u "$real_user" "$venv_path"/bin/python -m pip install "setuptools<58.0.0"
		sudo -u "$real_user" "$venv_path"/bin/python -m pip install ${packages_depricated}
		sudo -u "$real_user" "$venv_path"/bin/python -m pip install ${project_pack}
		echo "To activate virtual enviroment run command: ${venv_path}/bin/activate"
	elif [[ $venv_manager == "2" ]]; then
		su -c "/home/${real_user}/.local/bin/pipenv run pip install 'setuptools<58.0.0'" "$real_user"
		su -c "/home/${real_user}/.local/bin/pipenv run pip install ${packages_depricated}" "$real_user"
		su -c "/home/${real_user}/.local/bin/pipenv install ${project_pack}" "$real_user"
	elif [[ $venv_manager == "3" ]]; then
		su -c "/home/${real_user}/.local/bin/poetry run pip install 'setuptools<58.0.0' --no-cache-dir" "$real_user"
		su -c  "/home/${real_user}/.local/bin/poetry run pip install ${packages_depricated}" "$real_user"
		su -c "/home/${real_user}/.local/bin/poetry add ${project_pack}" "$real_user"
	fi

	return 0
}


Help(){
	# Display Help
	echo "
SYNOPSIS
	$script_name [-h|--help|-v|--version|-d|--directory]

DESCRIPTION
	Prepare machine to run pithon.
	And create virtual enviroment with flask framework.
	if work directory not given, create in current directory
	
 OPTIONS
	-h|--help          Print this help
	-v|--version       Show version
	-d|--directory     Work directory. Create vitrual enviroment in this directory

	"

	return 0
 }


Version(){
	echo "$script_name version: $script_version"

	return 0
}


Main(){

   # Check if the script is run with sudo
   if (( "$EUID" > 0 )); then
		echo "Please run this script with  sudo."
		Destruct
		exit 1
   fi

   if [[ ! $ID_LIKE =~ rhel ]]; then
		echo "Script run only on Red Hat distributives"
		Destruct
		exit 1
	fi

	# check options -
	while [[ "$#" -gt 0 ]]; do
		case "$1" in
			-h | --help )
				Help
				Destruct
				exit 0
			;;
			-v | --version ) 
				Version
				Destruct
				exit 0
				;;
			-d | --directory )
				work_directory="$2"
				echo "$work_directory"
				shift
				;;

			-- ) shift; break ;;  # End of options
			-* )  ;;
			* ) break ;;
		esac
		shift
	done

	Update_system
	Install_packages
	Install_project_packages
	Destruct
	return 0
}

Main "$@"
exit 0
