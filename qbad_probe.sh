#!/bin/bash

source ~/.dotfiles/.cluster_src

# Column width for fields (sized for col headers)
NODE_PAD=13
STATE_PAD=5
PING_PAD=0
SSH_PAD=0
JOBS_PAD=4

# Timeouts
PING_TIMEOUT=1
SSH_TIMEOUT=1

# Values for failed tests
PING_FAIL="P"
SSH_FAIL="S"

# Main

qbad_output=$(qbad)

bad_nodes=$(echo "$qbad_output" | grep -Po '(?<=@)[^.]*')
#bad_nodes=$(echo "$qbad_output" | head -30 | tail -10 | grep -Po '(?<=@)[^.]*')

printf "%-${NODE_PAD}s %${STATE_PAD}s %${PING_PAD}s %${SSH_PAD}s %${JOBS_PAD}s\n" "Node" "State" "P" "S" "Jobs"
echo

for node in $bad_nodes; do
    # Values for healthy test outcomes
    ping_test=" "
    ssh_test=" "

    # This will break if the node appears more than once in the list
    # e.g. if it's in two queues
    queue_state=$(echo "$qbad_output" | grep "@${node}\." | awk '{print $NF}')

    if ! ping -q -c 1 -W $PING_TIMEOUT $node > /dev/null; then
        ping_test="$PING_FAIL"
    elif ! nc -w $SSH_TIMEOUT -z $node 22 > /dev/null; then
        # Only check ssh if ping succeeded
        ssh_test="$SSH_FAIL"
    else
        # Only run ssh commands if ssh test passes
        :
    fi

    # 'qhjobs' now labels "MASTER" jobs "MAIN"
    job_count=$(qhjobs $node | grep -c MAIN)

    if (($job_count == 0)); then
        job_count=" "
    fi

    printf "%-${NODE_PAD}s %${STATE_PAD}s %${PING_PAD}s %${SSH_PAD}s %${JOBS_PAD}s\n" $node "$queue_state" "$ping_test" "$ssh_test" "$job_count"
done
