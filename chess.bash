#!/bin/bash

# Chess Game in Bash
# Piece representation: 
# Lowercase = black, Uppercase = white
# p/P = pawn, r/R = rook, n/N = knight, b/B = bishop, q/Q = queen, k/K = king

declare -A board
selected_piece=""
selected_x=-1
selected_y=-1
current_player="white"
game_over=0
check=0

# Initialize the board
init_board() {
    # Set up empty board
    for ((i=0; i<8; i++)); do
        for ((j=0; j<8; j++)); do
            board[$i,$j]=" "
        done
    done

    # Set up pawns
    for ((i=0; i<8; i++)); do
        board[1,$i]="p"  # Black pawns
        board[6,$i]="P"  # White pawns
    done

    # Set up other pieces (black - lowercase)
    board[0,0]="r"; board[0,1]="n"; board[0,2]="b"; board[0,3]="q"
    board[0,4]="k"; board[0,5]="b"; board[0,6]="n"; board[0,7]="r"

    # Set up other pieces (white - uppercase)
    board[7,0]="R"; board[7,1]="N"; board[7,2]="B"; board[7,3]="Q"
    board[7,4]="K"; board[7,5]="B"; board[7,6]="N"; board[7,7]="R"
}

# Display the board
display_board() {
    clear
    echo "    a   b   c   d   e   f   g   h"
    echo "  +---+---+---+---+---+---+---+---+"
    
    for ((i=0; i<8; i++)); do
        echo -n "$((8-i)) |"
        for ((j=0; j<8; j++)); do
            piece="${board[$i,$j]}"
            # Add colors and proper symbols
            case $piece in
                "p") echo -ne " \033[34m♟\033[0m |" ;;  # Black pawn
                "r") echo -ne " \033[34m♜\033[0m |" ;;  # Black rook
                "n") echo -ne " \033[34m♞\033[0m |" ;;  # Black knight
                "b") echo -ne " \033[34m♝\033[0m |" ;;  # Black bishop
                "q") echo -ne " \033[34m♛\033[0m |" ;;  # Black queen
                "k") echo -ne " \033[34m♚\033[0m |" ;;  # Black king
                "P") echo -ne " \033[33m♙\033[0m |" ;;  # White pawn
                "R") echo -ne " \033[33m♖\033[0m |" ;;  # White rook
                "N") echo -ne " \033[33m♘\033[0m |" ;;  # White knight
                "B") echo -ne " \033[33m♗\033[0m |" ;;  # White bishop
                "Q") echo -ne " \033[33m♕\033[0m |" ;;  # White queen
                "K") echo -ne " \033[33m♔\033[0m |" ;;  # White king
                *) echo -ne " $piece |" ;;
            esac
        done
        echo -e "\n  +---+---+---+---+---+---+---+---+"
    done
    
    echo -e "\nCurrent Player: \033[1m$current_player\033[0m"
    if [[ $check -eq 1 ]]; then
        echo -e "\033[31mCHECK!\033[0m"
    fi
    echo "Commands: 'quit', 'reset', 'move e2 e4' or select piece"
}

# Convert algebraic notation to coordinates
algebraic_to_coords() {
    local alg=$1
    local col_char=${alg:0:1}
    local row=${alg:1:1}
    
    case $col_char in
        a) col=0 ;; b) col=1 ;; c) col=2 ;; d) col=3 ;;
        e) col=4 ;; f) col=5 ;; g) col=6 ;; h) col=7 ;;
        *) return 1 ;;
    esac
    
    row=$((8 - row))
    echo "$row $col"
}

# Convert coordinates to algebraic notation
coords_to_algebraic() {
    local row=$1
    local col=$2
    
    case $col in
        0) col_char="a" ;; 1) col_char="b" ;; 2) col_char="c" ;; 3) col_char="d" ;;
        4) col_char="e" ;; 5) col_char="f" ;; 6) col_char="g" ;; 7) col_char="h" ;;
    esac
    
    row=$((8 - row))
    echo "$col_char$row"
}

# Check if a square contains current player's piece
is_current_player_piece() {
    local piece=$1
    if [[ $current_player == "white" ]]; then
        [[ $piece =~ [A-Z] ]]
    else
        [[ $piece =~ [a-z] ]]
    fi
}

