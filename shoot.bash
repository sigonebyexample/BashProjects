#!/bin/bash

# Game settings
WIDTH=60
HEIGHT=20
PLAYER="^"
BULLET="|"
ALIEN="M"
EMPTY=" "

# Game state
player_x=30
player_y=18
bullets=()
aliens=()
alien_direction=1
alien_speed=2
alien_move_counter=0
score=0
game_over=0

# Initialize aliens
init_aliens() {
    aliens=()
    for ((i=2; i<5; i++)); do
        for ((j=10; j<50; j+=4)); do
            aliens+=("$j $i")
        done
    done
}

# Draw the game
draw() {
    clear
    
    # Create buffer
    local buffer=()
    for ((i=0; i<HEIGHT; i++)); do
        line=""
        for ((j=0; j<WIDTH; j++)); do
            line+="$EMPTY"
        done
        buffer[i]="$line"
    done
    
    # Draw player
    line="${buffer[$player_y]}"
    new_line="${line:0:$player_x}$PLAYER${line:$((player_x+1))}"
    buffer[$player_y]="$new_line"
    
    # Draw bullets
    for ((i=0; i<${#bullets[@]}; i++)); do
        local bullet_data=(${bullets[$i]})
        local bx=${bullet_data[0]}
        local by=${bullet_data[1]}
        if (( by >= 0 && by < HEIGHT && bx >= 0 && bx < WIDTH )); then
            line="${buffer[$by]}"
            new_line="${line:0:$bx}$BULLET${line:$((bx+1))}"
            buffer[$by]="$new_line"
        fi
    done
    
    # Draw aliens
    for alien in "${aliens[@]}"; do
        local alien_data=($alien)
        local ax=${alien_data[0]}
        local ay=${alien_data[1]}
        if (( ax >= 0 && ax < WIDTH && ay >= 0 && ay < HEIGHT )); then
            line="${buffer[$ay]}"
            new_line="${line:0:$ax}$ALIEN${line:$((ax+1))}"
            buffer[$ay]="$new_line"
        fi
    done
    
    # Draw border and buffer
    echo "+$(printf '%*s' $WIDTH | tr ' ' '-')+"
    for ((i=0; i<HEIGHT; i++)); do
        echo "|${buffer[i]}|"
    done
    echo "+$(printf '%*s' $WIDTH | tr ' ' '-')+"
    echo "Score: $score | Controls: A-left, D-right, W-shoot, Q-quit"
    
    if [[ $game_over -eq 1 ]]; then
        echo "GAME OVER! Final Score: $score"
    fi
}

# Move aliens
move_aliens() {
    ((alien_move_counter++))
    if (( alien_move_counter >= alien_speed )); then
        alien_move_counter=0
        
        local move_down=0
        local new_aliens=()
        
        # Check if aliens hit the wall
        for alien in "${aliens[@]}"; do
            local alien_data=($alien)
            local ax=${alien_data[0]}
            if (( (ax <= 1 && alien_direction == -1) || (ax >= WIDTH-2 && alien_direction == 1) )); then
                move_down=1
                break
            fi
        done
        
        # Move aliens
        for alien in "${aliens[@]}"; do
            local alien_data=($alien)
            local ax=${alien_data[0]}
            local ay=${alien_data[1]}
            
            if (( move_down == 1 )); then
                ((ay++))
                # Game over if aliens reach bottom
                if (( ay >= player_y )); then
                    game_over=1
                fi
            else
                ((ax += alien_direction))
            fi
            new_aliens+=("$ax $ay")
        done
        
        if (( move_down == 1 )); then
            ((alien_direction *= -1))
        fi
        
        aliens=("${new_aliens[@]}")
    fi
}

# Move bullets
move_bullets() {
    local new_bullets=()
    
    for ((i=0; i<${#bullets[@]}; i++)); do
        local bullet_data=(${bullets[$i]})
        local bx=${bullet_data[0]}
        local by=${bullet_data[1]}
        
        ((by--))
        
        # Remove bullet if it goes off screen
        if (( by > 0 )); then
            new_bullets+=("$bx $by")
        fi
    done
    
    bullets=("${new_bullets[@]}")
}

# Check collisions
check_collisions() {
    local new_aliens=()
    local new_bullets=()
    local hit=0
    
    # Check each bullet
    for ((i=0; i<${#bullets[@]}; i++)); do
        local bullet_data=(${bullets[$i]})
        local bx=${bullet_data[0]}
        local by=${bullet_data[1]}
        local bullet_hit=0
        
        # Check against each alien
        for ((j=0; j<${#aliens[@]}; j++)); do
            local alien_data=(${aliens[$j]})
            local ax=${alien_data[0]}
            local ay=${alien_data[1]}
            
            if [[ "$bx $by" == "$ax $ay" ]]; then
                ((score += 10))
                bullet_hit=1
                hit=1
                break
            fi
        done
        
        # Keep bullet if it didn't hit anything
        if [[ $bullet_hit -eq 0 ]]; then
            new_bullets+=("${bullets[$i]}")
        fi
    done
    
    # Rebuild aliens array (remove hit aliens)
    for alien in "${aliens[@]}"; do
        local alien_data=($alien)
        local ax=${alien_data[0]}
        local ay=${alien_data[1]}
        local alien_hit=0
        
        for bullet in "${bullets[@]}"; do
            if [[ "$ax $ay" == "$bullet" ]]; then
                alien_hit=1
                break
            fi
        done
        
        if [[ $alien_hit -eq 0 ]]; then
            new_aliens+=("$ax $ay")
        fi
    done
    
    bullets=("${new_bullets[@]}")
    aliens=("${new_aliens[@]}")
    
    # Check win condition
    if [[ ${#aliens[@]} -eq 0 ]]; then
        echo "YOU WIN! Final Score: $score"
        exit 0
    fi
}

# Process input
process_input() {
    local key
    read -t 0.1 -n 1 key
    
    case $key in
        a|A) ((player_x > 1)) && ((player_x--)) ;;
        d|D) ((player_x < WIDTH-2)) && ((player_x++)) ;;
        w|W) bullets+=("$player_x $((player_y-1))") ;;
        q|Q) game_over=1 ;;
    esac
}

# Main game loop
main() {
    # Hide cursor
    echo -ne "\033[?25l"
    
    # Initialize game
    init_aliens
    
    # Game loop
    while [[ $game_over -eq 0 ]]; do
        draw
        process_input
        move_bullets
        move_aliens
        check_collisions
        
        # Small delay
        sleep 0.1
    done
    
    draw
    echo "Press any key to exit..."
    read -n 1
    
    # Show cursor
    echo -ne "\033[?25h"
}

# Handle cleanup on exit
trap 'echo -ne "\033[?25h"; exit 0' INT TERM EXIT

# Start game
main
