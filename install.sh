#!/bin/bash
BIN=$HOME/bin
SGE=$HOME/sge
mkdir -p $BIN
mkdir -p $SGE
mkdir -p $HOME/nobackup/log

for script in $(ls src/*.sh); do
    DESTINATION=$BIN/$(basename $script .sh)
    cp $script $DESTINATION
    chmod +x $DESTINATION
done

cp sge/* $SGE

if [ ":$PATH:" != *":$BIN:"* ]; then
    export PATH=$PATH:$BIN
fi
