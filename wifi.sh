#!/bin/bash

# Colors with proper escape sequences
RED='\e[0;31m'
GREEN='\e[0;32m'
BLUE='\e[0;34m'
YELLOW='\e[1;33m'
PURPLE='\e[0;35m'
CYAN='\e[0;36m'
WHITE='\e[1;37m'
NC='\e[0m'
BOLD='\e[1m'
DIM='\e[2m'
BLINK='\e[5m'

# Quirky messages arrays
SCANNING_MSGS=(
    "Sniffing the airwaves like a digital bloodhound..."
    "Poking the WiFi gods with a stick..."
    "Asking the internet nicely to show itself..."
    "Summoning networks from the ethernet realm..."
    "Teaching my antenna some new dance moves..."
    "Bribing radio waves with coffee..."
)

CONNECTING_MSGS=(
    "Doing the WiFi handshake (it's awkward)..."
    "Negotiating with the router's bouncer..."
    "Whispering sweet nothings to the access point..."
    "Performing ancient WiFi rituals..."
    "Convincing the network I'm not a threat..."
    "Playing rock-paper-scissors with encryption..."
)

SUCCESS_MSGS=(
    "We're in! *hacker voice* I'm in..."
    "Connection successful! Time to download the entire internet!"
    "You're now part of the network resistance!"
    "Welcome to the matrix, Neo..."
    "Houston, we have WiFi!"
    "Connection achieved! Your digital leash is now attached!"
)

FAIL_MSGS=(
    "Well, that was embarrassing..."
    "The WiFi gods have rejected your offering!"
    "Connection failed harder than my dating life..."
    "Nope. Not today, Satan."
    "Error 404: WiFi cooperation not found"
    "The network said 'it's not you, it's me' and left..."
)

# Function to get random message
get_random_msg() {
    local arr_name=$1[@]
    local arr=("${!arr_name}")
    echo "${arr[$RANDOM % ${#arr[@]}]}"
}

# Animated spinner
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    while kill -0 $pid 2>/dev/null; do
        local temp=${spinstr#?}
        printf " [%c] " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b"
    done
    printf "     \b\b\b\b\b"
}

# Clear screen with style
clear_screen() {
    clear
    printf "${PURPLE}${BOLD}"
    echo ""
    echo "    ██╗    ██╗██╗███████╗██╗    ██╗██╗███████╗██╗    "
    echo "    ██║    ██║██║██╔════╝██║    ██║██║╚══███╔╝██║    "
    echo "    ██║ █╗ ██║██║█████╗  ██║ █╗ ██║██║  ███╔╝ ██║    "
    echo "    ██║███╗██║██║██╔══╝  ██║███╗██║██║ ███╔╝  ╚═╝    "
    echo "    ╚███╔███╔╝██║██║     ╚███╔███╔╝██║███████╗██╗    "
    echo "     ╚══╝╚══╝ ╚═╝╚═╝      ╚══╝╚══╝ ╚═╝╚══════╝╚═╝    "
    echo ""
    printf "              ${CYAN}Network Management Suite${NC}\n"
    echo ""
}

# Check NetworkManager
check_nm() {
    if ! systemctl is-active --quiet NetworkManager; then
        printf "${RED}${BOLD}🚨 ALERT ALERT! 🚨${NC}\n"
        printf "${RED}NetworkManager is taking a nap! Wake it up with:${NC}\n"
        printf "${YELLOW}${BOLD}sudo systemctl start NetworkManager${NC}\n"
        printf "${DIM}(Or just restart your computer like a normal person)${NC}\n"
        exit 1
    fi
}

