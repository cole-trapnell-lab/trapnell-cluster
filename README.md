# trapnell-cluster
This repository contains common scripts one might use while working on Nexus.

## Installation
Run:
```sh
./install.sh
```

This will create the following directories in `$HOME`, if they do not exist already:
- `bin`: executable scripts
- `sge`: scripts that get submitted as jobs
- `nobackup/log`: a place for logfiles

Additionally, it will add `$HOME/bin` to your `$PATH` if it is not already present.

## Usage
Currently this repo only contains a script to submit a VSCode server that can be run remotely. To use it, simply type `serve_vscode`. Additional usage details are available in the script. To use VSCode remotely, you will also have to install the [Remote Development Extension Pack](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.vscode-remote-extensionpack). Read how to set up you local VS Code instance to connect to a Remote Tunnel [here](https://code.visualstudio.com/docs/remote/tunnels#_remote-tunnels-extension). You'll also probably want to set it up for [R Development](https://code.visualstudio.com/docs/languages/r).

## Contributing
If you would like to contribute modifications or additional cluster helpers, please create a branch and open a pull request for an admin to review.
