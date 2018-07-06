# rmjunk.py is a modified version of a script written by Jakub Klinkovský here: 
# https://github.com/lahwaacz/Scripts/blob/master/rmshit.py

import os
import sys
import shutil


junkfiles = [
    '~/.adobe',
    '~/.macromedia',
    '~/.recently-used',
    '~/.local/share/recently-used.xbel',
    '~/.thumbnails',
    '~/.gconfd',
    '~/.gconf',
    '~/.local/share/gegl-0.2',
    '~/.FRD/log/app.log',
    '~/.FRD/links.txt',
    '~/.objectdb',
    '~/.gstreamer-0.10',
    '~/.pulse',
    '~/.esd_auth',
    '~/.config/enchant',
    '~/.spicec',
    '~/.dropbox-dist',
    '~/.parallel',
    '~/.dbus',
    '~/ca2',
    '~/ca2~',
    '~/.distlib/',
    '~/.bazaar/',
    '~/.bzr.log',
    '~/.nv/',
    '~/.viminfo',
    '~/.npm/',
    '~/.java/',
    '~/.oracle_jre_usage/',
    '~/.jssc/',
    '~/.tox/',
    '~/.pylint.d/',
    '~/.qute_test/',
    '~/.QtWebEngineProcess/',
    '~/.qutebrowser/',
    '~/.asy/',
    '~/.cmake/',
    '~/.gnome/',
    '~/unison.log',
    '~/.texlive/',
    '~/.w3m/',
    '~/.subversion/',
    '~/nvvp_workspace/',
]


def yesno(question, default="n"):
    prompt = "%s (y/N) " % question

    ans = input(prompt).strip().lower()

    if not ans:
        ans = default

    if ans == "y":
        return True
    return False


def rmjunk():
    print("Found junk files:")
    found = []
    for f in junkfiles:
        absf = os.path.expanduser(f)
        if os.path.exists(absf):
            found.append(absf)
            print("    %s" % f)

    if len(found) == 0:
        print("No junk files found")
        return

    if yesno("Remove all?", default="n"):
        for f in found:
            if os.path.isfile(f):
                os.remove(f)
            else:
                shutil.rmtree(f)
        print("All cleaned")
    else:
        print("No file removed")


if __name__ == '__main__':
    rmjunk()