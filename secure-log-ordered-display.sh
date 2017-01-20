#!/bin/bash

##########################################################
# Finds the last login times (within reason) of SFTP users
#

SearchDir="$HOME/logtemp/short" #"/var/log"  # this is where we look for the file(s)
fNamePattern='secure*' # Filenames to look for
searchPattern='session opened for user [pP][kK][0-9]' # Search for lines containing this
excludePattern="We Aren't Using This But Don't Leave It Empty" # What to exclude

LogTempFile=$(mktemp)
FileList=$(find "$SearchDir" -type f -name "$fNamePattern" -printf '%TY-%Tm-%Td %p\n'|sort)


echo $FileList

# Iterate through the above list
while read -r line; do
  FileName=$(echo "$line"|cut -f2 -d' ')
  FileYear=$(echo "$line"|cut -f1 -d'-')
  FileMonth=$(echo "$line"|cut -f2 -d'-')
  echo "The file YEAR is $FileYear and the FILE is $FileName in month $FileMonth Line is: ${line}"

   #grep -E "$searchPattern" "$FileName"| grep -vE "$excludePattern")
  while IFS= read -r logline; do
    grep -q "$searchPattern" <<< "$logline"
    if [ $? -eq 0 ]; then
      MatchLine="$logline"
#      echo "MATCH: $logline"
      # Clean the log line to enable reading - only get the "text" month, day, time, and the login user
      cleanLogLine=$(echo "$logline"| cut -d' ' -f1,2,3,11)
      read LineMonTxt LineDay LineTime LineUser <<< "$logline" # Extract the date/time from the line
      LineMon=$(date -d "$LineMonTxt 01" "+%m") # Convert the three letter month to a leading-zero number

#      LineMonth=$(echo "$logline"|cut -d' ' -f1)
      # If the file is 'early' in the year, and the log line 'Late' month, we may need to fix the year info by subtracting
      if [[ ($FileMonth -lt 5) && ($LineMon -gt 7) ]]; then   # one from Year (as the file in Jan may have lines from Dec, etc)
         LineYear=$(($FileYear - 1))
      else
         LineYear=$FileYear
      fi
      formattedLogLine="${LineYear}-${LineMon}-${LineDay} $LineTime $LineUser"

       # LogLine looks like: Jan 20 11:48:59 storage01 sshd[1891]: pam_unix(sshd:session): session opened for user pk11328 by (uid=0)

#      formattedLogLine=$logline
#      echo "$formattedLogLine"
      echo "$formattedLogLine" >> "$LogTempFile"
#    else
#       echo "X: $logline"
    fi
  done < "$FileName"


done <<< "$FileList"
#exit

UserlistTempFile=$(mktemp)
lslogins -o USER|grep -E '^pk[0-9]' > "$UserlistTempFile"
Column=2 #This is the position in the log that contains the actual username - space delimited
awk 'FNR==NR{ user[$1]; next } $'$Column' in user { lastline[$'$Column'] = $0 } END { for (u in lastline) print u": "lastline[u]}' "$UserlistTempFile" "$LogTempFile"





rm "$UserlistTempFile" "$LogTempFile"

if [ 0 -eq 3 ]; then
 echo "
2017-01-17 /var/log/secure
2016-12-26 /var/log/secure-20161226
2017-01-16 /var/log/secure-20170116"
fi

#find /var/log -name 'secure*' -type f -printf '%T@ %p\0'|
#sort -zk 1nr |sed -z 's/^[^ ]* //'|
#grep -E "\0" -a
##xargs cat

# the FIND output is like this. excuse the nonsense


# ind /var/log -type f -name 'secure*' -printf '%T@ %p\n'|sort -n|cut -d' ' -f2
