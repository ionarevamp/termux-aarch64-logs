#!/bin/zsh -li

echo "Generating expressions..."
node Math-Expression-Generator/Source/mathgen.js > expressions.txt
echo "Beginning benchmark."
echo ""

#TIMEFMT=$'%*ER,%*UU,%*SS,%Pcpu; Mem: %MKBtotal,%XKBshared, %DKBunshared'
TIMEFMT=$'%uE %P'
max=1000

while IFS= read expr
do
    echo "\nexpression is \"$expr\""

    current_sum=0
    percentage_sum=0
    exp="$(echo $expr | sed 's/\^/**/g')"
    echo -n "zsh:  "
    for i in $(seq 1 1 $max)
    do
        timedata=$( { time (echo $(($exp)) > /dev/null 2>&1) } 2>&1 )
        micros="${timedata%% *}"
        let current_sum="$current_sum + ${micros%%us*}"
        percentage="${timedata##* }"
        let percentage_sum="$percentage_sum + ${percentage%%%*}"
        output="iteration: $i ; micros: ${micros%%us*} ; percentage: ${percentage%%%*}"
        echo -n "$output\x1B[0K\x1B[${#output}D"
    done
    echo -n "\x1B[0K"
    echo "$(($exp))"
    average=`$CARGO_TARGET_DIR/release/ruca "$current_sum / $max / 1000" 2>/dev/null`
    average_percentage=`$CARGO_TARGET_DIR/release/ruca "$percentage_sum / $max" 2>/dev/null`
    cpu_score_expression='local factor = 0;
    local score = 1 / ('"$average * ( $average_percentage / 100)"')
    while score < 1.0 do
        score = score * 10.0
        factor = factor - 1
    end
    while score > 10 do
        score = score / 10.0
        factor = factor + 1
    end
    local score_string = tostring(score)
    local exponent = ""
    if factor > 0 then
        exponent = "e+"
    end
    if factor < 0 then
        exponent = "e"
    end
    score_string = score_string..exponent..factor
    print(score_string)'
    echo "$cpu_score_expression" > $TMPDIR/cpu_score_expression.lua
    cpu_score=`luajit "$TMPDIR/cpu_score_expression.lua"`
    echo "Runs: $max -- Avg. time in ms: $average, Avg. CPU usage: $average_percentage%"
    echo "CPU score ( 1 / ( avg. time * ( avg. cpu / 100 ) ) ): $cpu_score"

    current_sum=0
    percentage_sum=0
    exp="$(echo $expr | sed 's/\^/**/g')"
    echo -n "zcalc:"
    for i in $(seq 1 1 $max)
    do
        timedata=$( { autoload zcalc && time (echo $(zcalc -e "$exp") > /dev/null 2>&1) } 2>&1 )
        micros="${timedata%% *}"
        let current_sum="$current_sum + ${micros%%us*}"
        percentage="${timedata##* }"
        let percentage_sum="$percentage_sum + ${percentage%%%*}"
        output="iteration: $i ; micros: ${micros%%us*} ; percentage: ${percentage%%%*}"
        echo -n "$output\x1B[0K\x1B[${#output}D"
    done
    echo -n "\x1B[0K"
    ( autoload zcalc && echo $(zcalc -e "$exp"))
    average=`$CARGO_TARGET_DIR/release/ruca "$current_sum / $max / 1000" 2>/dev/null`
    average_percentage=`$CARGO_TARGET_DIR/release/ruca "$percentage_sum / $max" 2>/dev/null`
    cpu_score_expression='local factor = 0;
    local score = 1 / ('"$average * ( $average_percentage / 100)"')
    while score < 1.0 do
        score = score * 10.0
        factor = factor - 1
    end
    while score > 10 do
        score = score / 10.0
        factor = factor + 1
    end
    local score_string = tostring(score)
    local exponent = ""
    if factor > 0 then
        exponent = "e+"
    end
    if factor < 0 then
        exponent = "e"
    end
    score_string = score_string..exponent..factor
    print(score_string)'
    echo "$cpu_score_expression" > $TMPDIR/cpu_score_expression.lua
    cpu_score=`luajit "$TMPDIR/cpu_score_expression.lua"`
    echo "Runs: $max -- Avg. time in ms: $average, Avg. CPU usage: $average_percentage%"
    echo "CPU score ( 1 / ( avg. time * ( avg. cpu / 100 ) ) ): $cpu_score"

    current_sum=0
    percentage_sum=0
    exp="$(echo $expr | sed 's/\^/**/g')"

    ./mathloop.bash "$expr"

    ./mathloop.sh "$expr"

    current_sum=0
    percentage_sum=0
    echo -n "perl: "
    for i in $(seq 1 1 $max)
    do
        timedata=$( { time (perl <<< 'print '"$exp"' . "\n"' > /dev/null 2>&1) } 2>&1 )
        micros="${timedata%% *}"
        let current_sum="$current_sum + ${micros%%us*}"
        percentage="${timedata##* }"
        let percentage_sum="$percentage_sum + ${percentage%%%*}"
        output="iteration: $i ; micros: ${micros%%us*} ; percentage: ${percentage%%%*}"
        echo -n "$output\x1B[0K\x1B[${#output}D"
    done
    echo -n "\x1B[0K"
    perl <<< 'print '"$exp"' . "\n"'
    average=`$CARGO_TARGET_DIR/release/ruca "$current_sum / $max / 1000" 2>/dev/null`
    average_percentage=`$CARGO_TARGET_DIR/release/ruca "$percentage_sum / $max" 2>/dev/null`
    cpu_score_expression='local factor = 0;
    local score = 1 / ('"$average * ( $average_percentage / 100)"')
    while score < 1.0 do
        score = score * 10.0
        factor = factor - 1
    end
    while score > 10 do
        score = score / 10.0
        factor = factor + 1
    end
    local score_string = tostring(score)
    local exponent = ""
    if factor > 0 then
        exponent = "e+"
    end
    if factor < 0 then
        exponent = "e"
    end
    score_string = score_string..exponent..factor
    print(score_string)'
    echo "$cpu_score_expression" > $TMPDIR/cpu_score_expression.lua
    cpu_score=`luajit "$TMPDIR/cpu_score_expression.lua"`
    echo "Runs: $max -- Avg. time in ms: $average, Avg. CPU usage: $average_percentage%"
    echo "CPU score ( 1 / ( avg. time * ( avg. cpu / 100 ) ) ): $cpu_score"

    current_sum=0
    percentage_sum=0
    cargo br 2>/dev/null && \
    echo -n "ruca: "
    for i in $(seq 1 1 $max)
    do
        timedata=$( { time ($CARGO_TARGET_DIR/release/ruca "$expr" > /dev/null 2>&1) } 2>&1 )
        micros="${timedata%% *}"
        let current_sum="$current_sum + ${micros%%us*}"
        percentage="${timedata##* }"
        let percentage_sum="$percentage_sum + ${percentage%%%*}"
        output="iteration: $i ; micros: ${micros%%us*} ; percentage: ${percentage%%%*}"
        echo -n "$output\x1B[0K\x1B[${#output}D"
    done
    echo -n "\x1B[0K"
    average=`$CARGO_TARGET_DIR/release/ruca "$current_sum / $max / 1000" 2>/dev/null`
    average_percentage=`$CARGO_TARGET_DIR/release/ruca "$percentage_sum / $max" 2>/dev/null`
    echo "`$CARGO_TARGET_DIR/release/ruca \"$expr\" 2>/dev/null`"
    cpu_score_expression='local factor = 0;
    local score = 1 / ('"$average * ( $average_percentage / 100)"')
    while score < 1.0 do
        score = score * 10.0
        factor = factor - 1
    end
    while score > 10 do
        score = score / 10.0
        factor = factor + 1
    end
    local score_string = tostring(score)
    local exponent = ""
    if factor > 0 then
        exponent = "e+"
    end
    if factor < 0 then
        exponent = "e"
    end
    score_string = score_string..exponent..factor
    print(score_string)'
    echo "$cpu_score_expression" > $TMPDIR/cpu_score_expression.lua
    cpu_score=`luajit "$TMPDIR/cpu_score_expression.lua"`
    echo "Runs: $max -- Avg. time in ms: $average, Avg. CPU usage: $average_percentage%"
    echo "CPU score ( 1 / ( avg. time * ( avg. cpu / 100 ) ) ): $cpu_score"

    current_sum=0
    percentage_sum=0
    echo -n "bc:   "
    for i in $(seq 1 1 $max)
    do
        timedata=$( { time (bc -l <<< "$expr" > /dev/null 2>&1) } 2>&1 )
        micros="${timedata%% *}"
        let current_sum="$current_sum + ${micros%%us*}"
        percentage="${timedata##* }"
        let percentage_sum="$percentage_sum + ${percentage%%%*}"
        output="iteration: $i ; micros: ${micros%%us*} ; percentage: ${percentage%%%*}"
        echo -n "$output\x1B[0K\x1B[${#output}D"
    done
    echo -n "\x1B[0K"
    bc -l <<< "$expr"
    average=`$CARGO_TARGET_DIR/release/ruca "$current_sum / $max / 1000" 2>/dev/null`
    average_percentage=`$CARGO_TARGET_DIR/release/ruca "$percentage_sum / $max" 2>/dev/null`
    cpu_score_expression='local factor = 0;
    local score = 1 / ('"$average * ( $average_percentage / 100)"')
    while score < 1.0 do
        score = score * 10.0
        factor = factor - 1
    end
    while score > 10 do
        score = score / 10.0
        factor = factor + 1
    end
    local score_string = tostring(score)
    local exponent = ""
    if factor > 0 then
        exponent = "e+"
    end
    if factor < 0 then
        exponent = "e"
    end
    score_string = score_string..exponent..factor
    print(score_string)'
    echo "$cpu_score_expression" > $TMPDIR/cpu_score_expression.lua
    cpu_score=`luajit "$TMPDIR/cpu_score_expression.lua"`
    echo "Runs: $max -- Avg. time in ms: $average, Avg. CPU usage: $average_percentage%"
    echo "CPU score ( 1 / ( avg. time * ( avg. cpu / 100 ) ) ): $cpu_score"

    current_sum=0
    percentage_sum=0
    echo -n "lc:   "
    for i in $(seq 1 1 $max)
    do
        timedata=$( { time (lc "$expr" > /dev/null 2>&1) } 2>&1 )
        micros="${timedata%% *}"
        let current_sum="$current_sum + ${micros%%us*}"
        percentage="${timedata##* }"
        let percentage_sum="$percentage_sum + ${percentage%%%*}"
        output="iteration: $i ; micros: ${micros%%us*} ; percentage: ${percentage%%%*}"
        echo -n "$output\x1B[0K\x1B[${#output}D"
    done
    echo -n "\x1B[0K"
    lc "$expr"
    average=`$CARGO_TARGET_DIR/release/ruca "$current_sum / $max / 1000" 2>/dev/null`
    average_percentage=`$CARGO_TARGET_DIR/release/ruca "$percentage_sum / $max" 2>/dev/null`
    cpu_score_expression='local factor = 0;
    local score = 1 / ('"$average * ( $average_percentage / 100)"')
    while score < 1.0 do
        score = score * 10.0
        factor = factor - 1
    end
    while score > 10 do
        score = score / 10.0
        factor = factor + 1
    end
    local score_string = tostring(score)
    local exponent = ""
    if factor > 0 then
        exponent = "e+"
    end
    if factor < 0 then
        exponent = "e"
    end
    score_string = score_string..exponent..factor
    print(score_string)'
    echo "$cpu_score_expression" > $TMPDIR/cpu_score_expression.lua
    cpu_score=`luajit "$TMPDIR/cpu_score_expression.lua"`
    echo "Runs: $max -- Avg. time in ms: $average, Avg. CPU usage: $average_percentage%"
    echo "CPU score ( 1 / ( avg. time * ( avg. cpu / 100 ) ) ): $cpu_score"

done < expressions.txt
