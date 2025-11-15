#!/bin/bash
# Hangman Game
words=("bash" "linux" "terminal" "script" "programming" "developer")
word=${words[$RANDOM % ${#words[@]}]}
guessed=()
lives=6

display_hangman() {
    clear
    echo "=== HANGMAN ==="
    echo "Lives: $lives"
    echo
    case $lives in
        6) echo "
          
          
          
          
          
          " ;;
        5) echo "
          
          
          
          
          
        ========" ;;
        4) echo "
          
            |
            |
            |
            |
        ========" ;;
        3) echo "
            ______
            |
            |
            |
            |
        ========" ;;
        2) echo "
            ______
            |    |
            |
            |
            |
        ========" ;;
        1) echo "
            ______
            |    |
            |    O
            |
            |
        ========" ;;
        0) echo "
            ______
            |    |
            |    O
            |   /|\\
            |   / \\
        ========" ;;
    esac
    echo
    for ((i=0; i<${#word}; i++)); do
        letter=${word:$i:1}
        if [[ " ${guessed[@]} " =~ " $letter " ]]; then
            echo -n "$letter "
        else
            echo -n "_ "
        fi
    done
    echo
    echo "Guessed: ${guessed[*]}"
}

while [[ $lives -gt 0 ]]; do
    display_hangman
    read -p "Guess a letter: " guess
    
    if [[ " ${guessed[@]} " =~ " $guess " ]]; then
        echo "Already guessed!"
        sleep 1
        continue
    fi
    
    guessed+=("$guess")
    if [[ $word == *"$guess"* ]]; then
        echo "Correct!"
        # Check if won
        won=1
        for ((i=0; i<${#word}; i++)); do
            letter=${word:$i:1}
            if [[ ! " ${guessed[@]} " =~ " $letter " ]]; then
                won=0
                break
            fi
        done
        [[ $won -eq 1 ]] && break
    else
        ((lives--))
        echo "Wrong!"
    fi
    sleep 1
done

display_hangman
if [[ $lives -gt 0 ]]; then
    echo "You won! The word was: $word"
else
    echo "Game Over! The word was: $word"
fi
