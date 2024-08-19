#!/bin/sh

export max=1000
export current_sum=0
export percentage_sum=0

#exp="$(echo "$@" | sed 's/\^/**/g')"
exp="$@"
echo -n "sh:   "
export start=`date +%s.%4N`
for i in $(seq 1 1 $max)
do
    TIMEFORMAT=
    (time --format='%E %P' -o $TMPDIR/timedata echo $(($exp)) )> /dev/null
    export timedata="$(cat $TMPDIR/timedata)"
#    echo -n "TIMEDATA: ($timedata), "
    export secs="${timedata%% *}"
    export secs="${secs##*:}"
    export millis=`$HOME/.cargo/build/release/ruca "$secs * 1000"`
#    echo -n "secs: $secs, "
#    export secs="${secs##*}"
    export current_sum=`$HOME/.cargo/build/release/ruca "$current_sum + $millis"`
#    export current_sum=$(bc -l $TMPDIR/current_sum)
    export percentage="${timedata##* }"
#    echo -n "PERCENTAGE: ($percentage), "
    export percentage_sum=`$HOME/.cargo/build/release/ruca "$percentage_sum + ${percentage%%%*}"`
#    export percentage_sum=$(bc -l $TMPDIR/current_percentage )
    export output="iteration: $i ; millis: $millis ; percentage: ${percentage%%%*}"
    echo -n "$output\033[0K\033[${#output}D"
done
export end=`date +%s.%4N`
echo -n "\033[0K"
echo $(($exp))
export average=`$HOME/.cargo/build/release/ruca "($current_sum / $max)" 2>/dev/null`
export average_percentage=`$HOME/.cargo/build/release/ruca "$percentage_sum / $max" 2>/dev/null`
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

    echo "Total time: `$HOME/.cargo/build/release/ruca \"($end - $start)\"`s -- Avg. loop time: `$HOME/.cargo/build/release/ruca \"( $end - $start ) * 1000 / $max\"`ms"
echo "CPU score ( 1 / ( avg. time * ( avg. cpu / 100 ) ) ): $cpu_score"
