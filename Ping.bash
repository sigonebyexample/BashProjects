#!/bin/bash

# Pong game
width=60
height=20
paddle_size=3
paddle1_y=$((height/2))
paddle2_y=$((height/2))
ball_x=$((width/2))
ball_y=$((height/2))
ball_dx=1
ball_dy=1
score1=0
score2=0

draw_pong() {
    clear
    echo "PONG - Player 1: $score1 | Player 2: $score2"
    echo "Controls: Player1 (W/S) | Player2 (I/K) | Q=Quit"
    echo
    
    for ((y=0; y<height; y++)); do
        for ((x=0; x<width; x++)); do
            if [[ $x -eq 0 && $y -ge $paddle1_y && $y -lt $((paddle1_y + paddle_size)) ]]; then
                echo -n "|"
            elif [[ $x -eq $((width-1)) && $y -ge $paddle2_y && $y -lt $((paddle2_y + paddle_size)) ]]; then
                echo -n "|"
            elif [[ $x -eq $ball_x && $y -eq $ball_y ]]; then
                echo -n "●"
            elif [[ $x -eq $((width/2)) ]]; then
                echo -n "."
            else
                echo -n " "
            fi
        done
        echo
    done
}

move_ball() {
    ((ball_x += ball_dx))
    ((ball_y += ball_dy))
    
    # Wall collision
    if [[ $ball_y -le 0 || $ball_y -ge $((height-1)) ]]; then
        ball_dy=$(( -ball_dy ))
    fi
    
    # Paddle collision
    if [[ $ball_x -le 1 && $ball_y -ge $paddle1_y && $ball_y -lt $((paddle1_y + paddle_size)) ]]; then
        ball_dx=1
    elif [[ $ball_x -ge $((width-2)) && $ball_y -ge $paddle2_y && $ball_y -lt $((paddle2_y + paddle_size)) ]]; then
        ball_dx=-1
    fi
    
    # Score
    if [[ $ball_x -le 0 ]]; then
        ((score2++))
        reset_ball
    elif [[ $ball_x -ge $width ]]; then
        ((score1++))
        reset_ball
    fi
}

reset_ball() {
    ball_x=$((width/2))
    ball_y=$((height/2))
    ball_dx=$(( (RANDOM % 2) * 2 - 1 ))
    ball_dy=$(( (RANDOM % 2) * 2 - 1 ))
}

while true; do
    draw_pong
    
    # Move paddles based on input
    read -t 0.1 -n 1 input
    
    case $input in
        w) [[ $paddle1_y -gt 0 ]] && ((paddle1_y--)) ;;
        s) [[ $paddle1_y -lt $((height - paddle_size)) ]] && ((paddle1_y++)) ;;
        i) [[ $paddle2_y -gt 0 ]] && ((paddle2_y--)) ;;
        k) [[ $paddle2_y -lt $((height - paddle_size)) ]] && ((paddle2_y++)) ;;
        q) break ;;
    esac
    
    move_ball
    
    # Game over condition
    if [[ $score1 -ge 5 || $score2 -ge 5 ]]; then
        echo "Game Over! Final Score: $score1 - $score2"
        break
    fi
done
