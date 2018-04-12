#!/bin/bash

PATH=/bin:/usr/bin:/opt/uge/bin/lx-amd64:/usr/local/UGE-prod/bin/lx-amd64

ARCH=`$SGE_ROOT/util/arch`
HOST=`$SGE_ROOT/utilbin/$ARCH/gethostname -name`

ls_log_file=/dev/stdout

# System users to ignore
SYSTEM_USERS='root,rpc,rpcuser,dbus,ntp,lldpd,_lldpd,postfix,sgeadmin,haldaemon,sensu'

# Some special users we want to ignore
#	matpp: leaves gpg-agents everywhere
#	scscicompci: leaves ssh-agents everywhere
#
KLUDGE_USERS='sadm_matpp,svcscicompci'

IGNORE_USERS="${SYSTEM_USERS},${KLUDGE_USERS}"

# Check for each username and convert to UID to handle:
#	lldpd sometimes being called _lldpd
#	haldaemon sometimes showing up as 68
#	sadm_* accounts showing up as UIDs only
#
for user in $(echo $IGNORE_USERS | tr ',' ' '); do
        if uid=$(id -u "$user" 2> /dev/null); then
                ignore_uids+="$uid,"
        fi
done

# Remove trailing comma
ignore_uids=${ignore_uids%,}

echo "Ignoring UIDs: $ignore_uids" >> $ls_log_file

   # Get the usernames currently running a job on this node
   # This has to happen inside the loop, I assume, since it changes
   job_users=$(qhost -j -h $(hostname -s) -xml | sed -n "s/.*'job_owner'>\([^<]*\).*/\1/p" | sort | uniq)

   echo "Found $(echo "$job_users" | wc -l) users with jobs" >> $ls_log_file
   echo "job_users=$job_users" >> $ls_log_file

   if [[ -n $job_users ]]; then
	job_users=$(echo "$job_users" | tr '\n' ',')
   fi

   # This assumes a trailing comma on 'job_users'
   ignore_list="${job_users}${ignore_uids},sadm_falko"

   echo "Ignoring: $ignore_list" >> $ls_log_file

   echo "$HOST:usr_processes:$(pgrep -v -u $ignore_list | wc -l)"
   pgrep -v -u $ignore_list | tr '\n' ' ' >> $ls_log_file
