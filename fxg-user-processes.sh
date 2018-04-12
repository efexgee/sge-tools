#!/bin/sh

# Load sensor to count how many user-owned processes are running
# FXG 2018-04-07

#
#___INFO__MARK_BEGIN__
##########################################################################
#
#  The Contents of this file are made available subject to the terms of
#  the Sun Industry Standards Source License Version 1.2
#
#  Sun Microsystems Inc., March, 2001
#
#
#  Sun Industry Standards Source License Version 1.2
#  =================================================
#  The contents of this file are subject to the Sun Industry Standards
#  Source License Version 1.2 (the "License"); You may not use this file
#  except in compliance with the License. You may obtain a copy of the
#  License at http://gridengine.sunsource.net/Gridengine_SISSL_license.html
#
#  Software provided under this License is provided on an "AS IS" basis,
#  WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING,
#  WITHOUT LIMITATION, WARRANTIES THAT THE SOFTWARE IS FREE OF DEFECTS,
#  MERCHANTABLE, FIT FOR A PARTICULAR PURPOSE, OR NON-INFRINGING.
#  See the License for the specific provisions governing your rights and
#  obligations concerning the Software.
#
#  The Initial Developer of the Original Code is: Sun Microsystems, Inc.
#
#  Copyright: 2001 by Sun Microsystems, Inc.
#
#  All Rights Reserved.
#
##########################################################################
#___INFO__MARK_END__

PATH=/bin:/usr/bin:/opt/uge/bin/lx-amd64

ARCH=`$SGE_ROOT/util/arch`
HOST=`$SGE_ROOT/utilbin/$ARCH/gethostname -name`

ls_log_file=/tmp/ls.dbg

# uncomment this to log load sensor startup  
#echo `date`:$$:I:load sensor `basename $0` started >> $ls_log_file

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

#echo "Ignoring UIDs: $ignore_uids" >> $ls_log_file

end=false
while [ $end = false ]; do

   # ---------------------------------------- 
   # wait for an input
   #
   read input
   result=$?
   if [ $result != 0 ]; then
      end=true
      break
   fi
   
   if [ "$input" = "quit" ]; then
      end=true
      break
   fi

   # ---------------------------------------- 
   # send mark for begin of load report
   echo "begin"

   # ---------------------------------------- 

   # Get the usernames currently running a job on this node
   # This has to happen inside the loop, I assume, since it changes
   job_users=$(qhost -j -h $(hostname -s) -xml | sed -n "s/.*'job_owner'>\([^<]*\).*/\1/p" | sort | uniq)

   #echo "Found $(echo "$job_users" | wc -l) users with jobs" >> $ls_log_file
   #echo "job_users=$job_users" >> $ls_log_file

   if [[ -n $job_users ]]; then
	job_users=$(echo "$job_users" | tr '\n' ',')
   fi

   # This assumes a trailing comma on 'job_users'
   ignore_list="${job_users}${ignore_uids},sadm_falko"

   #echo "Ignoring: $ignore_list" >> $ls_log_file

   echo "$HOST:usr_processes:$(pgrep -v -u $ignore_list | wc -l)"
   #pgrep -v -u $ignore_list >> $ls_log_file

   # ---------------------------------------- 
   # send mark for end of load report
   echo "end"
done

# uncomment this to log load sensor shutdown  
#echo `date`:$$:I:load sensor `basename $0` exiting >> $ls_log_file
