#!/bin/bash

# Simple Highway Dodger - No Blinking

# Game settings
HEIGHT=20
LANE_LEFT=15
LANE_RIGHT=25
PLAYER="[X]"
CAR="[O]"
EMPTY="   "

# Game state
player_lane=0
player_y=18
cars=()
score=0
game_over=0
speed=0.2

init_game() {
    player_lane=0
    player_y=18
    cars=()
    score=0
    game_over=0
    speed=0.2
}

draw_game() {
    clear
    
    # Header
    echo "================================"
    echo "         HIGHWAY DODGER"
    echo "================================"
    echo "Score: $score"
    echo
    echo "================================"
    
    # Game area
    for ((y=0; y<HEIGHT; y++)); do
        line=""
        left_car="$EMPTY"
        right_car="$EMPTY"
        
        # Draw player
        if [[ $y -eq $player_y ]]; then
            if [[ $player_lane -eq 0 ]]; then
                left_car="$PLAYER"
            else
                right_car="$PLAYER"
            fi
        fi
        
        # Draw other cars
        for car in "${cars[@]}"; do
            car_data=($car)
            car_y=${car_data[0]}
            car_lane=${car_data[1]}
            
            if [[ $y -eq $car_y ]]; then
                if [[ $car_lane -eq 0 ]]; then
                    left_car="$CAR"
                else
                    right_car="$CAR"
                fi
            fi
        done
        
        # Build the line
        line="$left_car     $right_car"
        echo "|         $line         |"
    done
    
    echo "================================"
    echo
    echo "Controls: A - Left  D - Right"
    echo "          R - Restart"
    
    if [[ $game_over -eq 1 ]]; then
        echo
        echo "GAME OVER! Score: $score"
        echo "Press R to restart"
    fi
}

add_car() {
    if [[ ${#cars[@]} -lt 3 ]] && [[ $((RANDOM % 4)) -eq 0 ]]; then
        lane=$((RANDOM % 2))
        cars+=("0 $lane")
    fi
}

move_cars() {
    new_cars=()
    for car in "${cars[@]}"; do
        car_data=($car)
        y=${car_data[0]}
        lane=${car_data[1]}
        
        ((y++))
        
        if [[ $y -lt $HEIGHT ]]; then
            new_cars+=("$y $lane")
        else
            ((score++))
            # Speed up every 5 points
            if [[ $((score % 5)) -eq 0 ]] && [[ $(echo "$speed > 0.05" | bc -l 2>/dev/null) ]]; then
                speed=$(echo "$speed - 0.02" | bc -l 2>/dev/null)
            fi
        fi
    done
    cars=("${new_cars[@]}")
}

check_crash() {
    for car in "${cars[@]}"; do
        car_data=($car)
        y=${car_data[0]}
        lane=${car_data[1]}
        
        if [[ $y -eq $player_y ]] && [[ $lane -eq $player_lane ]]; then
            game_over=1
            return
        fi
    done
}

process_input() {
    if read -t $speed -n 1 key; then
        case $key in
            a|A) player_lane=0 ;;
            d|D) player_lane=1 ;;
            r|R) [[ $game_over -eq 1 ]] && init_game ;;
            q|Q) exit 0 ;;
        esac
    fi
}

main() {
    # Hide cursor
    echo -ne "\033[?25l"
    
    echo "HIGHWAY DODGER - Simple Version"
    echo "Avoid the [O] cars, use A and D to switch lanes"
    echo "Press any key to start..."
    read -n 1
    
    init_game
    
    while true; do
        if [[ $game_over -eq 0 ]]; then
            draw_game
            process_input
            add_car
            move_cars
            check_crash
        else
            draw_game
            process_input
        fi
    done
}

# Clean up on exit
trap 'echo -ne "\033[?25h"; exit 0' INT TERM

main
