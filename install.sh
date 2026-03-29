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
cp .monoclerc $HOME

if [ ":$PATH:" != *":$BIN:"* ]; then
    export PATH=$PATH:$BIN
fi

# Aliases
if [ `alias | grep ^myjobs | wc -l` == 0 ]; then
    echo "alias myjobs='qstat -u $USER'" >> ~/.common_aliases
fi
if [ `alias | grep ^labjobs | wc -l` == 0 ]; then
    echo "alias labjobs='qstat -q trapnell'" >> ~/.common_aliases
fi
if [ `alias | grep ^gpujobs | wc -l` == 0 ]; then
    echo "alias gpujobs='labjobs | grep -E \"t0(01|05|08|10|11)\"'" >> ~/.common_aliases
fi
echo "Please add the following line to your ~/.bashrc or related shell configuration file to ensure the new aliases are available in future sessions:"
echo "source ~/.common_aliases"
