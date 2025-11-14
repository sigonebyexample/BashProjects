#!/bin/bash

# SSL Certificate Expiry Checker
check_certificate() {
    local domain=$1
    local port=${2:-443}
    
    echo "Checking certificate for: $domain:$port"
    echo
    
    # Get certificate info
    local cert_info
    cert_info=$(openssl s_client -connect "$domain:$port" -servername "$domain" < /dev/null 2>/dev/null | openssl x509 -noout -dates 2>/dev/null)
    
    if [[ $? -ne 0 ]]; then
        echo "Error: Could not retrieve certificate for $domain"
        return 1
    fi
    
    # Extract dates
    local not_after=$(echo "$cert_info" | grep "notAfter" | cut -d'=' -f2)
    local not_before=$(echo "$cert_info" | grep "notBefore" | cut -d'=' -f2)
    
    # Convert to timestamp
    local expiry_timestamp=$(date -d "$not_after" +%s 2>/dev/null)
    local current_timestamp=$(date +%s)
    local days_until_expiry=$(( (expiry_timestamp - current_timestamp) / 86400 ))
    
    echo "Domain:         $domain"
    echo "Valid From:     $not_before"
    echo "Expires:        $not_after"
    echo "Days Left:      $days_until_expiry"
    
    # Warning colors
    if [[ $days_until_expiry -lt 0 ]]; then
        echo -e "Status:         \033[1;31mEXPIRED\033[0m"
    elif [[ $days_until_expiry -lt 7 ]]; then
        echo -e "Status:         \033[1;31mCRITICAL ($days_until_expiry days)\033[0m"
    elif [[ $days_until_expiry -lt 30 ]]; then
        echo -e "Status:         \033[1;33mWARNING ($days_until_expiry days)\033[0m"
    else
        echo -e "Status:         \033[1;32mOK ($days_until_expiry days)\033[0m"
    fi
    echo
}

main() {
    echo "=== SSL CERTIFICATE CHECKER ==="
    echo
    
    if [[ $# -eq 0 ]]; then
        # Check common domains
        domains=(
            "google.com"
            "github.com"
            "stackoverflow.com"
            "wikipedia.org"
        )
        
        for domain in "${domains[@]}"; do
            check_certificate "$domain"
        done
    else
        check_certificate "$1" "$2"
    fi
}

main "$@"
