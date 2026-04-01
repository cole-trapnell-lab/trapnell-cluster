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
ALIAS_FILE=$HOME/.common_aliases
if [ ! -f $ALIAS_FILE ]; then
    touch $ALIAS_FILE
fi
if [  $(grep myjobs $ALIAS_FILE | wc -l) == 0 ]; then
    echo "alias myjobs='qstat -u $USER'" >> $ALIAS_FILE
fi
if [ $(grep labjobs $ALIAS_FILE | wc -l) == 0 ]; then
    echo "alias labjobs='qstat -q trapnell'" >> $ALIAS_FILE
fi
if [ $(grep gpujobs $ALIAS_FILE | wc -l) == 0 ]; then
    echo "alias gpujobs='labjobs | grep -E \"t0(01|05|08|10|11)\"'" >> $ALIAS_FILE
fi

echo "✅ Installation complete!"
echo "ℹ️  Note that for some shortcuts to work, you must add the following line to your ~/.bashrc or related shell configuration file:"
echo "source $ALIAS_FILE"
