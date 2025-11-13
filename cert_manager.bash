#!/bin/bash
# SSL/TLS Certificate Manager
# Usage: ./cert_manager.bash <command> <domain>
# Commands: check, renew, create, monitor

show_usage() {
    echo "SSL/TLS Certificate Manager"
    echo "Usage: ./cert_manager.bash <command> <domain>"
    echo "Commands:"
    echo "  check <domain>    - Check certificate validity"
    echo "  renew <domain>    - Renew certificate"
    echo "  create <domain>   - Create new certificate"
    echo "  monitor <domain>  - Monitor certificate expiry"
    echo "Example: ./cert_manager.bash check example.com"
}

check_certificate() {
    local domain=$1
    echo "Checking certificate for: $domain"
    
    if ! openssl s_client -connect "$domain:443" -servername "$domain" < /dev/null 2>/dev/null | openssl x509 -noout -dates; then
        echo "Error: Could not retrieve certificate for $domain"
        return 1
    fi
    
    expiry_date=$(openssl s_client -connect "$domain:443" -servername "$domain" < /dev/null 2>/dev/null | openssl x509 -noout -enddate | cut -d= -f2)
    expiry_epoch=$(date -d "$expiry_date" +%s)
    current_epoch=$(date +%s)
    days_until_expiry=$(( (expiry_epoch - current_epoch) / 86400 ))
    
    echo "Days until expiry: $days_until_expiry"
    
    if [[ $days_until_expiry -lt 30 ]]; then
        echo "WARNING: Certificate expires in less than 30 days!"
    fi
}

renew_certificate() {
    local domain=$1
    echo "Renewing certificate for: $domain"
    
    if command -v certbot >/dev/null 2>&1; then
        certbot renew --cert-name "$domain"
        systemctl reload nginx 2>/dev/null || echo "Note: nginx reload skipped"
    else
        echo "Error: certbot not found. Please install certbot."
        return 1
    fi
}

create_certificate() {
    local domain=$1
    echo "Creating certificate for: $domain"
    
    if command -v certbot >/dev/null 2>&1; then
        certbot certonly --nginx -d "$domain"
    else
        echo "Error: certbot not found. Please install certbot."
        return 1
    fi
}

monitor_certificate() {
    local domain=$1
    echo "Monitoring certificate for: $domain"
    
    while true; do
        check_certificate "$domain"
        echo "Next check in 1 hour..."
        sleep 3600
    done
}

if [[ $# -lt 2 ]]; then
    show_usage
    exit 1
fi

case "$1" in
    "check")
        check_certificate "$2"
        ;;
    "renew")
        renew_certificate "$2"
        ;;
    "create")
        create_certificate "$2"
        ;;
    "monitor")
        monitor_certificate "$2"
        ;;
    *)
        show_usage
        exit 1
        ;;
esac
