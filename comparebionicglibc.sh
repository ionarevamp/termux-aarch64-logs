#!/bin/zsh -li

echo 'Running bionic version of command in zsh:'
$LOGDIR/benchmarkcmd.sh $@
echo ""
echo 'Running bionic version of command in bash:'
$LOGDIR/bench.bash $@
echo ""
echo 'Running glibc version of command in bash:'
glibc-runner -s 'bash bench.bash "'$1'" '"$2"
