#!/bin/zsh -li


TIMEFMT=$'%*ER,%*UU,%*SS,%Pcpu; Mem: %MKBtotal,%XKBshared, %DKBunshared'

while IFS= read expr; do
    echo "\nexpression is \"$expr\""

    cargo br 2>/dev/null && \
    echo -n "ruca: "
    echo "`$CARGO_TARGET_DIR/release/ruca \"$expr\" 2>/dev/null`"
    time ($CARGO_TARGET_DIR/release/ruca "$expr" > /dev/null 2>&1)
    echo -n "lc:   "
    time (lc "$expr")
    echo -n "bc:   "
    time (bc <<< "scale = 10; $expr")

done < expressions.txt

unset RUSTRESULT
