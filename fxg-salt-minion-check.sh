#!/bin/sh

# Load sensor checking whether any processes called "salt-minion" are running
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

PATH=/bin:/usr/bin

ARCH=`$SGE_ROOT/util/arch`
HOST=`$SGE_ROOT/utilbin/$ARCH/gethostname -name`

ls_log_file=/tmp/ls.dbg

# uncomment this to log load sensor startup  
# echo `date`:$$:I:load sensor `basename $0` started >> $ls_log_file

# Process name to match
PROCESS_NAME='salt-minion'

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
   # send load value arch
   #
   #echo "$HOST:usr_processes:`who | cut -f1 -d" " | sort | uniq |wc -l`"
   # Need to grep -x or we'll get ourselves (name of the load_sensor)
   if pgrep -x "$PROCESS_NAME" > /dev/null 2>&1; then
      running="TRUE"
   else
      running="FALSE"
   fi

   echo "$HOST:salt-minion:$running"

   # ---------------------------------------- 
   # send mark for end of load report
   echo "end"
done

# uncomment this to log load sensor shutdown  
# echo `date`:$$:I:load sensor `basename $0` exiting >> $ls_log_file
