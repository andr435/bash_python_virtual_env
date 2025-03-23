#!/usr/bin/env bash

################################################
# Developed by: Andrey M.
# Purpose: Install python 3 packages, virtual enviroment manager.
# Create and activate virtual enviroment in given directory or in current directory if nothing given.
# Date: 21-03-2025
# Version: 1.0.0
################################################
set -o errexit
set -o pipefail
set -o nounset
################################################

script_version=1.0.0
script_name=python_machine.sh
work_directory="."
default_venv_directory=".venv"
real_user=${SUDO_USER:-$(whoami)}
run_user=$(whoami)

. /etc/os-release

Destruct(){
    unset script_version
    unset script_name
    unset work_directory
    unset default_venv_directory
    unset real_user
    unset run_user

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
    local p_modules=(python3 python3-pip python3-pipx makeself sqlite3)
    
    for item in "${p_modules[@]}"; do
        Install_package "$item"
    done

    local loop_again="true"

    while [[ $loop_again != "false" ]]; do
        read -p "Default virtual enviroment meneger? 
        [1] venv 
        [2] pipenv
        [3] poetry" venv_manager

        if [[ $venv_manager == "1" ]]; then
            loop_again="false"
            Install_package python3-venv
            Create_venv_venv
        elif [[ $venv_manager == "2" ]]; then
            loop_again="false"
            pip install pipenv
            Create_venv_pipenv
        elif [[ $venv_manager == "3" ]]; then
            loop_again="false"
            pipx install poetry
            poetry completions bash >> ~/.bash_completion
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

    mkdir -p "$work_directory" 
}

Create_venv_venv(){
    su - "$real_user"
    local venv_path=${work_directory}/"$default_venv_directory"
    Create_work_directory
    python -m "$venv_path"
    source "${venv_path}"/bin/activate
    
    su - "$run_user"

    return 0
}


Create_venv_pipenv(){
    su - "$real_user"
    Create_work_directory
    cd "$work_directory"
    pipenv shell

    su - "$run_user"
    return 0
}


Create_venv_poetry(){
    su - "$real_user"
    Create_work_directory
    local project_name="demo"
    read -p "Project name? " project_name
    cd "$work_directory"
    poetry new "$project_name"
    eval $(poetry env activate)

    su - "$run_user"
    return 0
}

Install_project_packages(){
    local project_pack=(flask flask-sqlalchemy flask-alchemyview bootstrap-flask quart db-sqlite3)
    su - "$real_user"

    if [[ $venv_manager == "1" ]]; then
        pip install "${project_pack[@]}"
    elif [[ $venv_manager == "2" ]]; then
        pipenv install "${project_pack[@]}"
    elif [[ $venv_manager == "3" ]]; then
        poetry add "${project_pack[@]}"
    fi
    
    su - "$run_user"

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
