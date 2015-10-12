# conf-sync
Synchronization scripts for linux configration files

## Preparation
To use conf-sync you need a private git Repositpory. For instance, you can host the a private fork on GitHub.
To create a private GitHub fork use https://import.github.com/new. As base repository use the URL of this project (https://github.com/conf-sync/conf-sync).

Please note, instead of the shown https-URLs you can also use ssh-URLs (i.e., for usage with SSH keypairs). For instance, https://github.com/tongr/conf-sync.git can be relaced by git@github.com:conf-sync/conf-sync.git. For further information see https://help.github.com/articles/changing-a-remote-s-url/.

## Installation
To create a local installation run:
```sh
curl -L http://git.io/vcNms -o install-conf-sync.sh
bash install-conf-sync.sh
```
Note, Git.io is used for more convenience, the original url is https://raw.githubusercontent.com/conf-sync/conf-sync/master/install.sh.

## Upgrades
To get upgrades, add the upstream repository to your local installation (prevent accidental pushing of private configs):
```sh
git remote add upstream https://github.com/conf-sync/conf-sync.git
git remote set-url --push upstream "you really don't want to do that"
```
An upgrade can then be performed by:
```sh
git pull upstream master
```
