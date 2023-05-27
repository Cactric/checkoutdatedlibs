#!/bin/bash

# Script to check processes for outdated libraries
# Made by @Cactric, 2023
# Inspired from the similar functionallity in htop, split out into a script

main() {
    outdated=0

    for pid in $(ps aux | awk '{print $2}' | grep -v "PID"); do
        maps="$(grep -v '/memfd:' "/proc/$pid/maps" 2>/dev/null)"
        if echo "$maps" | grep -q '[r-][w-]x[p-].* /.* (deleted)$'; then
            # TODO: add some edge cases from htop code (see https://github.com/htop-dev/htop/blob/f0a7a78797bd9fd9b8215cc194922d7bc1d6b885/linux/LinuxProcessList.c#L657)
            echo "$pid ($(cat /proc/"$pid"/comm)) is outdated or has outdated libraries"
            outdated=$(( outdated + 1 ))
        fi
    done

    # Check kernel version
    # (this assumes the old modules get removed)
    if [ ! -d "/usr/lib/modules/$(uname -r)/" ]; then
        echo "Kernel is outdated (running $(uname -r))"
        outdated=$(( outdated + 1))
    fi

    if [ $outdated -gt 0 ]; then
        exit 1;
    else
        echo "No outdated programs or libraries detected"
    fi
}

main "$@"
