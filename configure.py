from __future__ import print_function
from abc import ABCMeta
from builtins import input
import os
import shutil
import subprocess
import sys

from distutils.spawn import find_executable
import getpass
import tempfile
from os.path import expanduser, join, exists

HOME = expanduser("~")


class Exec:
    def __init__(self):
        self.sudo_file = None

    def __del__(self):
        self.unset_pw()

    def set_pw(self):
        name = None
        try:
            fd, name = tempfile.mkstemp(text=True)
            print("Created temp-file {} ...".format(name))
            os.write(fd,
                     "#!/bin/sh\necho '{}'".format(getpass.getpass("Please enter the password to use sudo:")).encode())
            os.fchmod(fd, 0o700)
            os.close(fd)
            self.unset_pw()
        except Exception:
            if name:
                shutil.rmtree(name, ignore_errors=True)
            raise
        self.sudo_file = name

    def unset_pw(self):
        if self.sudo_file:
            print("Deleting {} ...".format(self.sudo_file))
            os.remove(self.sudo_file)
            self.sudo_file = None

    @staticmethod
    def is_root():
        return getpass.getuser() == "root"

    def init_sudo(self):
        if not self.sudo_file:
            self.set_pw()
            os.environ['SUDO_ASKPASS'] = self.sudo_file

    def run_as_root(self, cmd):
        if self.is_root():
            # run command directly
            return self.run(cmd)
        else:
            # run command with sudo
            self.init_sudo()
            return self.run(["/usr/bin/sudo", "-A"] + cmd.split())

    @staticmethod
    def run(cmd, log=True):
        if isinstance(cmd, str):
            cmd = cmd.split()
        try:
            if not log:
                devnull = open(os.devnull, 'w')
                return subprocess.call(cmd, stdout=devnull, stderr=devnull) == 0
            else:
                return subprocess.call(cmd) == 0
        except Exception:
            return False

    @staticmethod
    def is_installed(command):
        return find_executable(command) is not None
        #return shutil.which(command) is not None


class PackageManager(object):
    __metaclass__ = ABCMeta
    # # fixme init: "sudo apt-get update",
    # @staticmethod
    # def __apt():
    #     return PackageManager(
    #         name="apt",
    #         init=lambda exe: exe.is_installed("apt") and exe.run_as_root("apt update"),
    #         install_template="apt -y install {package}",
    #     )
    #
    # @staticmethod
    # def __yum():
    #     return PackageManager(
    #         name="yum",
    #         init=lambda exe: exe.is_installed("yum"),
    #         install_template="yum install -y {package}",
    #     )
    #
    # @staticmethod
    # def __pacman():
    #     return PackageManager(
    #         name="pacman",
    #         init=lambda exe: exe.is_installed("pacman"),
    #         install_template="pacman -S {package}",
    #     )
    #
    # @staticmethod
    # def __snap():
    #     return PackageManager(
    #         name="snap",
    #         init=lambda exe: exe.is_installed("snap"),
    #         install_template="snap install {package}",
    #         installer=Software("snap", all="snapd"),
    #     )
    #
    # @staticmethod
    # def __flatpak():
    #     return PackageManager(
    #         name="flatpak",
    #         init=lambda exe: exe.is_installed("flatpak"),
    #         install_template="flatpak install {package}",
    #         installer=Software("flatpak", pacman="flatpak", yum="flatpak"),
    #     )
    #
    # @staticmethod
    # def __manual():
    #     return PackageManager(
    #         name="manual",
    #         init=lambda _: True,
    #         install_template=None,
    #         installer="manual installation",
    #     )

    @classmethod
    def basics(cls):
        return {name: pm for name, pm in cls.all().items() if pm.installer is None}

    @classmethod
    def manual(cls):
        return cls.get("manual")

    __all = {}

    @classmethod
    def all(cls):
        if not cls.__all:
            cls.__all = {
                "apt": Apt(),
                "pacman": Pacman(),
                "yum": Yum(),
                "snap": Snap(),
                "flatpak": Flatpak(),
                "manual": Manual(),
            }
        return cls.__all

    @classmethod
    def get(cls, item):
        return cls.all()[item]

    def __init__(self, name, install_template, installer=None):
        self.name = name
        self.install_template = install_template
        self.installer = installer

    def init(self, executor):
        return executor.is_installed(self.name)



class Apk(PackageManager):
    def __init__(self):
        super(Apk, self).__init__("apk", "apk add {package}")


class Apt(PackageManager):
    def __init__(self):
        super(Apt, self).__init__("apt", "apt -y install {package}")

    def init(self, executor):
        return executor.is_installed("apt") and executor.run_as_root("apt update")


class Yum(PackageManager):
    def __init__(self):
        super(Yum, self).__init__("yum", "yum install -y {package}")


