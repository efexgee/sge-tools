#!/bin/bash

# Clears error states on cluster nodes (actually queue instances)
# but supports a list of queues to ignore and only clears nodes
# which are actually in an error state. This keeps this job from
# wiping admin messages attached to the nodes by the sanity_check
# script and the d-node alias.

# Falko 1/19/2018

#TODO Figure out which states we should be auto-clearing
#TODO Test that this handles nodes with multiple queues

# UGE message
MESSAGE="auto-enabled by $(basename $0)"
message="$(date +'%D %T') $MESSAGE"

# list of all UGE states
ALL_STATES='acdosuACDES'

# list of states to exclude
EXCLUDE_STATES+='d' # 'd' means manually disabled
EXCLUDE_STATES+='s' # '-cq' won't clear 's' anyway

# queues to ignore
EXCLUDE_QUEUES='test.q geospatial-test.q'

# assemble an UGE wildcard string to exclude queues
queue_wildcard=$(echo "$EXCLUDE_QUEUES" | 
                    sed 's/.*/!(&)/' | 
                    tr ' ' '|')

echo "Matching queues: $queue_wildcard" >&2

# build regex to match queue states

# if there are states to exclude, exclude them
if [[ -n $EXCLUDE_STATES ]]; then
    STATES=$(echo $ALL_STATES | tr -d $EXCLUDE_STATES)
else
    STATES=$ALL_STATES
fi

echo "Matching states: $STATES" >&2

echo

# the ^$ makes the list exclusive so we can
# exclude states like d
regex="^[$STATES]+$"

queues=$(qstat -f -q "$queue_wildcard" |
awk -v states=$regex '{ if ( $6 ~ states ) { print } }' |
egrep -o '^[^@]*@[^.]*')

if [[ -n $queues ]]; then
    if [[ -n $MESSAGE ]]; then
        echo $queues | xargs qmod -msg "$message" -cq 
    else
        echo $queues | xargs qmod -cq
    fi
else
    echo "No queues to enable" >&2
fi
