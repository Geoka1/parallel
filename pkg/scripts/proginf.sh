#!/bin/bash
TOP=$(realpath "$(dirname "$0")/..")
MIR_BIN=$TOP/inputs/mir-sa/@andromeda/mir-sa/index.js
OUT=$TOP/outputs
IN=$TOP/inputs
INDEX=${INDEX:-"$TOP/inputs/index.txt"}

mkdir -p "${OUT}/"

export TOP MIR_BIN OUT IN

cat "$INDEX" | nl -v1 | parallel --colsep '\t' --halt now,fail=1 '
    pkg_count={1}
    package={2}
    cd "$IN/node_modules/$package" || exit 1
    "$MIR_BIN" -p > "$OUT/$pkg_count.log"
'