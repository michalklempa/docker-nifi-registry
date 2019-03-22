#!/usr/bin/env python2

import sys

for line in sys.stdin:
    if not line or line.isspace() or line.startswith('#'):
        sys.stdout.write(line)
    elif '=' in line:
        (key, value) = line.split('=', 1)
        sys.stdout.write('{}={{{{ default .Env.{} "{}" }}}}\n'.format(key, key.swapcase().replace('.', '_'), value.rstrip('\n') ))
    else:
        print 'omg', line

sys.stdout.flush()
