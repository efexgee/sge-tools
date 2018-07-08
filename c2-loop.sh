#!/bin/bash

if (( $# != 3 )); then
    echo "$0 <rack> <start U> <end U>"
    exit
fi

rack=$1
begin=$2
end=$3

for (( ru=$begin; ru <= $end; ru++ )); do
    for side in 1 2; do
        echo "c2-6f${rack}-${ru}-${side}"
    done
done
