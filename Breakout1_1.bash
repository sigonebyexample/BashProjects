#!/bin/bash

# Simple Breakout clone - Reduced Blinking Version
width=60
height=20
paddle_pos=25
paddle_width=8
ball_x=30
ball_y=10
ball_dx=1
ball_dy=-1
score=0
lives=3
level=1
ball_launched=0

# Colors for terminal
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
WHITE='\033[1;37m'
NC='\033[0m'

# Game state
bricks=()

reset_bricks() {
    bricks=()
    # Create 3 rows of bricks
    for ((row=0; row<3; row++)); do
        for ((i=8; i<52; i+=5)); do
            bricks+=("$i:$((row+2))")
        done
    done
}

draw_breakout() {
    # Use printf for better cursor control
    printf "\033[H"  # Move cursor to home instead of clearing

    # Build the game area in memory
    local buffer=""
    buffer+="${YELLOW}=== BREAKOUT BASH === Score: $score Lives: $lives Level: $level ===\n"
    buffer+="Controls: A (left) D (right) ANY KEY to start Q (quit)\n"
    buffer+="============================================================${NC}\n"
    buffer+="\n"
    
    # Create an array for each row
    local rows=()
    for ((y=0; y<height; y++)); do
        rows[y]=$(printf '%*s' $width | tr ' ' ' ')
    done
    
    # Draw bricks
    for brick in "${bricks[@]}"; do
        brick_data=(${brick/:/ })
        bx=${brick_data[0]}
        by=${brick_data[1]}
        if (( by >= 0 && by < height && bx >= 0 && bx < width )); then
            row="${rows[$by]}"
            rows[$by]="${row:0:$bx}${RED}#${NC}${row:$((bx+1))}"
        fi
    done
    
    # Draw paddle
    for ((x=paddle_pos; x<=paddle_pos+paddle_width && x<width; x++)); do
        if (( height-1 >= 0 && height-1 < height && x >= 0 && x < width )); then
            row="${rows[$((height-1))]}"
            rows[$((height-1))]="${row:0:$x}${BLUE}=${NC}${row:$((x+1))}"
        fi
    done
    
    # Draw ball
    if (( ball_y >= 0 && ball_y < height && ball_x >= 0 && ball_x < width )); then
        row="${rows[$ball_y]}"
        rows[$ball_y]="${row:0:$ball_x}${WHITE}O${NC}${row:$((ball_x+1))}"
    fi
    
    # Build the final buffer
    for ((y=0; y<height; y++)); do
        buffer+="${rows[y]}\n"
    done
    
    buffer+="${YELLOW}============================================================${NC}\n"
    buffer+="\n"
    
    local total_bricks=${#bricks[@]}
    buffer+="Bricks left: $total_bricks\n"
    
    if [[ $ball_launched -eq 0 ]]; then
        buffer+="${GREEN}Press ANY KEY to start the ball!${NC}\n"
    fi
    
    # Print everything at once
    echo -e "$buffer"
}

move_ball() {
    # Move the ball
    ball_x=$((ball_x + ball_dx))
    ball_y=$((ball_y + ball_dy))

    # Wall collision
    if [[ $ball_x -le 0 ]]; then
        ball_x=1
        ball_dx=1
    elif [[ $ball_x -ge $((width-1)) ]]; then
        ball_x=$((width-2))
        ball_dx=-1
    fi

    if [[ $ball_y -le 0 ]]; then
        ball_y=1
        ball_dy=1
    fi

    # Paddle collision
    if [[ $ball_y -eq $((height-2)) ]]; then
        if [[ $ball_x -ge $paddle_pos && $ball_x -le $((paddle_pos+paddle_width)) ]]; then
            ball_y=$((height-3))
            ball_dy=-1
            # Change angle based on where ball hits paddle
            local hit_pos=$((ball_x - paddle_pos))
            if [[ $hit_pos -lt 2 ]]; then
                ball_dx=-1
            elif [[ $hit_pos -gt $((paddle_width-2)) ]]; then
                ball_dx=1
            fi
            ((score+=5))
        fi
    fi

    # Brick collision
    for i in "${!bricks[@]}"; do
        if [[ "${bricks[i]}" == "$ball_x:$ball_y" ]]; then
            unset 'bricks[i]'
            ball_dy=$(( -ball_dy ))
            ((score+=10))
            # Reindex the array
            bricks=("${bricks[@]}")
            break
        fi
    done

    # Lose life
    if [[ $ball_y -ge $height ]]; then
        ((lives--))
        if [[ $lives -gt 0 ]]; then
            # Reset ball position
            ball_x=$((paddle_pos + paddle_width/2))
            ball_y=$((height-2))
            ball_dx=0
            ball_dy=0
            ball_launched=0
        fi
    fi
}

show_game_over() {
    printf "\033[H"  # Move cursor to home
    echo -e "${RED}"
    echo "  GAME OVER"
    echo "  ========="
    echo -e "${NC}"
    echo -e "Final Score: $score"
    echo -e "Level Reached: $level"
    echo -e "\nPress any key to exit..."
    read -n 1
}

show_you_win() {
    printf "\033[H"  # Move cursor to home
    echo -e "${GREEN}"
    echo "  LEVEL COMPLETE!"
    echo "  ==============="
    echo -e "${NC}"
    echo -e "Score: $score"
    echo -e "Moving to level $((level+1))"
    echo -e "\nPress any key to continue..."
    read -n 1
}

main() {
    # Hide cursor
    echo -ne "\033[?25l"
    
    # Clear screen once at start
    clear
    
    echo "BREAKOUT - Reduced Blinking Version"
    echo "Controls: A (left) D (right) ANY KEY to start Q (quit)"
    echo "Press any key to start the game..."
    read -n 1

    # Initialize game
    reset_bricks

    # Main game loop
    while [[ $lives -gt 0 ]]; do
        draw_breakout

        # Wait for ANY key to launch ball
        if [[ $ball_launched -eq 0 ]]; then
            read -t 0.1 -n 1 input
            if [[ -n "$input" ]]; then
                # ANY key press will start the ball
                ball_dx=1
                ball_dy=-1
                ball_launched=1
            fi
        else
            # Ball is launched - move it automatically
            move_ball
        fi

        # Handle paddle movement with timeout (non-blocking)
        if read -t 0.05 -n 1 input; then
            case $input in
                a|A) [[ $paddle_pos -gt 0 ]] && ((paddle_pos--)) ;;
                d|D) [[ $paddle_pos -lt $((width-paddle_width-1)) ]] && ((paddle_pos++)) ;;
                q|Q) break ;;
            esac
        fi

        # Check level completion
        if [[ ${#bricks[@]} -eq 0 ]]; then
            ((level++))
            show_you_win
            reset_bricks
            paddle_pos=25
            ball_x=30
            ball_y=10
            ball_dx=1
            ball_dy=-1
            ball_launched=0

            # Increase difficulty
            if [[ $paddle_width -gt 4 ]]; then
                ((paddle_width--))
            fi
        fi
    done

    show_game_over
    
    # Show cursor
    echo -ne "\033[?25h"
}

# Handle cleanup on exit
trap 'echo -ne "\033[?25h"; stty echo; clear; exit 0' INT TERM EXIT

# Start game
main
