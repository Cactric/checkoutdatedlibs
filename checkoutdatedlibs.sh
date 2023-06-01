#!/bin/bash

# Script to check processes for outdated libraries
# Made by @Cactric, 2023
# Inspired from the similar functionallity in htop, split out into a script

main() {
    outdated=0
    
    # Whether to say the user show logout/back in or reboot
    advice=""

    if [ "$EUID" -ne 0 ]; then
        echo "Root is needed to detect outdated libraries in processes running as different users"
    else
        my_uid="$SUDO_UID"
    fi
    if [ -z "$my_uid" ]; then
        my_uid="$(id -ru)"
    fi

    for pid in $(ps aux | awk '{print $2}' | grep -v "PID"); do
        maps="$(grep -v '/memfd:' "/proc/$pid/maps" 2>/dev/null)"
        if echo "$maps" | grep -q '[r-][w-]x[p-].* /.* (deleted)$'; then
            # TODO: add some edge cases from htop code (see https://github.com/htop-dev/htop/blob/f0a7a78797bd9fd9b8215cc194922d7bc1d6b885/linux/LinuxProcessList.c#L657)
            echo "$pid ($(cat /proc/"$pid"/comm)) is outdated or has outdated libraries"
            outdated=$(( outdated + 1 ))
            
            # Check if the user owns the process's directory
            # If it's owned by someone else (likely root or a user for a specific daemon), advice the user to reboot
            if [ "$my_uid" -ne "$(stat "/proc/$pid" --format=%u)" ]; then
                advice='reboot'
            else
                # 'reboot' has higher precedence than 'logout'
                if [ "$advice" != 'reboot' ]; then
                    advice='logout'
                fi
            fi
        fi
    done

    # Check kernel version
    # (this assumes the old modules get removed)
    if [ ! -d "/usr/lib/modules/$(uname -r)/" ]; then
        echo "Kernel is outdated (running $(uname -r))"
        outdated=$(( outdated + 1))
        advice=reboot
    fi

    if [ $outdated -gt 0 ]; then
        case $advice in
            'reboot') echo "Advice: reboot your computer"
            ;;
            'logout') echo "Advice: log out and back in"
            ;;
        esac
    
        exit 1;
    else
        echo "No outdated programs or libraries detected"
    fi
}

main "$@"
