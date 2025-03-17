#!/bin/bash
BIN=$HOME/bin
SGE=$HOME/sge
mkdir -p $BIN
mkdir -p $SGE
mkdir -p $HOME/nobackup/log

for script in $(ls src); do
    DESTINATION=$BIN/$(basename $script)
    cp src/$script $DESTINATION
    chmod +x $DESTINATION
done

cp src/* $SGE