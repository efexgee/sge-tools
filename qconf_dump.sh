#!/bin/bash

#TODO Does not run qconf -sconf ???

# Everything gets dumped in here and also tarballed
output_dir="qconf_dump.$SGE_CLUSTER_NAME.`hostname -s`.$$"

mkdir $output_dir || (echo "Coulnd't create output directory: $output_dir"; exit 1)

# All flags to qconf of the form "-sXl"
for conf in prj rqs u hgrp q user p e conf; do
    # projects
    # resource quota sets
    # user lists
    # host groups
    # queues
    # users
    # parallel environments
    # exec hosts
    # local configurations

    # Capture the output of "-sXl"
    # (list of all things of that type)
    qconf_opt="s${conf}l"

    entries=$(qconf -${qconf_opt})
    echo "$entries" > ${output_dir}/qconf.${qconf_opt}

    # Capture the output of "-sX"
    # (information for each thing in the list above)
    qconf_opt="s${conf}"

    details_file="${output_dir}/qconf.${qconf_opt}.entries"

    # Remove existing file to avoid appending to it
    if [[ -f $details_file ]]; then
        rm $details_file
    fi

    echo -n "Getting $conf entries" >&2

    # Append output for each thing in the list
    for entry in $entries; do
        echo -n "." >&2
        qconf -${qconf_opt} "$entry" >> $details_file 2>&1
        echo >> $details_file
    done

    echo >&2
done

# settings of the form -X
echo -n "Dumping configs" >&2

for conf in sc sh ss sep sds so sm sss ssconf stl sconf; do
    # complexes
    # exec hosts
    # admin hosts
    # submit hosts
    # licensed processors
    # detached settings (orphaned)
    # operators
    # managers
    # scheduler state (returns qmaster hostname)
    # scheduler configuration
    # thread list
    # global configuration (same as "qconf -sconf global")

    echo -n "." >&2
    
    qconf -${conf} > ${output_dir}/qconf.$conf 2>&1

done

echo >&2

# manual commands

# event clients
# qconf -secl has "pretty" output and has to be handled differently
qconf_output=$(qconf -secl)

echo "$qconf_output" > ${output_dir}/qconf.secl

echo -n "Getting ec entries" >&2

details_file="${output_dir}/qconf.sec.entries"
if [[ -f $details_file ]]; then
    rm $details_file
fi

for entry in $(echo "$qconf_output" | awk 'NR >= 3 { print $2 }'); do
    echo -n "." >&2
    qconf -sec $entry >> $details_file 2>&1
    echo >> $details_file
done

echo >&2

# common commands
# qstat

echo -n "Getting qstat output" >&2

for flag in f 'u \*' 'g c'; do
    # full output
    # all jobs
    # queue summary

    echo -n "." >&2

    safe_flag=$(echo "$flag" | sed 's/ /_/g')

    # use bash -c to make the space in "u \*" work
    bash -c "qstat -${flag}" >> ${output_dir}/qstat.${safe_flag} 2>&1
done

echo >&2

# qhost

# plain qhost
qhost >> ${output_dir}/qhost 2>&1

# qhost flags
echo -n "Getting qhost output" >&2

for flag in F q; do
    # list hosts
    # show resources
    # queues hosted by host

    echo -n "." >&2
    
    safe_flag=$(echo "$flag" | sed 's/ /_/g')

    qhost -${flag} >> ${output_dir}/qhost.${safe_flag} 2>&1
done

echo >&2

archive_file="$output_dir.tar.gz"

echo "Making archive: $archive_file" >&2

tar cfz $archive_file $output_dir

echo "Done." >&2 

# Skipping the following because we don't use them

# from UGE 8.5.4 qconf -help

# calendars
#   [-scal calendar_name]                    show given calendar
#   [-scall]                                 show a list of all calendar names

# ckpt interfaces
#   [-sckpt ckpt_name]                       show ckpt interface definition
#   [-sckptl]                                show all ckpt interface definitions

# DRMAA
#   [-sdjs]                                  show details of a DRMAA2 job session
#   [-sdjsl]                                 show a list of all usable DRMAA2 job sessions
# not in 8.3.1p6
#   [-sdrs]                                  show details of a DRMAA2 reservation session
#   [-sdrsl]                                 show a list of all usable DRMAA2 reservation sessions
#   [-sdsl]                                  show a list of all usable DRMAA2 sessions

# job classes
#   [-sjc jc_name]                           show job class
#   [-sjcl]                                  show job class list

# sessions
#   [-ssi session_id]                        show parameters of a session
#   [-ssil]                                  show list of all existing sessions

# sharetree
#   [-sstnode node_list]                     show sharetree node(s)
#   [-rsstnode node_list]                    show sharetree node(s) and its children
#   [-sst]                                   show a formated sharetree
#   [-sstree]                                show the sharetree
