# trapnell-cluster

This repository contains common scripts and utilities one might use while working on Nexus. It is meant to help our lab work on our cluster; it is not intended to be portable to other setups. Your mileage may vary.

## Installation

### On your own computer

Edit your `~/.ssh/config` file to contain the following:
```
Host *.gs.washington.edu
    User <your-GS-username-here>
    EnableEscapeCommandline yes
```

This gives you a shortcut to log onto Nexus by simply typing `ssh nexus` instead of the longer `ssh <username>@nexus.gs.washington.edu`.

### On Nexus

Run:
```sh
./install.sh
```

This will create the following directories in `$HOME`, if they do not exist already:
- `bin`: executable scripts
- `sge`: scripts that get submitted as jobs
- `nobackup/log`: a place for logfiles

Additionally, it will add `$HOME/bin` to your `$PATH` if it is not already present.

> [!IMPORTANT]
> Please be sure to add `source ~/.common_aliases` to your `~/.bashrc` file (or similar for other shells) in order for some of the aliases to be usable.

## Usage

### VSCode Server

To submit a VSCode server that can be run remotely, simply type `serve_vscode`. Additional usage details are available by running `serve_vscode -h`. To use VSCode remotely, you will also have to install the [Remote Development Extension Pack](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.vscode-remote-extensionpack). Read how to set up you local VS Code instance to connect to a Remote Tunnel [here](https://code.visualstudio.com/docs/remote/tunnels#_remote-tunnels-extension). You'll also probably want to set it up for [R Development](https://code.visualstudio.com/docs/languages/r).

### Monocle3

A file will be created in your home directory called `.monoclerc`. This file contains startup instructions so that BPCells temporary directories are written to a directory in `/tmp` if possible and a `nobackup` directory otherwise. This prevents temporary directories from being backed up to tape.

> [!NOTE]
> Monocle3 is configured to automatically clean up after itself when quitting R. To do this properly, you must run `q()` in an interactive session. However, if you close out of VS Code before quitting, or your job dies before completing, Monocle3 will not clean up the temporary directories. To safeguard against this, you can configure a cronjob to run on a regular basis and remove any stale Monocle3 temporary directories. Run `crontab -e` and then enter something like the following:
```sh
0 18 * * 0 find $HOME/nobackup -mindepth 1 -type d -name 'monocle*' -mtime +7 -exec rm -rf {} +
```
> - `0 18 * * 0` means "every Sunday at 6pm"
> - `find $HOME/nobackup -mindepth 1 -type d -name 'monocle*' -mtime +7` means "find any directories starting with `monocle` in `$HOME/nobackup` that are at least a week old."
> - `-exec rm -rf {} +` removes all those directories.

### Cluster utilities

You can quickly check the status of jobs in the queue by running `myjobs`. You can similarly check the status of all jobs in the lab queue by running `labjobs` and all jobs running on nodes with GPUs availabe by running `gpujobs`.

### Disc usage

Check how much storage we have available as a lab:
```sh
df -h /net/trapnell/vol1
```

Check the size of a directory:
```sh
du -h -d 0 \<dirname\>
```

Check the size of a directory and all directories one level deep:
```sh
du -h -d 1 \<dirname\>
```

GS IT runs a full audit of disc usage once a month. To view it, start an interactive job with 8G and then run:
```sh
cd /net/trapnell/vol1/diskusage
bzcat \<filename\>  ncdu -f -
```

### Nextflow

Nextflow work should be placed in a `nobackup` directory. To do this, you can either add `workDir = "nobackup/work"` or add `-work-dir nobackup/work` to your `nextflow run` command.

You can view the status of all your past Nextflow runs by running `nextflow log`. To view more specific details about a specific run, run:
```sh
nextflow log -f name,status,attempt,realtime,workdir \<runname\>
```

Work directories can take up a lot of space. When you are done with a Nextflow run, delete it with `nextflow clean -f \<runname\>`. The outputs will still be saved in the `publishDir` specified in the config.

## Contributing

If you would like to contribute modifications or additional cluster helpers, please create a branch and open a pull request for an admin to review.
