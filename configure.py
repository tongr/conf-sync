from __future__ import print_function
try:
  basestring
except NameError:
  basestring = str
try:
    # noinspection PyShadowingBuiltins
    input = raw_input
except NameError:
    pass

import getpass
import json
import os
import shutil
import subprocess
import sys
import tempfile
from abc import ABCMeta
from collections import OrderedDict
from os.path import dirname, exists, expanduser, expandvars

from distutils.spawn import find_executable

HOME = expanduser("~")


class PackageManager(object):
    __metaclass__ = ABCMeta

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
                "apk": Apk(),
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

    def init(self, cli):
        return cli.is_installed(self.name)

    def install_cmd(self, packages):
        return self.install_template.format(package=packages)


class Apk(PackageManager):
    def __init__(self):
        super(Apk, self).__init__("apk", "apk add {package}")


class Apt(PackageManager):
    def __init__(self):
        super(Apt, self).__init__("apt", "apt -y install {package}")

    def init(self, cli):
        return cli.is_installed("apt") and cli.run_as_root("apt update")


class Yum(PackageManager):
    def __init__(self):
        super(Yum, self).__init__("yum", "yum install -y {package}")


class Pacman(PackageManager):
    def __init__(self):
        super(Pacman, self).__init__("pacman", "pacman --noconfirm -S {package}")

    def init(self, cli):
        return cli.is_installed("pacman") and cli.run_as_root("pacman --noconfirm -Syu")


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
                                     install_template="{package}",
                                     installer="manual installation")

    def init(self, cli):
        return True


class Software:
    def __init__(self, name, description=None, requirements=None, as_sudo=True, flavors=None, check_available=None, **kwargs):
        packages = {}
        # try to get the "default" package name (all)
        if "default" in kwargs:
            default = kwargs["default"]
            for man_name in PackageManager.basics():
                # add package for all default package managers
                packages[man_name] = default
            del kwargs["default"]

        # package manager specific package names
        for key, value in kwargs.items():
            try:
                if value:
                    packages[key] = value
                elif key in packages:
                    # explicitly set to None / empty package: remove install possibility for this manager
                    del packages[key]
            except KeyError:
                print("Unknown package manager {} ..".format(key), file=sys.stderr)
                del packages[key]
        self.name = name
        self.description = description if description else name
        self.as_sudo = as_sudo

        self.flavors = flavors if flavors else {}
        # in case there are flavor choices we have to
        self.flavors_selected = not self.flavors

        self.__unflavored_packages = packages
        self.__requirements = requirements
        self.__check_available = check_available

    def packages(self, package_manager):
        assert self.flavors_selected, "Error, flavors not yet selected!"
        unflavored_package_def = self.__unflavored_packages[package_manager]

        if isinstance(unflavored_package_def, basestring):
            return self.__add_flavors(unflavored_package_def)

        return [self.__add_flavors(pack) if isinstance(pack, basestring) else pack for pack in unflavored_package_def]

    @property
    def installers(self):
        return [pman for pman in self.__unflavored_packages.keys()]

    def choose_flavors(self, choices):
        assert self.flavors.keys() == choices.keys(),\
            "Flavor selection `%s` differences from available options `%s`" % (list(choices), list(self.flavors))
        self.flavors_selected = True
        self.flavors = choices

    def install_via(self, cli, package_manager):
        execute = cli.run
        if self.as_sudo:
            execute = cli.run_as_root

        def flavored_packages(definition):
            return package_manager.install_cmd(self.__add_flavors(definition))

        return cli.run_all(
            cmds=self.packages(package_manager.name),
            default_action=execute,
            value_wrapper=flavored_packages,
            log=True,
        )

    def check_requirements(self, cli):
        if self.__requirements is None:
            return True
        return cli.run_all(
            cmds=self.__requirements,
            default_action=cli.is_installed,
            value_wrapper=self.__add_flavors,
        )

    def is_available(self, cli):
        checks = self.__check_available
        if checks is None:
            checks = self.name
        return cli.run_all(
            cmds=checks,
            default_action=cli.is_installed,
            value_wrapper=self.__add_flavors,
        )

    def __add_flavors(self, unflavored):
        return expandvars(unflavored).format(**self.flavors)

    @classmethod
    def parse_list(cls, file):
        with open(file, mode="r") as fp:
            # it would be much nicer if we could use yaml instead of json, however, python 2.7 does not support yaml out
            # of the box
            all_definitions = json.load(fp, object_pairs_hook=OrderedDict)

        return [cls(name=name, **params) for name, params in all_definitions.items()]

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


