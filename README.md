# conf-sync
Synchronization scripts for linux configration files

## Installation
To create a local installation run (necessary packages: curl sudo):
```sh
bash -c "$(curl -fsSL http://git.io/va5Ka)"
```
Git.io is used for convenience (original url: https://raw.githubusercontent.com/tongr/conf-sync/master/install.sh).
Instead of the default https-URLs (https://github.com/tongr/conf-sync.git) you can also use ssh-URLs (i.e., for usage with SSH keypairs): git@github.com:tongr/conf-sync.git (see https://help.github.com/articles/changing-a-remote-s-url/)
To prevent accidental pushs execute:
```sh
git remote set-url --push origin "you really don't want to do that"
```

There are some predefined scripts that install basic software packages and settings:
 1. To set up a desktop environment:
    ```bash
    curl --progress-bar --fail "https://raw.githubusercontent.com/tongr/conf-sync/master/install/ubuntu-desktop.sh" --output install-ubuntu-desktop.sh; \
    bash install-ubuntu-desktop.sh;
    ```

## Keyboard setup
In order to support German umlauts follow the following description: https://askubuntu.com/a/1007440

