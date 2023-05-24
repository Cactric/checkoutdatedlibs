#!/bin/bash

# Script to check processes for outdated libraries
# Made by @Cactric, 2023
# Inspired from the similar functionallity in htop, split out into a script

main() {
    outdated=0

    for pid in $(ps aux | awk '{print $2}' | grep -v "PID"); do
        if grep -q ' (deleted)' "/proc/$pid/maps" 2>/dev/null; then
            # TODO: add some edge cases from htop code (see https://github.com/htop-dev/htop/blob/f0a7a78797bd9fd9b8215cc194922d7bc1d6b885/linux/LinuxProcessList.c#L657)
            echo "$pid ($(cat /proc/"$pid"/comm)) is outdated or has outdated libraries"
            outdated=$(( outdated + 1 ))
        fi
    done

    if [ $outdated -gt 0 ]; then
        exit 1;
    else
        echo "No outdated programs or libraries detected"
    fi
}

main "$@"
