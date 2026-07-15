#!/bin/bash

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
NC='\033[0m'

while true; do
    clear
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "👑 ${GREEN}<b>SSH WEBSOCKET MANAGEMENT PANEL</b>${NC} 👑"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "1. Create SSH Account"
    echo -e "2. Show All SSH Accounts"
    echo -e "3. Delete SSH Account"
    echo -e "4. Change Banner"
    echo -e "5. Exit"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    read -p "Select an option [1-5]: " option

    case $option in
        1)
            clear
            echo -e "${GREEN}== CREATE NEW SSH ACCOUNT ==${NC}"
            read -p "Enter Username: " username
            if id "$username" &>/dev/null; then
                echo -e "${RED}Error: User already exists!${NC}"
            else
                read -p "Enter Password: " password
                read -p "Enter Validity Days (e.g., 30): " days
                
                exp_date=$(date -d "+$days days" +%Y-%m-%d)
                useradd -M -e "$exp_date" -s /bin/false "$username"
                echo "$username:$password" | chpasswd
                
                clear
                echo -e "${GREEN}✔ Account Created Successfully!${NC}"
                echo -e "👤 Username: $username"
                echo -e "🔑 Password: $password"
                echo -e "📅 Expire Date: $exp_date ($days Days)"
            fi
            read -p "Press Enter to return..." temp
            ;;
        2)
            clear
            echo -e "${PURPLE}== ALL REGISTERED SSH ACCOUNTS ==${NC}"
            echo -e "--------------------------------------------------------"
            printf "%-15s %-15s %-15s\n" "Username" "UID" "Expiry Date"
            echo -e "--------------------------------------------------------"
            awk -F: '$7 ~ /\/false/ {print $1}' /etc/passwd | while read user; do
                uid=$(id -u "$user")
                expire_raw=$(chage -l "$user" | grep "Account expires" | cut -d: -f2)
                printf "%-15s %-15s %-15s\n" "$user" "$uid" "$expire_raw"
            done
            echo -e "--------------------------------------------------------"
            read -p "Press Enter to return..." temp
            ;;
        3)
            clear
            echo -e "${RED}== DELETE SSH ACCOUNT ==${NC}"
            read -p "Enter Username to delete: " username
            if id "$username" &>/dev/null; then
                userdel -r "$username" 2>/dev/null
                echo -e "${GREEN}✔ User '$username' deleted successfully.${NC}"
            else
                echo -e "${RED}Error: User does not exist!${NC}"
            fi
            read -p "Press Enter to return..." temp
            ;;
        4)
            clear
            echo -e "${YELLOW}== CHANGE DROPBEAR BANNER ==${NC}"
            echo "Enter your new banner below. You can use HTML tags (e.g., <font color='red'>Text</font>)."
            echo "Press Ctrl+D on a new blank line when you are finished writing:"
            echo -e "--------------------------------------------------------"
            
            # Temporary file to store banner input
            cat > /tmp/new_banner
            
            if [ -s /tmp/new_banner ]; then
                mv /tmp/new_banner /etc/issue.net
                systemctl restart dropbear
                echo -e "\n${GREEN}✔ Banner updated successfully and Dropbear restarted!${NC}"
            else
                echo -e "\n${RED}Error: Banner cannot be empty!${NC}"
            fi
            read -p "Press Enter to return..." temp
            ;;
        5)
            echo -e "${GREEN}Exiting... Goodbye!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid Option!${NC}"
            sleep 1
            ;;
    esac
done

