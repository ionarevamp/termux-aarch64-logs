#!/bin/zsh -li
# echo 'Begin script'

TIMEFMT=$'%uE %P'
max=300

if ! [ -z $BENCHMAX ]; then
    max=$BENCHMAX
fi

local checkcode=

cmd="$1"
shift 1
if (( $# >= 1 )); then
    max="$1"
    shift 1
    validmax="$(luajit <<< "if not (tonumber($max) >= 10) then print(0) else print(1) end")"
    (( $validmax == 1 )) || {
        echo 'Error: second argument must be a number greater than or equal to 10'
        exit 1;
    }
fi

trap 'exit 69;' SIGINT SIGTERM SIGKILL

    #echo "\ncommand is \"$cmd\""


    longest=0
    shortest=999999999999

    current_sum=0
    percentage_sum=0
#    exp="$(echo $cmd | sed 's/\^/**/g')"
    echo "eval \"$cmd\":  "
    start="$(date +%s.%4N)"
    for i in $(seq 1 1 $max)
    do
        timedata=$( { time ( eval "$cmd" > /dev/null 2>&1 ) } 2>&1 )
        micros="${timedata%% *}"
        micros="${micros%%us*}"
        if [ "$micros" -gt "$longest" ]; then
            longest="$micros"
        fi
        if [ "$micros" -lt "$shortest" ]; then
            shortest="$micros"
        fi
        let current_sum="$current_sum + $micros"
        percentage="${timedata##* }"
        let percentage_sum="$percentage_sum + ${percentage%%%*}"
        output="iteration: $i ; micros: $micros ; percentage: ${percentage%%%*}"
        echo -n "$output\x1B[0K\x1B[${#output}D"
    done
    end="$(date +%s.%4N)"
    echo -n "\x1B[0K"
    eval $cmd
    average=`$CARGO_TARGET_DIR/release/ruca "$current_sum / $max / 1000" 2>/dev/null`
    average_percentage=`$CARGO_TARGET_DIR/release/ruca "$percentage_sum / $max" 2>/dev/null`
    longest=`$CARGO_TARGET_DIR/release/ruca "$longest / 1000"`
    shortest=`$CARGO_TARGET_DIR/release/ruca "$shortest / 1000"`
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
    echo "Total time: `$HOME/.cargo/build/release/ruca \"$end - $start\"`s -- Avg. loop time: `$HOME/.cargo/build/release/ruca \"( $end - $start ) * 1000 / $max \"`ms"
    echo "Longest time: $longest"ms"; Shortest time: $shortest"ms
    echo "CPU score ( 1 / ( avg. time * ( avg. cpu / 100 ) ) ): $cpu_score"

