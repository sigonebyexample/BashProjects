#!/bin/bash
# Load Balancer - Round-robin request distribution
# Usage: ./load_balancer.bash [config_file]
# Example: ./load_balancer.bash servers.txt

show_usage() {
    echo "Load Balancer - Round-robin distribution"
    echo "Usage: ./load_balancer.bash [config_file]"
    echo "Config file format: one server per line (host:port)"
    echo "Example: ./load_balancer.bash servers.txt"
    echo "Default servers: 192.168.1.10:80, 192.168.1.11:80, 192.168.1.12:80"
}

# Default servers
default_servers=("192.168.1.10:80" "192.168.1.11:80" "192.168.1.12:80")
current=0

load_servers_from_file() {
    local config_file=$1
    if [[ -f "$config_file" ]]; then
        mapfile -t servers < "$config_file"
        echo "Loaded ${#servers[@]} servers from $config_file"
    else
        echo "Config file not found, using default servers"
        servers=("${default_servers[@]}")
    fi
}

balance_request() {
    local path=$1
    local server=${servers[current]}
    
    echo "$(date): Routing to $server$path"
    response=$(curl -s -w "%{http_code}" "http://$server$path" 2>/dev/null)
    status_code=${response: -3}
    content=${response%???}
    
    echo "Response: HTTP $status_code"
    echo "Content: $content"
    echo "---"
    
    current=$(( (current + 1) % ${#servers[@]} ))
}

if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    show_usage
    exit 0
fi

# Load servers
if [[ $# -ge 1 ]]; then
    load_servers_from_file "$1"
else
    servers=("${default_servers[@]}")
    echo "Using default servers"
fi

echo "Load Balancer Started with ${#servers[@]} servers"
echo "Available commands: /request <path>, /stats, /quit"
echo "================================================="

while true; do
    read -p "lb> " command
    case $command in
        "/request "*)
            path=${command#/request }
            balance_request "$path"
            ;;
        "/stats")
            echo "Server Statistics:"
            for i in "${!servers[@]}"; do
                echo "  $i: ${servers[i]} $( [[ $i -eq $current ]] && echo "(next)" )"
            done
            ;;
        "/quit")
            echo "Goodbye!"
            exit 0
            ;;
        *)
            echo "Unknown command. Use /request <path>, /stats, or /quit"
            ;;
    esac
done
