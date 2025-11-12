#!/bin/bash
cards=(A A B B C C D D E E F F)
shuffled=($(shuf -e "${cards[@]}"))
revealed=()
score=0
attempts=0

display_board() {
    clear
    echo "MEMORY GAME - Score: $score Attempts: $attempts"
    echo "Press 'q' at any time to quit"
    echo
    for ((i=0; i<12; i++)); do
        if [[ " ${revealed[@]} " =~ " $i " ]]; then
            echo -n "[${shuffled[i]}] "
        else
            echo -n "[?] "
        fi
        [[ $(((i+1)%4)) -eq 0 ]] && echo
    done
}

# Initial preview of all cards
clear
echo "MEMORY GAME - Memorize the cards! (30 seconds)"
echo
for ((i=0; i<12; i++)); do
    echo -n "[${shuffled[i]}] "
    [[ $(((i+1)%4)) -eq 0 ]] && echo
done
echo
echo "You have 5 seconds to memorize the cards..."
echo "Game will start automatically after the timer."

# Countdown timer
for ((i=5; i>0; i--)); do
    echo -ne "Time remaining: $i seconds\r"
    sleep 1
done

echo
echo "Time's up! Game starting..."
sleep 2

while [[ ${#revealed[@]} -lt 12 ]]; do
    display_board
    echo "Enter two card numbers (1-12) or 'q' to quit:"
    
    # First card input with quit check
    read -p "First: " card1
    if [[ "$card1" == "q" || "$card1" == "Q" ]]; then
        echo "Game quit. Final score: $score"
        exit 0
    fi
    
    # Second card input with quit check
    read -p "Second: " card2
    if [[ "$card2" == "q" || "$card2" == "Q" ]]; then
        echo "Game quit. Final score: $score"
        exit 0
    fi
    
    # Validate input
    if ! [[ "$card1" =~ ^[0-9]+$ ]] || ! [[ "$card2" =~ ^[0-9]+$ ]] || 
         [[ $card1 -lt 1 || $card1 -gt 12 ]] || 
         [[ $card2 -lt 1 || $card2 -gt 12 ]]; then
        echo "Invalid input. Please enter numbers between 1-12."
        sleep 2
        continue
    fi
    
    ((attempts++))
    
    # Check if cards are already revealed
    if [[ " ${revealed[@]} " =~ " $((card1-1)) " ]] || [[ " ${revealed[@]} " =~ " $((card2-1)) " ]]; then
        echo "One or both cards are already matched. Try different cards."
        sleep 2
        continue
    fi
    
    # Show temporary reveal
    clear
    echo "MEMORY GAME - Score: $score Attempts: $attempts"
    echo
    for ((i=0; i<12; i++)); do
        if [[ " ${revealed[@]} " =~ " $i " ]] || [[ $i -eq $((card1-1)) ]] || [[ $i -eq $((card2-1)) ]]; then
            echo -n "[${shuffled[i]}] "
        else
            echo -n "[?] "
        fi
        [[ $(((i+1)%4)) -eq 0 ]] && echo
    done
    
    if [[ ${shuffled[$card1-1]} == "${shuffled[$card2-1]}" && $card1 -ne $card2 ]]; then
        revealed+=($((card1-1)) $((card2-1)))
        ((score+=10))
        echo "Match found!"
    else
        echo "No match. Try again."
    fi
    sleep 3
done

echo "You won! Final score: $score (Attempts: $attempts)"