# Validate pawn movement
validate_pawn_move() {
    local start_row=$1 start_col=$2 end_row=$3 end_col=$4
    local piece=${board[$start_row,$start_col]}
    local direction=0
    local start_row_pawn=0
    
    if [[ $piece == "P" ]]; then
        direction=-1
        start_row_pawn=6
    else
        direction=1
        start_row_pawn=1
    fi
    
    # Normal move forward
    if [[ $start_col -eq $end_col ]] && [[ ${board[$end_row,$end_col]} == " " ]]; then
        # Single move forward
        if [[ $((start_row + direction)) -eq $end_row ]]; then
            return 0
        # Double move from starting position
        elif [[ $start_row -eq $start_row_pawn ]] && [[ $((start_row + 2 * direction)) -eq $end_row ]] && \
             [[ ${board[$((start_row + direction)),$start_col]} == " " ]]; then
            return 0
        fi
    # Capture diagonally
    elif [[ $((start_row + direction)) -eq $end_row ]] && \
         [[ $(($start_col - $end_col)) -eq 1 || $(($end_col - $start_col)) -eq 1 ]] && \
         [[ ${board[$end_row,$end_col]} != " " ]] && \
         ! is_current_player_piece "${board[$end_row,$end_col]}"; then
        return 0
    fi
    
    return 1
}

# Validate rook movement
validate_rook_move() {
    local start_row=$1 start_col=$2 end_row=$3 end_col=$4
    
    # Must move in straight line
    if [[ $start_row -ne $end_row ]] && [[ $start_col -ne $end_col ]]; then
        return 1
    fi
    
    # Check path is clear
    if [[ $start_row -eq $end_row ]]; then
        # Horizontal move
        local min_col=$((start_col < end_col ? start_col + 1 : end_col + 1))
        local max_col=$((start_col > end_col ? start_col - 1 : end_col - 1))
        for ((col=min_col; col<=max_col; col++)); do
            if [[ ${board[$start_row,$col]} != " " ]]; then
                return 1
            fi
        done
    else
        # Vertical move
        local min_row=$((start_row < end_row ? start_row + 1 : end_row + 1))
        local max_row=$((start_row > end_row ? start_row - 1 : end_row - 1))
        for ((row=min_row; row<=max_row; row++)); do
            if [[ ${board[$row,$start_col]} != " " ]]; then
                return 1
            fi
        done
    fi
    
    return 0
}

# Validate knight movement
validate_knight_move() {
    local start_row=$1 start_col=$2 end_row=$3 end_col=$4
    local row_diff=$((start_row - end_row))
    local col_diff=$((start_col - end_col))
    
    # Knight moves in L-shape: 2+1 or 1+2
    if { [[ $row_diff -eq 2 || $row_diff -eq -2 ]] && [[ $col_diff -eq 1 || $col_diff -eq -1 ]]; } || \
       { [[ $row_diff -eq 1 || $row_diff -eq -1 ]] && [[ $col_diff -eq 2 || $col_diff -eq -2 ]]; }; then
        return 0
    fi
    
    return 1
}

# Validate bishop movement
validate_bishop_move() {
    local start_row=$1 start_col=$2 end_row=$3 end_col=$4
    
    # Must move diagonally
    local row_diff=$((start_row - end_row))
    local col_diff=$((start_col - end_col))
    if [[ ${row_diff#-} -ne ${col_diff#-} ]]; then
        return 1
    fi
    
    # Check path is clear
    local row_step=$((start_row < end_row ? 1 : -1))
    local col_step=$((start_col < end_col ? 1 : -1))
    local steps=${row_diff#-}
    
    for ((i=1; i<steps; i++)); do
        local check_row=$((start_row + i * row_step))
        local check_col=$((start_col + i * col_step))
        if [[ ${board[$check_row,$check_col]} != " " ]]; then
            return 1
        fi
    done
    
    return 0
}

# Validate queen movement
validate_queen_move() {
    validate_rook_move $1 $2 $3 $4 || validate_bishop_move $1 $2 $3 $4
}

# Validate king movement
validate_king_move() {
    local start_row=$1 start_col=$2 end_row=$3 end_col=$4
    local row_diff=$((start_row - end_row))
    local col_diff=$((start_col - end_col))
    
    # King moves one square in any direction
    if [[ ${row_diff#-} -le 1 ]] && [[ ${col_diff#-} -le 1 ]]; then
        return 0
    fi
    
    return 1
}

# Validate a move
validate_move() {
    local start_row=$1 start_col=$2 end_row=$3 end_col=$4
    local piece=${board[$start_row,$start_col]}
    local target_piece=${board[$end_row,$end_col]}
    
    # Can't move to square with own piece
    if [[ $target_piece != " " ]] && is_current_player_piece "$target_piece"; then
        return 1
    fi
    
    # Validate based on piece type
    case ${piece,,} in  # Convert to lowercase for comparison
        p) validate_pawn_move $start_row $start_col $end_row $end_col ;;
        r) validate_rook_move $start_row $start_col $end_row $end_col ;;
        n) validate_knight_move $start_row $start_col $end_row $end_col ;;
        b) validate_bishop_move $start_row $start_col $end_row $end_col ;;
        q) validate_queen_move $start_row $start_col $end_row $end_col ;;
        k) validate_king_move $start_row $start_col $end_row $end_col ;;
        *) return 1 ;;
    esac
}

