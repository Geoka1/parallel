#!/usr/bin/env bash
# original script + GNU parallel **only**          ────────────────────────────
# requires GNU parallel on $PATH; set THREADS to limit jobs (defaults: nproc)

shopt -s expand_aliases

alias g='git'
alias gst='git status'
alias gco='git checkout'
alias grs='git reset --hard'
alias gcl='git clean -fd'
alias gci='git commit'
alias gaa='git add -A'

TOP=$(git rev-parse --show-toplevel)
EVAL_DIR="${TOP}/repl"
REPO_PATH="${EVAL_DIR}/inputs/chromium"
COMMITS_DIR="${EVAL_DIR}/inputs/commits"
NUM_COMMITS="${1:-20}"
THREADS="${THREADS:-$(nproc)}"        # ← how many workers for GNU parallel

export HOME="$COMMITS_DIR"
mkdir -p "$COMMITS_DIR"

cd "$REPO_PATH" || exit 1

g config user.email "author@example.com"
g config user.name  "A U Thor"

g stash
gco main
g branch -D bench_branch 2>/dev/null || true
gco -b bench_branch 644ae58
grs
gcl

commit_file=~/commit_list.txt
g rev-list --first-parent HEAD -n "$NUM_COMMITS" | tac > "$commit_file"

base_commit=$(head -n 1 "$commit_file")
echo "$base_commit" > ~/base_commit.txt

num_patches=$((NUM_COMMITS - 1))

###############################################################################
# ▸▸  Generate all *.diff / *.commit pairs **in parallel**  ◂◂
#    (independent, read-only ops → safe to parallelise)
###############################################################################
awk -v n="$num_patches" '
  NR==1 {prev=$0; next}               # keep first commit as “prev”
  {
    upper = n - (NR-1) + 1            # patch_upper formula from original loop
    lower = upper - 1                 # patch_lower
    print prev, $0, upper, lower      # fields: prev curr upper lower
    prev=$0
  }' "$commit_file" | \
parallel --colsep ' ' -j "$THREADS" '
  g diff  {1} {2} > ~/{3}-{4}.diff
  g log -1 --pretty=%B {2} > ~/{3}-{4}.commit
'

gst

if [ -f ~/base_commit.txt ]; then
    git checkout bench_branch
    git reset --hard "$(cat ~/base_commit.txt)"
else
    echo "Missing base_commit.txt"
    exit 1
fi

for i in $(seq "$num_patches" -1 1); do
    lower=$(( i - 1 ))
    patchfile=~/${i}-${lower}.diff
    commitmsg=~/${i}-${lower}.commit
    
    if [ -s "$patchfile" ]; then
        g apply "$patchfile" || { echo "Failed to apply $patchfile"; exit 1; }

        gst

        gaa
        gci --author="A U Thor <author@example.com>" -F "$commitmsg" \
           || { echo "Failed to commit with $commitmsg"; exit 1; }
    else
        echo "Patch file $patchfile is empty, skipping commit."
    fi
done

gst
