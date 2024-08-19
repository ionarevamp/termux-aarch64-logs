#!/bin/bash

export max=1000
export current_sum=0
export percentage_sum=0
export divisor=1

echo "Measuring \`date\` overhead..."

export start="`date +%s.%4N`"
for i in $(seq 1 1 $((max / $divisor)) )
do
    TIMEFORMAT='%3lR %P'
    export timedata="$( ( time date +%s.%N) 2>&1 )"
#    echo -n "timedata: $timedata -- "
    export secs="${timedata%% *}"
    export secs="${secs%%s*}"
    export secs="${secs##*m}"
    export millis=`$HOME/.cargo/build/release/ruca "$secs * 1000" `
#    echo -n "secs: $secs -- "
    export current_sum="$(($current_sum + $millis))"
    export percentage="${timedata##* }"
    export percentage_sum=$($HOME/.cargo/build/release/ruca "$percentage_sum + $percentage")
    export output="iteration: $(($i * $divisor)); millis: $millis ; percentage: $percentage"
    echo -ne "$output"'\033[0K\033['"${#output}D"
done
export end=`date +%s.%4N`
echo -ne "\x1B[0K"
export average=`$HOME/.cargo/build/release/ruca "($current_sum / $max )" 2>/dev/null`
export average_percentage=`$HOME/.cargo/build/release/ruca "$percentage_sum / $max " 2>/dev/null`
    cpu_score_expression='local factor = 0;
    local score = 1 / ('"$average * $average_percentage"')
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

    echo "Total time: `bc -l <<< \"$end - $start\"`s -- Avg. loop time: `bc -l <<< \"( $end - $start ) / ( $max * $divisor) * 1000\"`ms"
echo "CPU score ( 1 / (avg. time * avg. cpu) ): $cpu_score"
