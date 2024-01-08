#!/bin/bash

SWAPFILE="swapfile"
MSG_NEED_SUDO="Please run this script with sudo."
MSG_EXIT="Exiting..."
MSG_PROCEED="Proceeding..."

if [ "$EUID" -ne 0 ]; then
    sleep 1
    echo "Error: $MSG_NEED_SUDO" >&2
    exit 1
fi

echo -e "\nThis Script should be used for both enabling and\ndisabling the swapfile and if you had created the swap\nmanually then dont use this script, instead remove\nit manually!\n"

read -p "Ready to proceed? y|n : " ans

if [[ "$ans" == "n" ]]; then
    sleep 1
    echo -e "$MSG_EXIT\n"
    exit 1
elif [[ "$ans" == "y" ]]; then
    read -p"Enable Swap or Disable Swap? E|D : " ed
    if [[ "$ed" == "E" ]]; then
        echo -e "$MSG_PROCEED You chose to Enable..."
        CHECK=$(swapon --show | awk 'NR>1 {print $1}')
        if [ -z "$CHECK" ]; then
            read -p "How many Gigabytes of space you want to allocate? (default: 4GB) " size
            size=${size:-4}
            if ! [[ "$size" =~ ^[0-9]+$ ]] || [ "$size" -le 0 ]; then
                sleep 1
                echo "Error: Invalid size!" >&2
                exit 1
            fi
            read -p "Enter a location for swap memory: (default:/) " LOCATION
            LOCATION=${LOCATION:-/}
            if [ ! -d "$LOCATION" ]; then
                sleep 1
                echo -e "Error: Provide valid location!\n" >&2
                exit 1
            fi
            echo "Making Swapfile in ${LOCATION}"
            sudo fallocate -l ${size}G ${LOCATION}${SWAPFILE}
            sudo chmod 600 ${LOCATION}${SWAPFILE}
            sudo mkswap ${LOCATION}${SWAPFILE}
            sudo swapon ${LOCATION}${SWAPFILE}
            echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
            sleep 2
            echo "Created the swapfile of "$size"GB in "$LOCATION""
            echo -e "Reboot Now!\n"
        else
            sleep 1
            echo -e "Error: There is a swap file already in $CHECK\n" >&2
            exit 1
        fi
    elif [[ "$ed" == "D" ]]; then
        echo -e "$MSG_PROCEED You chose to Disable..."
        LOCATION=$(swapon --show | awk 'NR>1 {print $1}')
        if [ -n "$LOCATION" ]; then
            sudo swapoff "$LOCATION"
            sudo sed -i '/\/swapfile.*swap/s/^/#/' /etc/fstab
            sudo rm "$LOCATION"
            sleep 2
            echo "Removed the swap file!"
            echo -e "Reboot Now!\n"
        else
            sleep 1
            echo -e "Seems like there is no Swap present, $MSG_EXIT\n" >&2
            exit 1
        fi
    else
        sleep 1
        echo -e "Error: Invalid Choice $MSG_EXIT\n" >&2
        exit 1
    fi
else
    sleep 1
    echo "Error: Input -> y | n" >&2
    exit 1
fi
