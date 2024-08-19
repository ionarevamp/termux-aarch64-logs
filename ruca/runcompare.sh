#!/bin/zsh -li

expression="$@"

cargo build 2>/dev/null && \
    time ($CARGO_TARGET_DIR/debug/ruca "$expression")
    time (lc "$expression") && \
    time (bc <<< "scale = 10; $expression") && \
