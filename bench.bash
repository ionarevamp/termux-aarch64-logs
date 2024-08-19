#!/bin/bash


max=300

if ! [ -z $BENCHMAX ]; then
    max=$BENCHMAX
fi

checkcode=

cmd="$1"
shift 1
#echo "DEBUG: Cmd is $cmd"
if (( $# >= 1 )); then
    max="$1"
    shift 1
    #echo "DEBUG: Max is $max"
    validmax="$(luajit <<< "if not (tonumber($max) >= 10) then print(0) else print(1) end")"
    [[ "$validmax" -eq "1" ]] || {
        echo 'Error: second argument must be a number greater than or equal to 10'
        exit 1;
    }
fi


longest=0
shortest=999999999999


trap 'exit 69;' SIGINT SIGTERM SIGKILL
export current_sum=0
export percentage_sum=0
export date_sum=0
export divisor=1

export date_overhead="16.357" #ms

#exp="$(echo "$@" | sed 's/\^/**/g')"
echo "bash: eval \"$cmd\""
export start="`date +%s.%4N`"
for i in $(seq 1 1 $((max / $divisor)) )
do
    TIMEFORMAT='%3lR %P'
    export pre_time=`date +%s.%N`
    export timedata="$( ( time eval "$cmd" >/dev/null) 2>&1 )"
    export post_time=`echo "scale = 10; $(date +%s.%N) - ( ( $date_overhead / 1000 ) * 2 )" | bc`
#    echo -n "timedata: $timedata -- "
    export secs="${timedata%% *}"
    export secs="${secs%%s*}"
    export secs="${secs##*m}"
    export millis=`$HOME/.cargo/build/release/ruca "$secs * 1000"`
    if [ "$millis" -gt "$longest" ]; then
        longest="$millis"
    fi
    if [ "$millis" -lt "$shortest" ]; then
        shortest="$millis"
    fi
    #export date_sum=`$HOME/.cargo/build/release/ruca "$date_sum + ( ($post_time - $pre_time) * 1000)"`
#    echo -n "secs: $secs -- "
    export current_sum="$(( $current_sum + $millis ))"
    export percentage="${timedata##* }"
    export percentage_sum=$($HOME/.cargo/build/release/ruca "$percentage_sum + $percentage")
    export output="iteration: $(($i * $divisor)); millis: $millis ; percentage: $percentage"
    echo -ne "$output"'\033[0K\033['"${#output}D"
done
export end=`date +%s.%4N`
echo -ne "\x1B[0K"
eval "$cmd"
export average=`$HOME/.cargo/build/release/ruca "($current_sum ) / $max" 2>/dev/null`
export average_percentage=`$HOME/.cargo/build/release/ruca "$percentage_sum / $max " 2>/dev/null`
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
#    echo "Average time as measured by date (excluding overhead): `$HOME/.cargo/build/release/ruca \"$date_sum / $max\"`ms"

echo "Total time: `$HOME/.cargo/build/release/ruca \"$end - $start\"`s -- Avg. loop time: `$HOME/.cargo/build/release/ruca \"( $end - $start ) * 1000 / $max \"`ms"
echo "Longest time: $longest"ms"; Shortest time: $shortest"ms
echo "CPU score ( 1 / ( avg. time * ( avg. cpu / 100 ) ) ): $cpu_score"
#echo -n "CPU score as measured by \`date\`: "
#echo 'local factor = 0;
#    local score = 1 / ('"( $date_sum / 1000 / $max ) * ( $average_percentage / 100)"')
#    while score < 1.0 do
#        score = score * 10.0
#        factor = factor - 1
#    end
#    while score > 10 do
#        score = score / 10.0
#        factor = factor + 1
#    end
#    local score_string = tostring(score)
#    local exponent = ""
#    if factor > 0 then
#        exponent = "e+"
#    end
#    if factor < 0 then
#        exponent = "e"
#    end
#    score_string = score_string..exponent..factor
#    print(score_string)' | luajit
