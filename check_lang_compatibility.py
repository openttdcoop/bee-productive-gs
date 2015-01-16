#!/usr/bin/env python3
#
# This file is part of BusyBee, which is a GameScript for OpenTTD
# Copyright (C) 2014-2015  alberth / andythenorth
#
# BusyBee is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License
#
# BusyBee is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with BusyBee; If not, see <http://www.gnu.org/licenses/> or
# write to the Free Software Foundation, Inc., 51 Franklin Street,
# Fifth Floor, Boston, MA 02110-1301 USA.
"""
Verify whether the current language file is compatible with a language file at
a revision as given in a file, indicated by the prefix "// cset:".
"""

import os, subprocess, re, sys


def process_langline(line):
    """
    Process a line in a language file.

    @param line: Line in a language file.
    @type  line: C{str}

    @return: The name of the string if reading a string line, else C{None}
    @rtype:  C{None} or C{str}
    """
    line = line.rstrip()
    if len(line) == 0 or line[0] == '#':
        return None

    i = line.find(':')
    if i < 0:
        return None

    return line[:i].rstrip()


def get_langfile_rev(name, rev):
    """
    Get the string names of a language file.

    @param name: Name of the language file.
    @type  name: C{str}

    @param rev: Revision to retrieve.
    @type  rev: C{str}

    @return: Lines wit string names.
    @rtype:  C{list} of C{str}
    """
    # Copy the environment, and add HGPLAIN
    env = dict(kv for kv in os.environ.items())
    env['HGPLAIN'] = ''

    cmd = ['hg', 'cat', '-r', rev, name]
    txt = subprocess.check_output(cmd, universal_newlines=True, env=env)

    lines = []
    for line in txt.split('\n'):
        line = process_langline(line)
        if line is not None:
            lines.append(line)

    return lines

def get_langfile(fname):
    """
    Get strings from the given language file.

    @param fname: Name of the file to open.
    @type  fname: C{str}

    @return: Lines wit string names.
    @rtype:  C{list} of C{str}
    """
    handle = open(fname, 'rt', encoding='utf-8')

    lines = []
    for line in handle:
        line = process_langline(line)
        if line is not None:
            lines.append(line)

    handle.close()
    return lines

cset_pattern = re.compile('//[ \\t]*cset:[ \\t]*([0-9A-F[a-f]*)')

def get_cset(fname):
    """
    Get changeset revision from the given file.

    @param fname: Name of the file to open.
    @type  fname: C{str}

    @return: Changeset number, if available (C{// *cset: *([0-9A-F[a-f]*)})
    @rtype:  C{list} of C{str}
    """
    handle = open(fname, 'rt', encoding='utf-8')
    for line in handle:
        m = cset_pattern.search(line)
        if m and len(m.group(1)) > 4:
            handle.close()
            return m.group(1)

    handle.close()
    return None

if len(sys.argv) != 3:
    print("Incorrect number of arguments: expected \"check_lang_compatibility.py <lang/basename.txt> <cset-src>\"")
    sys.exit(1)

language_name = sys.argv[1]
cset_file = sys.argv[2]

cset = get_cset(cset_file)
if cset is None:
    print("No change set number found.")
    sys.exit(1)

print("** Comparing file {}, current version and at revision {} **".format(language_name, cset))
min_comp_strings = get_langfile_rev(language_name, cset)
now_strings = get_langfile(language_name)
result = min_comp_strings != now_strings #0 code is ok.
if result:
    print("\nCompatibility of language files failed.\n")
sys.exit(result)
