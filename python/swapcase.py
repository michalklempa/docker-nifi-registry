#!/usr/bin/env python2

import sys

prefix = sys.argv[1] if len(sys.argv) > 1 else ''

for line in sys.stdin:
    if not line or line.isspace():
        sys.stdout.write(line)
    elif line.startswith('#') and '=' in line and line[1] != ' ':
        (key, value) = line[1:].split('=', 1)
        sys.stdout.write(line)
        sys.stdout.write('{{{{ if .Env.{}{} -}}}}\n'.format(prefix, key.swapcase().replace('.', '_')));
        sys.stdout.write('{}={{{{ .Env.{}{} }}}}\n'.format(key, prefix, key.swapcase().replace('.', '_') ))
        sys.stdout.write('{{- end }}\n')
    elif line.startswith('#'):
        sys.stdout.write(line)
    elif '=' in line:
        (key, value) = line.split('=', 1)
        sys.stdout.write('{}={{{{ default .Env.{}{} "{}" }}}}\n'.format(key, prefix, key.swapcase().replace('.', '_'), value.rstrip('\n') ))
    else:
        print 'omg', line

sys.stdout.flush()
