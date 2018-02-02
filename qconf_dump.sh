#!/bin/bash

# settings of the form -sXl
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

    qconf_opt="s${conf}l"

    entries=$(qconf -${qconf_opt})
    echo "$entries" > qconf.${qconf_opt}

    qconf_opt="s${conf}"

    details_file="qconf.${qconf_opt}.entries"

    if [[ -f $details_file ]]; then
        rm $details_file
    fi

    echo -n "Getting $conf entries" >&2

    for entry in $entries; do
        echo -n "." >&2
        qconf -${qconf_opt} "$entry" >> $details_file 2>&1
        echo >> $details_file
    done

    echo >&2
done

# event clients
# qconf -secl has "pretty" output and has to be handled differently
qconf_output=$(qconf -secl)

echo "$qconf_output" > qconf.secl

echo -n "Getting ec entries" >&2

details_file="qconf.sec.entries"
if [[ -f $details_file ]]; then
    rm $details_file
fi

for entry in $(echo "$qconf_output" | awk 'NR >= 3 { print $2 }'); do
    echo -n "." >&2
    qconf -sec $entry >> $details_file 2>&1
    echo >> $details_file
done

echo >&2

# settings of the form -X
echo -n "Dumping configs" >&2

for conf in sc sh ss sep sds so sm sss ssconf stl; do
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

    echo -n "." >&2
    
    qconf -${conf} > qconf.$conf 2>&1

done

echo >&2

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