# Scan networks
scan_networks() {
    local scan_msg=$(get_random_msg SCANNING_MSGS)
    printf "${YELLOW}🔍 ${scan_msg}${NC}\n"
    
    # Animated scanning
    (nmcli device wifi rescan 2>/dev/null; sleep 2) &
    spinner $!
    wait
    
    printf "\n"
    
    # Get networks
    networks=$(nmcli -t -f SSID,SIGNAL,SECURITY device wifi list | grep -v '^$' | sort -t: -k2 -nr)
    
    if [ -z "$networks" ]; then
        printf "${RED}${BOLD}No networks found${NC}\n"
        printf "${DIM}Try moving to a different location${NC}\n"
        return 1
    fi
    
    # Clear and declare global network map
    unset network_map
    declare -gA network_map
    
    i=1
    
    printf "${BOLD}${WHITE}📡 Available Networks${NC}\n"
    printf "${DIM}────────────────────────────────────────────${NC}\n"
    
    while IFS=: read -r ssid signal security; do
        if [ ! -z "$ssid" ] && [ ${#ssid} -gt 0 ]; then
            # Store the mapping FIRST
            network_map[$i]="$ssid"
            
            # Truncate long SSIDs for display
            display_ssid=$(echo "$ssid" | cut -c1-22)
            if [ ${#ssid} -gt 22 ]; then
                display_ssid="${display_ssid}..."
            fi
            
            # Security with personality
            if [ "$security" = "--" ]; then
                sec_text="${GREEN}Open${NC}"
                vibe="🔓"
            else
                sec_text="${RED}Secure${NC}"
                vibe="🔒"
            fi
            
            # Signal strength with attitude
            if [ "$signal" -gt 80 ]; then
                signal_display="${GREEN}●●●●${NC} ${BOLD}${signal}%${NC}"
            elif [ "$signal" -gt 60 ]; then
                signal_display="${YELLOW}●●●○${NC} ${BOLD}${signal}%${NC}"
            elif [ "$signal" -gt 40 ]; then
                signal_display="${YELLOW}●●○○${NC} ${BOLD}${signal}%${NC}"
            elif [ "$signal" -gt 20 ]; then
                signal_display="${RED}●○○○${NC} ${BOLD}${signal}%${NC}"
            else
                signal_display="${RED}○○○○${NC} ${BOLD}${signal}%${NC}"
            fi
            
            printf "${BOLD}%2d${NC} │ %-20s │ %-12s │ %-8s │ %s\n" \
                   "$i" "$display_ssid" "$(printf '%b' "$signal_display")" "$(printf '%b' "$sec_text")" "$vibe"
            
            ((i++))
            
            # Limit to 15 networks
            if [ $i -gt 15 ]; then
                break
            fi
        fi
    done <<< "$networks"
    
    printf "${DIM}────────────────────────────────────────────${NC}\n"
}

# Function to read password with asterisk masking
read_password() {
    local password=""
    local char=""
    
    printf "${WHITE}Password: ${NC}"
    
    while IFS= read -r -s -n1 char; do
        if [[ $char == $'\0' ]]; then     # Enter pressed
            break
        elif [[ $char == $'\177' ]]; then # Backspace pressed
            if [ ${#password} -gt 0 ]; then
                password="${password%?}"
                printf '\b \b'  # Move back, print space, move back again
            fi
        else
            password+="$char"
            printf '*'
        fi
    done
    
    echo "$password"
}

# Connect function with retries and better error handling
connect_network() {
    local ssid="$1"
    local max_retries=3
    local attempt=1
    
    printf "\n${CYAN}${BOLD}🎯 Target: ${WHITE}$ssid${NC}\n"
    
    # Check security - Get security info properly
    security=$(nmcli -t -f SSID,SECURITY device wifi list | grep "^$ssid:" | head -n1 | cut -d: -f2)
    
    if [ "$security" != "--" ]; then
        printf "${YELLOW}🔐 Network secured${NC}\n"
        
        while [ $attempt -le $max_retries ]; do
            if [ $attempt -gt 1 ]; then
                printf "\n${YELLOW}Attempt ${attempt}/${max_retries}${NC}\n"
            fi
            
            password=$(read_password)
            echo  # New line after password input
            
            if [ ${#password} -lt 8 ] && [ ${#password} -gt 0 ]; then
                printf "${RED}${BOLD}Password too short!${NC}\n"
                printf "${DIM}Most WiFi passwords are at least 8 characters${NC}\n"
                if [ $attempt -lt $max_retries ]; then
                    printf "${YELLOW}Try again...${NC}\n"
                    ((attempt++))
                    continue
                else
                    return 1
                fi
            fi
            
            local connect_msg=$(get_random_msg CONNECTING_MSGS)
            printf "${YELLOW}${connect_msg}${NC}\n"
            
            # First, forget any existing connection to this SSID
            nmcli connection delete "$ssid" 2>/dev/null
            
            # Try to connect with detailed error output
            connect_output=$(nmcli device wifi connect "$ssid" password "$password" 2>&1)
            connect_result=$?
            
            # Show spinner during connection attempt
            sleep 2
            
            if [ $connect_result -eq 0 ]; then
                local success_msg=$(get_random_msg SUCCESS_MSGS)
                printf "${GREEN}${BOLD}✅ ${success_msg}${NC}\n"
                
                # Show connection details
                sleep 1
                ip=$(ip route get 8.8.8.8 2>/dev/null | grep -oP 'src \K\S+')
                if [ -n "$ip" ]; then
                    printf "${BLUE}IP: ${BOLD}$ip${NC}\n"
                fi
                return 0
            else
                # Parse error message for better feedback
                if echo "$connect_output" | grep -q "Secrets were required"; then
                    printf "${RED}${BOLD}❌ Wrong password${NC}\n"
                elif echo "$connect_output" | grep -q "already exists"; then
                    printf "${YELLOW}Removing old connection and retrying...${NC}\n"
                    nmcli connection delete "$ssid" 2>/dev/null
                elif echo "$connect_output" | grep -q "No network with SSID"; then
                    printf "${RED}${BOLD}❌ Network not found${NC}\n"
                    return 1
                else
                    printf "${RED}${BOLD}❌ Connection failed${NC}\n"
                    printf "${DIM}Error: $connect_output${NC}\n"
                fi
                
                if [ $attempt -lt $max_retries ]; then
                    printf "${YELLOW}Retrying in 2 seconds...${NC}\n"
                    sleep 2
                    ((attempt++))
                else
                    local fail_msg=$(get_random_msg FAIL_MSGS)
                    printf "${RED}${BOLD}❌ ${fail_msg}${NC}\n"
                    printf "${DIM}All ${max_retries} attempts failed${NC}\n"
                    return 1
                fi
            fi
        done
    else
        printf "${GREEN}🎉 Open network${NC}\n"
        local connect_msg=$(get_random_msg CONNECTING_MSGS)
        printf "${YELLOW}${connect_msg}${NC}\n"
        
        # Delete any existing connection first
        nmcli connection delete "$ssid" 2>/dev/null
        
        connect_output=$(nmcli device wifi connect "$ssid" 2>&1)
        connect_result=$?
        
        sleep 2
        
        if [ $connect_result -eq 0 ]; then
            local success_msg=$(get_random_msg SUCCESS_MSGS)
            printf "${GREEN}${BOLD}✅ ${success_msg}${NC}\n"
        else
            local fail_msg=$(get_random_msg FAIL_MSGS)
            printf "${RED}${BOLD}❌ ${fail_msg}${NC}\n"
            printf "${DIM}Error: $connect_output${NC}\n"
        fi
    fi
}

# Show current connection
show_current() {
    printf "\n${BOLD}${WHITE}📶 Connection Status${NC}\n"
    printf "${DIM}────────────────────────────────────────────${NC}\n"
    
    current=$(nmcli -t -f NAME connection show --active 2>/dev/null | head -n1)
    if [ -n "$current" ]; then
        printf "${GREEN}${BOLD}Connected: ${WHITE}$current${NC}\n"
        
        # Get detailed info
        ip=$(ip route get 8.8.8.8 2>/dev/null | grep -oP 'src \K\S+')
        gateway=$(ip route | grep default | grep -oP 'via \K\S+' | head -n1)
        
        if [ -n "$ip" ]; then
            printf "${BLUE}IP Address: ${BOLD}$ip${NC}\n"
        fi
        if [ -n "$gateway" ]; then
            printf "${BLUE}Gateway: ${BOLD}$gateway${NC}\n"
        fi
        
        # Test connection
        printf "${YELLOW}Testing internet...${NC}\n"
        if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
            printf "${GREEN}${BOLD}✅ Internet connected${NC}\n"
        else
            printf "${RED}${BOLD}❌ No internet access${NC}\n"
        fi
    else
        printf "${RED}${BOLD}Not connected${NC}\n"
        printf "${DIM}Select a network to connect${NC}\n"
    fi
}

# Disconnect function
disconnect_network() {
    current=$(nmcli -t -f NAME connection show --active 2>/dev/null | head -n1)
    if [ -n "$current" ]; then
        printf "${YELLOW}Disconnecting from ${BOLD}$current${NC}...\n"
        
        (nmcli connection down "$current" 2>/dev/null) &
        spinner $!
        
        if wait $!; then
            printf "${GREEN}${BOLD}✅ Disconnected${NC}\n"
        else
            printf "${RED}${BOLD}❌ Failed to disconnect${NC}\n"
        fi
    else
        printf "${RED}${BOLD}Not connected to any network${NC}\n"
    fi
}

# Main menu
main_menu() {
    while true; do
        clear_screen
        check_nm
        
        if ! scan_networks; then
            printf "\n${RED}Press Enter to try again or Ctrl+C to give up...${NC}\n"
            read
            continue
        fi
        
        printf "\n${BOLD}${WHITE}Commands${NC}\n"
        printf "${DIM}────────────────────────────────────────────${NC}\n"
        
        printf "${GREEN}${BOLD}[1-99]${NC} Connect to network by number\n"
        printf "${YELLOW}${BOLD}[r]${NC}    Refresh network list\n"
        printf "${CYAN}${BOLD}[s]${NC}    Show connection status\n"
        printf "${RED}${BOLD}[d]${NC}    Disconnect\n"
        printf "${PURPLE}${BOLD}[q]${NC}    Quit\n"
        
        printf "\n${BOLD}${WHITE}Choice: ${NC}"
        read -p "" choice
        
        case "$choice" in
            [0-9]*)
                if [ -n "${network_map[$choice]}" ]; then
                    connect_network "${network_map[$choice]}"
                    printf "\n${DIM}Press Enter to continue...${NC}\n"
                    read
                else
                    printf "${RED}${BOLD}Invalid selection${NC}\n"
                    sleep 1
                fi
                ;;
            r|R|refresh)
                printf "${CYAN}Refreshing...${NC}\n"
                sleep 1
                ;;
            s|S|status)
                show_current
                printf "\n${DIM}Press Enter to continue...${NC}\n"
                read
                ;;
            d|D|disconnect)
                disconnect_network
                printf "\n${DIM}Press Enter to continue...${NC}\n"
                read
                ;;
            q|Q|quit|exit)
                clear
                printf "${PURPLE}${BOLD}"
                echo ""
                echo "    Thanks for using WiFizl!"
                echo ""
                printf "${NC}"
                exit 0
                ;;
            *)
                printf "${RED}${BOLD}Invalid option${NC}\n"
                sleep 1
                ;;
        esac
    done
}

# Let the magic begin!
main_menu