class Pacman(PackageManager):
    def __init__(self):
        super(Pacman, self).__init__("pacman", "pacman --noconfirm -S {package}")

    def init(self, executor):
        return executor.is_installed("pacman") and executor.run_as_root("pacman --noconfirm -Syu")
        # and executor.run_as_root("pacman --noconfirm -Sy archlinux-keyring")

class Snap(PackageManager):
    def __init__(self):
        super(Snap, self).__init__("snap", "snap install {package}", installer=Software("snap", all="snapd"))


class Flatpak(PackageManager):
    def __init__(self):
        super(Flatpak, self).__init__(name="flatpak",
                                      install_template="flatpak install {package}",
                                      installer=Software("flatpak", pacman="flatpak", yum="flatpak"))


class Manual(PackageManager):
    def __init__(self):
        super(Manual, self).__init__(name="manual",
                                     install_template=None,
                                     installer="manual installation")

    def init(self, executor):
        return True


class Software:
    def __init__(self, name, as_sudo=True, **kwargs):
        packages = {}
        # try to get the "default" package name (all)
        if "default" in kwargs:
            default = kwargs["default"]
            for man_name in PackageManager.basics():
                # add package for all default package managers
                packages[man_name] = default
            del kwargs["default"]

        if "manual" in kwargs:
            assert "check" in kwargs, "Expecting check definition for manual installers"

        # try to get the "checker" to find out if the software is already installed
        if "check" in kwargs:
            check = kwargs["check"]
            del kwargs["check"]
        else:
            check = None

        # package manager specific package names
        for key, value in kwargs.items():
            try:
                packages[key] = value
            except KeyError:
                print("unknown package manager {} ..".format(key), file=sys.stderr)
                del packages[key]
        self.name = name
        self.packages = packages
        self.explicit_check = check
        self.as_sudo = as_sudo

    @property
    def installers(self):
        return [pman for pman in self.packages.keys()]

    def exists(self, executor):
        if self.explicit_check:
            return self.explicit_check(executor)
        return executor.is_installed(self.name)


basics = [
    Software(
        "basics",
        default="git htop tmux wget curl",
        check=lambda executor: all(find_executable(cmd) is not None for cmd in "git htop tmux wget curl".split())
    ),
    Software("git", default="git"),
    Software("htop", default="htop"),
    Software("tmux", default="tmux"),
    Software("wget", default="wget"),
    Software("curl", default="curl"),
    Software("ssh", apt="openssh-client", yum="openssh-clients", pacman="openssh", apk="openssh-client"),
    Software("ssh-key",
             as_sudo=False,
             manual=["ssh-keygen", "echo new public key:", "cat {}/.ssh/id_rsa.pub".format(HOME)],
             check=lambda _: exists(join(HOME, ".ssh/id_rsa.pub"))),
    Software("zsh", default="zsh"),
    # TODO
    #  oh-my-zsh .. manual
    #    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    #  oh-my-zsh .. plugins
    #    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    #    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
]


def writer_def(content, path, mode="W"):
    def write():
        with open(path, mode=mode) as fd:
            fd.write(content)
        return True

    return write


desktop_list = [
    Software("tilda", default="tilda"),
    Software(
        "tilda-autostart",
        check=lambda _: exists(join(HOME, ".config/autostart/Terminal.desktop")),
        manual=[
            writer_def(path=join(HOME, ".config/autostart/Terminal.desktop"),
                       content="""\
[Desktop Entry]
Type=Application
Name=Dropdown Terminal (Tilda)
Exec=tilda
X-GNOME-Autostart-enabled=true
""")
        ],
    ),
    Software("guake", default="guake"),
    Software(
        "guake-autostart",
        check=lambda _: exists(join(HOME, ".config/autostart/Terminal.desktop")),
        manual=[
            writer_def(path=join(HOME, ".config/autostart/Terminal.desktop"),
                       content="""\
[Desktop Entry]
Type=Application
Name=Dropdown Terminal (Guake)
Exec=guake
X-GNOME-Autostart-enabled=true
        """)
        ],
    ),
    # TODO
    #  sudo snap install intellij-idea-community --classic
    #  sudo snap install pycharm-community --classic
    #   .. Pro versions of the above
    #  sudo snap install git-cola
    #  sudo snap install gitkraken
]