# Make a move
make_move() {
    local start_row=$1 start_col=$2 end_row=$3 end_col=$4
    local piece=${board[$start_row,$start_col]}
    
    # Store the move for potential undo
    board[$end_row,$end_col]=${board[$start_row,$start_col]}
    board[$start_row,$start_col]=" "
    
    # Switch player
    if [[ $current_player == "white" ]]; then
        current_player="black"
    else
        current_player="white"
    fi
    
    # Simple check detection (basic implementation)
    check=0
    find_kings
    if is_king_in_check; then
        check=1
    fi
}

# Find kings on the board (simplified)
find_kings() {
    white_king_pos=""
    black_king_pos=""
    
    for ((i=0; i<8; i++)); do
        for ((j=0; j<8; j++)); do
            if [[ ${board[$i,$j]} == "K" ]]; then
                white_king_pos="$i $j"
            elif [[ ${board[$i,$j]} == "k" ]]; then
                black_king_pos="$i $j"
            fi
        done
    done
}

# Check if king is in check (simplified)
is_king_in_check() {
    # This is a simplified check - in a real implementation, you'd check all opponent pieces
    return 0  # Placeholder
}

# Main game loop
main() {
    init_board
    
    while [[ $game_over -eq 0 ]]; do
        display_board
        
        echo -e "\nEnter your move (e.g., 'e2 e4' or 'quit'): "
        read -r input
        
        case $input in
            quit|exit)
                echo "Thanks for playing!"
                exit 0
                ;;
            reset)
                init_board
                current_player="white"
                check=0
                echo "Game reset!"
                sleep 1
                continue
                ;;
            [a-h][1-8]\ [a-h][1-8])
                # Parse algebraic notation move
                start_alg=${input:0:2}
                end_alg=${input:3:2}
                
                if ! start_coords=$(algebraic_to_coords "$start_alg") || \
                   ! end_coords=$(algebraic_to_coords "$end_alg"); then
                    echo "Invalid coordinates!"
                    sleep 1
                    continue
                fi
                
                start_row=$(echo $start_coords | cut -d' ' -f1)
                start_col=$(echo $start_coords | cut -d' ' -f2)
                end_row=$(echo $end_coords | cut -d' ' -f1)
                end_col=$(echo $end_coords | cut -d' ' -f2)
                
                piece=${board[$start_row,$start_col]}
                
                # Validate selection and move
                if [[ $piece == " " ]]; then
                    echo "No piece at $start_alg!"
                    sleep 1
                elif ! is_current_player_piece "$piece"; then
                    echo "That's not your piece!"
                    sleep 1
                elif validate_move $start_row $start_col $end_row $end_col; then
                    make_move $start_row $start_col $end_row $end_col
                    echo "Move made: $start_alg -> $end_alg"
                    sleep 1
                else
                    echo "Invalid move for $piece!"
                    sleep 1
                fi
                ;;
            *)
                echo "Invalid command! Use format: 'e2 e4' or 'quit'"
                sleep 1
                ;;
        esac
    done
}

# Handle cleanup
trap 'echo -e "\nGame ended."; exit 0' INT TERM

# Start the game
echo "Welcome to Bash Chess!"
echo "Piece symbols: ♙♘♗♖♕♔ (white) ♟♞♝♜♛♚ (black)"
echo "Enter moves in algebraic notation like: e2 e4"
echo "Press Ctrl+C to quit at any time"
sleep 2
main
