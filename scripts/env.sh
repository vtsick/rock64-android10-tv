#!/usr/bin/env bash

SDK="${SDK:-/opt/devel/Firefly/android10sdk}"
cd "$SDK"

# Mandatory for this Firefly Android 10 SDK. The bundled build tooling expects
# Python 2, and its 32-bit Python needs the matching zlib module supplied here.
export PATH="$PWD/prebuilts/python/linux-x86/2.7.5/bin:$PATH"
export PYTHON="$PWD/prebuilts/python/linux-x86/2.7.5/bin/python2.7"
export PYTHONPATH="$PWD/host-tools/python2-modules"
hash -r

export SDK
