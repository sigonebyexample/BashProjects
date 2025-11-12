#!/bin/bash
echo "TRAVELING SALESMAN - NEAREST NEIGHBOR"

# Cities with coordinates
cities=("A:0:0" "B:1:2" "C:3:1" "D:2:3" "E:4:0")

calculate_distance() {
    local x1=$1 y1=$2 x2=$3 y2=$4
    local dx=$((x2-x1))
    local dy=$((y2-y1))
    echo $((dx*dx + dy*dy))
}

solve_tsp() {
    local visited=($1)
    local current=$2
    local total_distance=$3
    
    if [[ ${#visited[@]} -eq ${#cities[@]} ]]; then
        echo "Path: ${visited[@]} Distance: $total_distance"
        return
    fi
    
    local nearest=""
    local min_distance=9999
    
    for ((i=0; i<${#cities[@]}; i++)); do
        if [[ ! " ${visited[@]} " =~ " ${cities[i]%:*} " ]]; then
            local city1=${cities[current]}
            local name1=${city1%:*}; city1=${city1#*:}
            local x1=${city1%:*}; local y1=${city1#*:}
            
            local city2=${cities[i]}
            local name2=${city2%:*}; city2=${city2#*:}
            local x2=${city2%:*}; local y2=${city2#*:}
            
            local dist=$(calculate_distance $x1 $y1 $x2 $y2)
            
            if [[ $dist -lt $min_distance ]]; then
                min_distance=$dist
                nearest=$i
            fi
        fi
    done
    
    if [[ -n $nearest ]]; then
        solve_tsp "$(echo "${visited[@]} ${cities[nearest]%:*}")" $nearest $((total_distance + min_distance))
    fi
}

solve_tsp "A" 0 0
