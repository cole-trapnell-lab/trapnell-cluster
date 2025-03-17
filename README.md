# trapnell-cluster
This repository contains common scripts one might use while working on Nexus.

## Installation
Run:
```sh
install.sh
```

This will create the following directories in `$HOME`, if they do not exist already:
- `bin`: executable scripts
- `sge`: scripts that get submitted as jobs
- `nobackup/log`: a place for logfiles

Additionally, it will add `$HOME/bin` to your `$PATH` if it is not already present.

## Usage
Currently this repo only contains a script to submit a VSCode server that can be run remotely. To use it, simply type `serve_vscode`. Additional usage details are available in the script.