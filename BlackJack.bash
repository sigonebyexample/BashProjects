#!/bin/bash
balance=100

deal_card() {
    echo $((RANDOM % 11 + 1))
}

calculate_total() {
    local total=0
    for card in "$@"; do
        ((total += card))
    done
    echo $total
}

echo "BLACKJACK - Balance: $$balance"

while [[ $balance -gt 0 ]]; do
    echo
    read -p "Bet amount: " bet
    [[ $bet -gt $balance ]] && echo "Not enough balance!" && continue
    
    player_cards=($(deal_card) $(deal_card))
    dealer_cards=($(deal_card))
    
    player_total=$(calculate_total "${player_cards[@]}")
    dealer_total=$(calculate_total "${dealer_cards[@]}")
    
    echo "Your cards: ${player_cards[@]} Total: $player_total"
    echo "Dealer shows: ${dealer_cards[0]}"
    
    while [[ $player_total -lt 21 ]]; do
        read -p "Hit or Stand? (h/s): " choice
        [[ $choice == "s" ]] && break
        new_card=$(deal_card)
        player_cards+=($new_card)
        player_total=$(calculate_total "${player_cards[@]}")
        echo "New card: $new_card Total: $player_total"
    done
    
    while [[ $dealer_total -lt 17 ]]; do
        new_card=$(deal_card)
        dealer_cards+=($new_card)
        dealer_total=$(calculate_total "${dealer_cards[@]}")
    done
    
    echo "Dealer cards: ${dealer_cards[@]} Total: $dealer_total"
    
    if [[ $player_total -gt 21 ]]; then
        echo "You bust! Lose $$bet"
        ((balance -= bet))
    elif [[ $dealer_total -gt 21 ]]; then
        echo "Dealer busts! You win $$bet"
        ((balance += bet))
    elif [[ $player_total -gt $dealer_total ]]; then
        echo "You win! +$$bet"
        ((balance += bet))
    elif [[ $player_total -lt $dealer_total ]]; then
        echo "You lose! -$$bet"
        ((balance -= bet))
    else
        echo "Push! Bet returned"
    fi
    
    echo "Balance: $$balance"
    [[ $balance -eq 0 ]] && echo "You're out of money!" && break
    read -p "Play again? (y/n): " again
    [[ $again != "y" ]] && break
done

echo "Final balance: $$balance"
