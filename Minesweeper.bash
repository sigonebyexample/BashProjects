
#!/bin/bash

# Minesweeper - 90s Style

# Game settings
GRID_SIZE=10
MINES=15
EMPTY=" ."
FLAG=" ⚑"
MINE=" 💣"
BORDER="██"

# Game state
grid=()
visible=()
flags=()
game_over=0
game_won=0
first_click=1

init_game() {
    grid=()
    visible=()
    flags=()
    game_over=0
    game_won=0
    first_click=1
    
    # Initialize empty grid
    for ((i=0; i<GRID_SIZE*GRID_SIZE; i++)); do
        grid[i]=0
        visible[i]=0
        flags[i]=0
    done
}

place_mines() {
    local click_x=$1
    local click_y=$2
    local mines_placed=0
    
    while [[ $mines_placed -lt $MINES ]]; do
        local x=$((RANDOM % GRID_SIZE))
        local y=$((RANDOM % GRID_SIZE))
        
        # Don't place mine on first click position or adjacent
        if (( abs(x - click_x) > 1 || abs(y - click_y) > 1 )) && [[ ${grid[$((y * GRID_SIZE + x))]} -eq 0 ]]; then
            grid[$((y * GRID_SIZE + x))]=9
            ((mines_placed++))
            
            # Update adjacent counts
            for ((dy=-1; dy<=1; dy++)); do
                for ((dx=-1; dx<=1; dx++)); do
                    local nx=$((x + dx))
                    local ny=$((y + dy))
                    if (( nx >= 0 && nx < GRID_SIZE && ny >= 0 && ny < GRID_SIZE )) && 
                       [[ ${grid[$((ny * GRID_SIZE + nx))]} -ne 9 ]]; then
                        ((grid[$((ny * GRID_SIZE + nx))]++))
                    fi
                done
            done
        fi
    done
}

abs() {
    echo $1 | awk '{print $1 < 0 ? -$1 : $1}'
}

reveal_cell() {
    local x=$1
    local y=$2
    
    if (( x < 0 || x >= GRID_SIZE || y < 0 || y >= GRID_SIZE )) || 
       [[ ${visible[$((y * GRID_SIZE + x))]} -eq 1 ]] || 
       [[ ${flags[$((y * GRID_SIZE + x))]} -eq 1 ]]; then
        return
    fi
    
    visible[$((y * GRID_SIZE + x))]=1
    
    # If it's an empty cell, reveal neighbors
    if [[ ${grid[$((y * GRID_SIZE + x))]} -eq 0 ]]; then
        for ((dy=-1; dy<=1; dy++)); do
            for ((dx=-1; dx<=1; dx++)); do
                reveal_cell $((x + dx)) $((y + dy))
            done
        done
    fi
}

check_win() {
    local revealed=0
    for ((i=0; i<GRID_SIZE*GRID_SIZE; i++)); do
        if [[ ${visible[i]} -eq 1 ]] && [[ ${grid[i]} -ne 9 ]]; then
            ((revealed++))
        fi
    done
    
    if [[ $revealed -eq $((GRID_SIZE * GRID_SIZE - MINES)) ]]; then
        game_won=1
    fi
}

draw_game() {
    clear
    
    echo "    M I N E S W E E P E R"
    echo " Mines: $MINES"
    echo "┌──────────────────────┐"
    
    for ((y=0; y<GRID_SIZE; y++)); do
        line="│"
        for ((x=0; x<GRID_SIZE; x++)); do
            local index=$((y * GRID_SIZE + x))
            local cell="$EMPTY"
            
            if [[ ${flags[$index]} -eq 1 ]]; then
                cell="$FLAG"
            elif [[ ${visible[$index]} -eq 1 ]]; then
                case ${grid[$index]} in
                    0) cell="  " ;;
                    1) cell=" 1" ;;
                    2) cell=" 2" ;;
                    3) cell=" 3" ;;
                    4) cell=" 4" ;;
                    5) cell=" 5" ;;
                    6) cell=" 6" ;;
                    7) cell=" 7" ;;
                    8) cell=" 8" ;;
                    9) cell="$MINE" ;;
                esac
            fi
            
            line+="$cell"
        done
        line+="│"
        echo "$line"
    done
    
    echo "└──────────────────────┘"
    echo " Controls:"
    echo "   WASD: Move cursor"
    echo "   Space: Reveal cell"
    echo "   F: Place/remove flag"
    echo "   R: Restart  Q: Quit"
    
    if [[ $game_over -eq 1 ]]; then
        echo
        echo "   BOOM! Game Over!"
        echo "   Press R to restart"
    elif [[ $game_won -eq 1 ]]; then
        echo
        echo "   Congratulations! You won!"
        echo "   Press R to play again"
    fi
}

main() {
    echo -ne "\033[?25l"
    
    echo "M I N E S W E E P E R"
    echo "Find all mines without triggering them!"
    echo "Use flags to mark suspected mines."
    echo "Press any key to start..."
    read -n 1
    
    init_game
    draw_game
    
    local cursor_x=0
    local cursor_y=0
    
    while true; do
        if [[ $game_over -eq 0 ]] && [[ $game_won -eq 0 ]]; then
            # Show cursor
            tput cup $((cursor_y + 5)) $((cursor_x * 2 + 2))
            echo -ne "[]"
            tput cup $((cursor_y + 5)) $((cursor_x * 2 + 2))
            
            read -n 1 key
            # Hide cursor
            tput cup $((cursor_y + 5)) $((cursor_x * 2 + 2))
            case ${grid[$((cursor_y * GRID_SIZE + cursor_x))]} in
                0) echo -ne "  " ;;
                *) echo -ne " ${grid[$((cursor_y * GRID_SIZE + cursor_x))]}" ;;
            esac
            
            case $key in
                w|W) [[ $cursor_y -gt 0 ]] && ((cursor_y--)) ;;
                s|S) [[ $cursor_y -lt $((GRID_SIZE-1)) ]] && ((cursor_y++)) ;;
                a|A) [[ $cursor_x -gt 0 ]] && ((cursor_x--)) ;;
                d|D) [[ $cursor_x -lt $((GRID_SIZE-1)) ]] && ((cursor_x++)) ;;
                " ")
                    if [[ $first_click -eq 1 ]]; then
                        place_mines $cursor_x $cursor_y
                        first_click=0
                    fi
                    
                    if [[ ${grid[$((cursor_y * GRID_SIZE + cursor_x))]} -eq 9 ]]; then
                        game_over=1
                        # Reveal all mines
                        for ((i=0; i<GRID_SIZE*GRID_SIZE; i++)); do
                            if [[ ${grid[i]} -eq 9 ]]; then
                                visible[i]=1
                            fi
                        done
                    else
                        reveal_cell $cursor_x $cursor_y
                        check_win
                    fi
                    ;;
                f|F)
                    if [[ ${visible[$((cursor_y * GRID_SIZE + cursor_x))]} -eq 0 ]]; then
                        flags[$((cursor_y * GRID_SIZE + cursor_x))]=$((1 - flags[$((cursor_y * GRID_SIZE + cursor_x))]))
                    fi
                    ;;
                r|R) init_game ;;
                q|Q) break ;;
            esac
            
            draw_game
        else
            read -n 1 key
            case $key in
                r|R) 
                    init_game
                    draw_game
                    cursor_x=0
                    cursor_y=0
                    ;;
                q|Q) break ;;
            esac
        fi
    done
    
    echo -ne "\033[?25h"
}

trap 'echo -ne "\033[?25h"; exit 0' INT TERM
main