develop_list = [
    Software("java", apt="openjdk-11-jdk", pacman="jdk11-openjdk", yum="java-11-openjdk-devel"),
    Software("maven", default="maven"),
    Software(
        "git-flow",
        apt="git-flow",
        check=lambda executor: executor.run("git flow version"),
        manual=[
            "wget -q https://raw.githubusercontent.com/petervanderdoes/gitflow-avh/develop/contrib/gitflow-installer.sh",
            "sudo bash gitflow-installer.sh install stable",
            "rm gitflow-installer.sh",
        ],
    ),
    Software(
        "docker",
        apt=[
            "apt-get -y install apt-transport-https ca-certificates curl gnupg-agent software-properties-common",
            "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -",
            'add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"',
            "apt-get update",
            "apt-get -y install docker-ce docker-ce-cli containerd.io",
            'curl -L "https://github.com/docker/compose/releases/download/1.25.5/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose',
            "chmod +x /usr/local/bin/docker-compose",
        ],
        yum=[
            "yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo",
            "yum install -y docker-ce docker-ce-cli containerd.io",
            'curl -L "https://github.com/docker/compose/releases/download/1.25.5/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose',
            "chmod +x /usr/local/bin/docker-compose",
        ],
        pacman="docker",
        # TODO? sudo usermod -aG docker $USER
    ),
    Software(
        "conda",
        as_sudo=False,
        manual=[
            "wget --show-progress https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh",
            "bash Miniconda3-latest-Linux-x86_64.sh",
            writer_def(
                path=join(HOME, ".zshrc"),
                mode="a",
                content="""
# activate conda
source "${HOME}/miniconda3/etc/profile.d/conda.sh"
            """),
            "rm Miniconda3-latest-Linux-x86_64.sh",
        ],
        check=lambda _: exists(join(HOME, "miniconda3")),
    ),
]

# TODO
#  check which programs are available (apt, yum, ...)
#  update repositories
#  go through all software packages and ask the user which to install, he has the following options:
#    skip: do neither check nor install
#    normal: does check before executing the install commands and after (if after check fails, give warning/error ..)
#    force: does not before executing the install commands but checks afterwards (if check fails, error/warning)
#  try to find an existing & compatible installer go through all installers .. if init() fails, check next try to identify installed additional_installer
#  run the installer:
#    1. if single package_def (str): exec.run_as_root(PM.install_template.format(package=package_def))
#    2a. if instruction set (list of str): run the individual commands (run_as_root(cmd1),run_as_root(cmd2),...) or ...
#    2b. if it is a callable: execute the callable


def try_install(cli, software, pman, executor):
    package_def = software.packages[pman.name]
    run = executor.run
    if software.as_sudo:
        run = executor.run_as_root

    cli.info("Trying to install {} via {} ...".format(software.name, pman.name))
    success = True
    # here we are lets try to execute the installer
    if isinstance(package_def, str):
        success = run(pman.install_template.format(package=package_def))
    else:
        # we do not have a single package definition here but a sequence of commands
        for command in package_def:
            if isinstance(command, str):
                success &= run(command)
            else:
                success &= command()

    if success:
        cli.success("Installation of {} via {} sucessful!".format(software.name, pman.name))
    return success


class ColoredConsole:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

    def error(self, msg):
        print(ColoredConsole.FAIL + msg + ColoredConsole.ENDC)

    def success(self, msg):
        print(ColoredConsole.OKGREEN + msg + ColoredConsole.ENDC)

    def info(self, msg):
        print(ColoredConsole.OKBLUE + msg + ColoredConsole.ENDC)

    def question(self, question, default="yes"):
        """Ask a yes/no/force question

        The "answer" return value is "y" for "yes" or "n" for "no".
        """
        valid = {"yes": True, "y": True, "ye": True,
                 "no": False, "n": False}
        if default is None:
            prompt = " [y/n] "
        elif default == "yes":
            prompt = " [Y/n] "
        elif default == "no":
            prompt = " [y/N] "
        else:
            raise ValueError("invalid default answer: '%s'" % default)

        while True:
            choice = input(ColoredConsole.WARNING + question + prompt + ColoredConsole.ENDC).lower()
            if default is not None and choice == '':
                return valid[default]
            elif choice in valid:
                return valid[choice]
            else:
                sys.stdout.write("Please respond with 'y' or 'n'.\n")


def start():
    cli = ColoredConsole()
    executor = Exec()
    installers = {name: base_man.init(executor) for name, base_man in PackageManager.basics().items()}
    installers["manual"] = True

    for software in basics:
        if not software.exists(executor) and cli.question("Do you want to install {}?".format(software.name)):
            for name in software.installers:
                pman = PackageManager.get(name)
                if pman not in installers:
                    pm_init = pman.init(executor)
                    if isinstance(pm_init, Software):
                        for base_pm, package in pm_init.packages.items():
                            if try_install(cli, pman=base_pm, software=software, executor=executor):
                                pm_init = pman.init(executor)
                                break
                    installers[pman] = pm_init
                if not installers[pman]:
                    continue
                if try_install(cli, pman=pman, software=software, executor=executor):
                    break

            if not software.exists(executor):
                cli.error("Unable to install `{}`!".format(software.name))


if __name__ == '__main__':
    start()