class ColoredConsole:
    BLUE = "\033[94m"
    GREEN = "\033[92m"
    ORANGE = "\033[93m"
    GRAY = "\033[37m"
    RED = "\033[91m"
    BOLD = "\033[1m"
    UNDERLINE = "\033[4m"
    ENDC = "\033[0m"

    FRAME_HORIZONTAL = u"\u2550"
    FRAME_VERTICAL = u"\u2551"
    FRAME_LEFT_TOP = u"\u2554"
    FRAME_RIGHT_TOP = u"\u2557"
    FRAME_LEFT_BOTTOM = u"\u255A"
    FRAME_RIGHT_BOTTOM = u"\u255D"
    FRAME_SEP = u"\u2500"
    FRAME_LEFT_SEP = u"\u255F"
    FRAME_RIGHT_SEP = u"\u2562"

    def __init__(self):
        self.sudo_file = None
        self.available_installers = {name: base_man.init(self) for name, base_man in PackageManager.basics().items()}
        self.available_installers["manual"] = True
        for name, man in PackageManager.all().items():
            if name not in self.available_installers and man.init(self) is True:
                # just check for the "non-basic" installers (e.g., snap) .. if not available, we will see later if we
                # should ask for installation
                self.available_installers[name] = True

    def __del__(self):
        self.unset_pw()

    def print(self, msg, colors):
        print(colors + msg + self.ENDC)

    def headline(self, msg, list_installers=False):
        content_size = max(78, len(msg)+2)

        def fill(filler=" ", text="", center=False):
            left = 1
            if center:
                left = max(int((content_size - len(text)) / 2.), 1)
            right = content_size - left - len(text)
            return (filler * left) + text + (filler * right)
        # daw frame
        self.info(self.FRAME_LEFT_TOP + fill(filler=self.FRAME_HORIZONTAL) + self.FRAME_RIGHT_TOP)
        self.info(self.FRAME_VERTICAL + self.BOLD + fill(text=msg) + self.FRAME_VERTICAL)
        if list_installers:
            self.info(
                self.FRAME_LEFT_SEP +
                fill(text=" Available Package Managers ", filler=self.FRAME_SEP, center=True) +
                self.FRAME_RIGHT_SEP
            )
            available = sorted(installer for installer, available in self.available_installers.items() if available)
            for installer in available:
                self.info(self.FRAME_VERTICAL + fill(text=installer) + self.FRAME_VERTICAL)
        self.info(self.FRAME_LEFT_BOTTOM + fill(filler=self.FRAME_HORIZONTAL) + self.FRAME_RIGHT_BOTTOM)

    def error(self, msg):
        self.print(msg, self.RED + self.BOLD)

    def success(self, msg):
        self.print(msg, self.GREEN)

    def info(self, msg):
        self.print(msg, self.BLUE)

    def debug(self, msg):
        self.print(msg, self.GRAY)

    def ask(self, question, options=None):
        """

        Ask a question with the given options.

        If options is empty array, no choices will be checked (no default set).

        :param question: The question to ask.
        :param options: The possible choices for the user as an array of strings (default: [*y*/n]). The first value
        between a pair of two asterisks will be used as default value (leading and trailing double-asterisks will be
        removed).
        :return: The "answer" return value, e.g., is "y" for "yes or "n" for "no".
        """
        if options is None:
            options = ["**y**", "n"]

        def is_default(value):
            return value.startswith("**") and value.endswith("**")

        def strip_default(value, tty_highlight=False):
            if not is_default(value):
                return value
            if tty_highlight:
                return "{}{}{}".format(self.BOLD + self.UNDERLINE, value[2:-2].upper(), self.ENDC + self.ORANGE)
            return value[2:-2]

        default = None
        prompt = ""
        if len(options) == 1:
            default = options[0]
            prompt = " [default: " + default + "]"
        elif len(options) > 1:
            for val in options:
                if is_default(val):
                    default = strip_default(val)
                    break

            prompt = " [" + "/".join(strip_default(val, True) for val in options) + "]"
            if default is not None:
                # remove double asterisks
                options = [strip_default(val) for val in options]

        # normalize options for comparisons
        options_lower = {option.lower(): option for option in options}

        while True:
            choice = input(self.ORANGE + question + prompt + self.ENDC + " >>> ").strip()
            if len(options) == 0:
                return choice
            elif choice == "" and default is not None:
                return default
            elif choice.lower() in options_lower:
                return options_lower[choice.lower()]
            else:
                self.error("Please respond with either of these choices" + prompt)

    def set_pw(self):
        name = None
        try:
            fd, name = tempfile.mkstemp(text=True)
            self.debug("Created temp-file {} ...".format(name))
            os.write(fd, "#!/bin/sh\necho '{}'".format(
                getpass.getpass(self.ORANGE + "Please enter the password to use sudo:" + self.ENDC + " >>> ")
            ).encode())
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
            self.debug("Deleting temp-file {} ...".format(self.sudo_file))
            os.remove(self.sudo_file)
            self.sudo_file = None

    @staticmethod
    def is_root():
        return getpass.getuser() == "root"

    def init_sudo(self):
        if not self.sudo_file:
            self.set_pw()
            os.environ['SUDO_ASKPASS'] = self.sudo_file

    def run_as_root(self, cmd, silent=False):
        if self.is_root():
            # run command directly
            return self.run(cmd, silent=silent)
        else:
            # run command with sudo
            self.init_sudo()
            return self.run(["/usr/bin/sudo", "-A"] + cmd.split(), silent=silent)

    def run(self, cmd, silent=False):
        if isinstance(cmd, basestring):
            cmd = cmd.split()
        try:
            if silent:
                devnull = open(os.devnull, 'w')
                return subprocess.call(cmd, stdout=devnull, stderr=devnull) == 0
            else:
                return subprocess.call(cmd) == 0
        except Exception:
            return False

    def write_to_file(self, content, path, mode="w"):
        parent = dirname(path)
        try:
            os.makedirs(parent, exist_ok=True)
        except TypeError:
            # exist_ok only available starting with 3.2 .. try without
            try:
                os.makedirs(parent)
            except OSError:
                # expect: [Errno 17] File exists: '{parent}'
                pass
        try:
            with open(path, mode=mode) as fd:
                fd.write(content)
        except Exception:
            self.error("Unable to {} content to `{}`!".format("append" if mode == "a" else "write", path))
            return False
        return True

    @staticmethod
    def is_installed(command):
        return find_executable(command) is not None

    @staticmethod
    def file_exists(filename):
        return exists(filename)

    def run_all(self, cmds, default_action, value_wrapper=lambda x: x, log=False):
        log = self.debug if log else lambda x: None
        if isinstance(cmds, basestring):
            return default_action(value_wrapper(cmds))
        if isinstance(cmds, list):
            # here we go recursive
            success = True
            for item in cmds:
                if not success:
                    log("    --> Skipping step (due to previous problem): {}".format(item))
                else:
                    log("  Executing: {}".format(item))
                    success &= self.run_all(item, default_action, value_wrapper)
                    if not success:
                        log("    -->  Step execution failed: {}".format(item))
            return success

        if isinstance(cmds, dict):
            # here we have a dynamic definition of a check:
            if cmds["type"] == "find_executable":
                return self.is_installed(value_wrapper(cmds["cmd"]))
            if cmds["type"] == "file_exists":
                return self.file_exists(value_wrapper(cmds["file"]))
            if cmds["type"] == "write_to_file":
                return self.write_to_file(**{key: value_wrapper(val) for key, val in cmds.items() if key != "type"})
            if cmds["type"] == "lambda":
                return eval(value_wrapper(cmds["code"]))(self)
        raise ValueError("Unknown check definition: {}".format(cmds))

    def try_install(self, software, pman):
        self.info("  Trying to install {} via {} ...".format(software.description, pman.name))

        # here we are lets try to execute the installer
        success = software.install_via(cli=self, package_manager=pman)
        if success:
            if software.is_available(self):
                self.success("  Installation of {} via {} successful!".format(software.name, pman.name))
            else:
                self.debug("  Steps executed successfully but not able to verify installation of {} via {}!".format(
                    software.name, pman.name
                ))
        return success

    def choose_installers(self, software_packages):
        for software in software_packages:
            if not software.is_available(self) and \
                    software.check_requirements(self) and \
                    "y" == self.ask("Do you want to install {}?".format(software.description)).lower():
                if not software.flavors_selected:
                    flavor_choices = {}
                    for flavor_type, choices in software.flavors.items():
                        if isinstance(choices, basestring):
                            choices = [choices]
                        flavor_choices[flavor_type] = self.ask(
                            "  Please choose a flavor for `{}`".format(flavor_type), options=choices
                        )
                    software.choose_flavors(flavor_choices)
                tried_pms = []
                for name in software.installers:
                    pman = PackageManager.get(name)
                    if name not in self.available_installers:
                        # we didn't try using this pm yet .. try to initialize and cache result for next time
                        pm_is_initialized = pman.init(self)
                        if isinstance(pm_is_initialized, Software):
                            # this is a special case .. we get a software package back, so we have to try install it
                            # before checking if it is correctly installed
                            for pm_installer in pm_is_initialized.installers:
                                base_pm = PackageManager.get(pm_installer)
                                if self.try_install(pman=base_pm, software=software):
                                    pm_is_initialized = pman.init(self)
                                    break
                        self.available_installers[pman.name] = pm_is_initialized
                    if not self.available_installers[pman.name]:
                        continue
                    tried_pms.append(pman.name)
                    if self.try_install(pman=pman, software=software):
                        break

                if not software.is_available(self):
                    if tried_pms:
                        self.error("  Unable to install `{}`, tried: {}".format(
                            software.name,
                            ", ".join(tried_pms)
                        ))
                    else:
                        self.error("  Unable to install `{}`, no suitable package manager found!".format(software.name))


def start(*package_lists):
    cli = ColoredConsole()
    if package_lists:
        for idx, package_list in enumerate(package_lists):
            cli.headline("Installing software from {} ...".format(package_list), list_installers=idx==0)
            cli.choose_installers(Software.parse_list(package_list))
    else:
        cli.headline("Basic software packages ...", list_installers=True)
        cli.choose_installers(Software.parse_list("install/basics.json"))
        cli.headline("Desktop software packages ...")
        cli.choose_installers(Software.parse_list("install/desktop.json"))
        cli.headline("Development software packages ...")
        cli.choose_installers(Software.parse_list("install/development.json"))


if __name__ == '__main__':
    start(*sys.argv[1:])
