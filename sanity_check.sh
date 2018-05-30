#!/bin/bash

lockdir=/var/tmp/sanity_check
pidfile=${lockdir}/pid

if ( mkdir ${lockdir} ) 2> /dev/null; then
  echo $$ > $pidfile
  trap 'rm -rf "$lockdir"; exit $?' INT TERM EXIT

  # do stuff here
  source /etc/profile.d/sge.sh

  HOSTNAME=$(hostname --fqdn)
  #Dont run if the host is already disabled
  qhost -h ${HOSTNAME} -q -xml|xmlstarlet sel -t -m "//queue/queuevalue[@name='state_string']" -v .| grep d && echo "Host disabled, Exiting" && exit 98

  function test_failed {
    DATETIME=$(date)
    COMPACT_DATETIME=$(date +'%D %T')   #not much room in the disabled message
    HOSTNAME=$(hostname)
    MESSAGE="${DATETIME}: Sanity check failed. ${HOSTNAME} disabled. Please Investigate. ${1}"
    # some checks fail if not run as root, but qmod -d will still work if the user is an UGE admin
    if [[ $EUID -ne 0 ]]; then
        echo
        echo "WARNING: Not running as root. This is a dry-run!" 1>&2
        echo
        echo "Would have run:" qmod -msg \"Sanity check: ${1} @ ${COMPACT_DATETIME}\" -d *@${HOSTNAME}
        echo "Would have run:" echo ${1}
        echo "Would have run:" /usr/bin/logger -t auto_disabled_host \"${MESSAGE}\"
        exit 100
    fi
    # do the things
    qmod -msg "Sanity check: ${1} @ ${COMPACT_DATETIME}" -d *@${HOSTNAME}
    echo ${1}
    #echo ${MESSAGE} | mailx -s "Host Automatically Disabled ${HOSTNAME}" ihmesa@uw.edu
    /usr/bin/logger -t auto_disabled_host "${MESSAGE}"
    exit 99
  }

  # Check CVFS mounts
  # Skip check on the following hosts
  case ${HOSTNAME} in
    geos-app-t*)  echo ;;   # geos nodes are still mounting via NFS
    cluster-qmaster-p01.ihme.washington.edu) echo ;;    # why are we not checking the qmasters?
    cluster-qmaster-d01.ihme.washington.edu) echo ;;    # why are we not checking the qmasters?
    *) grep -c cvfs /proc/mounts | grep -v  2 > /dev/null && test_failed "Missing cvfs mount";;
  esac

  cd /homes 2> /dev/null || test_failed "Home directory not accessible"

  # SGE process running ?
  case ${HOSTNAME} in
    cluster-prod.ihme.washington.edu) echo ;;
    cluster-dev.ihme.washington.edu) echo ;;
    cluster-qmaster-p01.ihme.washington.edu) echo ;;
    cluster-qmaster-d01.ihme.washington.edu) echo ;;
    gma1-dev.ihme.washington.edu) echo ;;
    *) pgrep sge_execd > /dev/null || test_failed "UGE not running";;
  esac


  # Usernames resolving correctly ?

  id cjlm > /dev/null || test_failed "Usernames not resolving"

  # SSSD running

  cat /var/run/sssd.pid > /dev/null || test_failed "sssd is not running"

  # Cgroup running

  #service cgconfig status | grep Running > /dev/null || test_failed "cgconfig not running"

  #stornext volumes
  # this checks that they are present, not that they are mounted via CVFS (see higher up in the script)
  grep -q snfs1 /home/j/.snfs1 || test_failed "snfs1 not mounted or /home/j missing"
  grep -q homes /homes/.homes || test_failed "/homes missing"

  #check /ihme/code symlink
  ls /ihme/code/mortality > /dev/null || test_failed "/ihme/code symlink missing (Salt not working?)"


  # clean up after lock
  rm -rf "$lockdir"
  trap - INT TERM EXIT
else
  lock_pid=$(cat $pidfile)
  echo -n "Lock Exists: $pidfile owned by PID $lock_pid"
  # This will remove orphaned locks but not re-run sanity-check
  if ps h -p $lock_pid > /dev/null 2>&1; then
    echo ". Exiting..."
  else
    echo ", but can't find process $lock_pid. Deleting $lockdir directory."
    rm -rf $lockdir
  fi
fi
