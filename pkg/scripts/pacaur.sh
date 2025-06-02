#!/bin/bash


IN="$1"
OUT="$2"
MAX_PROCS=${MAX_PROCS:-$(nproc)}

mkcd() {
    mkdir -p "$1" || return 1
    cd "$1" || return 1
}

# set link to plaintext PKGBUILDs
URL='https://atlas.cs.brown.edu/data/aurpkg'

run_tests() {
    pkg=$1
    echo
    ORIG_DIR=$(pwd)

    mkcd "${OUT}/$pkg" || exit 1

    curl --insecure -o PKGBUILD "$URL/$pkg/PKGBUILD" 2>/dev/null || echo ' '

    gpg --recv-keys $(sed -n "s:^validpgpkeys=('\([0-9A-Fa-fx]\+\)').*$:\1:p" PKGBUILD)

    if [ "$EUID" -eq 0 ]; then
        chown -R user:user "$OUT"
        runuser -u user -p -- makedeb -d >"../$pkg.txt" 2>&1 || true
    else
        makedeb -d >"../$pkg.txt" 2>&1 || true
    fi 
    cd "$ORIG_DIR" || exit 1
}

export -f run_tests

export IN
export OUT
export URL
export -f mkcd
export -f run_tests
cat "${IN}" | parallel --jobs "$MAX_PROCS" 'run_tests {} > "${OUT}/{}.txt" 2>&1'

