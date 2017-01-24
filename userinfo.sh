#!/bin/bash
## User Info Script

# Declare our "dictionary" (associative array)
declare -A userInfo
while IFS=: read -r userName userDescRaw; do
  userDesc=$(echo -e "$userDescRaw")
  #echo "User: $userName - Desc: $userDesc"
  userInfo[$userName]="$userDesc"
done < <(lslogins -co USER,GECOS)

