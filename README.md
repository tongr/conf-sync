# conf-sync
Synchronization scripts for linux configration files

## Installation
To create a local installation run (necessary packages: curl sudo):
```sh
bash -c "$(curl -fsSL http://git.io/va5Ka )"
```
Git.io is used for convenience (original url: https://raw.githubusercontent.com/tongr/conf-sync/master/install.sh).
Instead of the default https-URLs (https://github.com/tongr/conf-sync.git) you can also use ssh-URLs (i.e., for usage with SSH keypairs): git@github.com:tongr/conf-sync.git (see https://help.github.com/articles/changing-a-remote-s-url/)
To prevent accidental pushs execute:
```sh
git remote set-url --push origin "you really don't want to do that"
```
