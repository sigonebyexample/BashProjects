#!/bin/bash

# Secure Password Generator
generate_password() {
    local length=${1:-16}
    local use_special=${2:-true}

    local chars="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    if [[ "$use_special" == "true" ]]; then
        chars+="!@#$%^&*()_+-=[]{}|;:,.<>?"
    fi

    local password=""
    for ((i=0; i<length; i++)); do
        password+=${chars:$((RANDOM % ${#chars})):1}
    done

    echo "$password"
}

password_strength() {
    local password=$1
    local strength=0

    [[ ${#password} -ge 8 ]] && ((strength++))
    [[ $password =~ [a-z] ]] && ((strength++))
    [[ $password =~ [A-Z] ]] && ((strength++))
    [[ $password =~ [0-9] ]] && ((strength++))
    
    # Check for special characters using a safer approach
    if [[ "$password" =~ [!@#\$%^\&*()_+\-=\[\]{}|\;:,.\<\>?] ]]; then
        ((strength++))
    fi

    case $strength in
        5) echo "Very Strong" ;;
        4) echo "Strong" ;;
        3) echo "Good" ;;
        2) echo "Weak" ;;
        *) echo "Very Weak" ;;
    esac
}

main() {
    echo "=== PASSWORD GENERATOR ==="
    echo

    read -p "Password length (default 16): " length
    length=${length:-16}

    read -p "Include special characters? (y/n, default y): " special
    special=${special:-y}

    if [[ "$special" == "y" || "$special" == "Y" ]]; then
        use_special=true
    else
        use_special=false
    fi

    echo
    echo "Generating passwords..."
    echo

    for i in {1..5}; do
        password=$(generate_password $length $use_special)
        strength=$(password_strength "$password")
        printf "%-${length}s - %s\n" "$password" "$strength"
    done

    echo
    echo "Passwords generated successfully!"
}

main "$@"
