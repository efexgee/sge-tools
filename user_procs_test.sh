#!/bin/bash

# System users to ignore
#TODO lldpd is known as _lldpd on some hosts which breaks pgrep
SYSTEM_USERS='root,rpc,rpcuser,dbus,ntp,lldpd,_lldpd,postfix,sgeadmin,haldaemon,sensu'

# Some special users we want to ignore
# Matt leaves gpg-agents everywhere
# scscicompci leaves ssh-agents everywhere
KLUDGE_USERS='sadm_matpp,svcscicompci'

IGNORE_USERS="${SYSTEM_USERS},${KLUDGE_USERS}"

# Check for each username and convert to UID to handle:
#   lldpd vs. _lldpd
#   haldaemon vs. 68

for user in $(echo $IGNORE_USERS | tr ',' ' '); do
        if uid=$(id -u "$user" 2> /dev/null); then
                ignore_uids+="$uid,"
        else
                echo "Didn't find user $user" >&2
        fi
done

ignore_uids=${ignore_uids%,}

echo "ignoring UIDs: $ignore_uids"

job_users=$(qhost -j -h $(hostname -s) -xml | sed -n "s/.*'job_owner'>\([^<]*\).*/\1/p" | sort | uniq)

if [[ -n "$job_users" ]]; then
    job_users=$(echo "$job_users" | tr '\n' ',')
else
    echo "job_users is zero-length: $job_users"
fi

echo "users with jobs: $job_users"

# Counting on a trailing comma on job_users
ignore_list="${job_users}${ignore_uids},sadm_falko"

pgrep -v -u "$ignore_list" -l
