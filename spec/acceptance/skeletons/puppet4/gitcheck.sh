#!/bin/bash
# helper script to determine if a git clone is checked out to a
# PR, tag, or branch, and then output some information about the status
if [ $# -gt 0 ]; then
    cd $1
fi
origin=$(git remote show -n origin | grep 'Fetch URL:' | awk '{print $3}')
if tmp=$(git status | grep "refs/pull/origin"); then
    foo=$(echo "$tmp" | awk '{print $4}' | awk -F / '{print $4}')
    echo "PR: ${foo} @ $(git rev-parse HEAD) (origin: ${origin})"
elif tagname=$(git describe --exact-match --tags $(git log -n1 --pretty='%h') 2>/dev/null); then
    echo "tag: ${tagname} @ $(git rev-parse HEAD) (origin: ${origin})"
elif git symbolic-ref -q HEAD &>/dev/null; then
    branch_name=$(git symbolic-ref -q HEAD)
    branch_name=${branch_name##refs/heads/}
    branch_name=${branch_name:-HEAD}
    echo "branch: ${branch_name} @ $(git rev-parse HEAD) (origin: ${origin})"
else
    echo "sha: $(git rev-parse HEAD) (origin: ${origin})"
fi
