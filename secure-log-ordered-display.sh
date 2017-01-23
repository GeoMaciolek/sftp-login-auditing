#!/bin/bash

##########################################################
# Finds the last login times (within reason) of SFTP users
#

### "User" variables - set these as needed

SearchDir="$HOME/logtemp/full" #"/var/log"  # this is where we look for the file(s)
fNamePattern='secure*' # Filenames to look for
searchPattern='session opened for user [pP][kK][0-9]' # Search for lines containing this
excludePattern="We Aren't Using This But Don't Leave It Empty" # What to exclude
debugLogging=false # set to "true" or "false" without quotes.  Note that this line is EXECUTED by the if statements - be careful

#### Begin Script ####

LogTempFile=$(mktemp)
FileList=$(find "$SearchDir" -type f -name "$fNamePattern" -printf '%TY-%Tm-%Td %p\n'|sort)

if $debugLogging; then echo "File list: $FileList"; fi 

# Iterate through the above list
while read -r currentFile; do
  FileName=$(echo "$currentFile"|cut -f2 -d' ') # The line is formatted e.g. "2016-07 /var/log/secure-20160813"
  FileYear=$(echo "$currentFile"|cut -f1 -d'-') # So we extract these variables from the line content
  FileMonth=$(echo "$currentFile"|cut -f2 -d'-')
  if $debugLogging ; then echo "File Timestamp: ${FileYear}-${FileMonth} FileName: $FileName Line is: ${currentFile}"; fi

   #grep -E "$searchPattern" "$FileName"| grep -vE "$excludePattern")
  while IFS= read -r logline; do
    grep -q "$searchPattern" <<< "$logline"
    if [ $? -eq 0 ]; then
      MatchLine="$logline"
#      echo "MATCH: $logline"
      # Clean the log line to enable reading - only get the "text" month, day, time, and the login user
      cleanLogLine=$(echo "$logline"|tr -s ' '|cut -d' ' -f1,2,3,11) # the "tr -s" removes multiple concurrent spaces, e,g "Jan  1" which confuse "cut"
      read LineMonTxt rawLineDay LineTime LineUser <<< "$cleanLogLine" # Extract the date/time from the line
      LineDay=$(printf "%02d" $rawLineDay)
      LineMon=$(date -d "$LineMonTxt 01" "+%m") # Convert the three letter month to a leading-zero number

#      LineMonth=$(echo "$logline"|cut -d' ' -f1)
      # If the file is 'early' in the year, and the log line 'Late' month, we may need to fix the year info by subtracting
      if [[ ($FileMonth -lt 5) && ($LineMon -gt 7) ]]; then   # one from Year (as the file in Jan may have lines from Dec, etc)
         if $debugLogging; then echo "FIXING THIS ONE: ($currentFile): $logline"; fi
         LineYear=$(($FileYear - 1))
      else
         LineYear=$FileYear
      fi
      formattedLogLine="${LineYear}-${LineMon}-${LineDay} $LineTime $LineUser"

       # LogLine looks like: Jan 20 11:48:59 storage01 sshd[1891]: pam_unix(sshd:session): session opened for user pk11328 by (uid=0)

#      formattedLogLine=$logline
#      echo "$formattedLogLine XX $logline"
      echo "$formattedLogLine" >> "$LogTempFile"
#    else
#       echo "X: $logline"
    fi
  done < "$FileName"


done <<< "$FileList"
#exit

UserlistTempFile=$(mktemp)
lslogins -o USER|grep -E '^pk[0-9]' |sort -V > "$UserlistTempFile" # "sort -V" is 'version' sorting; works for fidning pk56 smaller than pk103
Column=3 #This is the position in the log that contains the actual username - space delimited
#awk 'FNR==NR{ user[$1]; next } $'$Column' in user { lastline[$'$Column'] = $0 } END { for (u in lastline) print u": "lastline[u]}' "$UserlistTempFile" "$LogTempFile"
LastLoginsUnsorted=$(awk 'FNR==NR{ user[$1]; next } $'$Column' in user { lastline[$'$Column'] = $0 } END { for (u in lastline) print lastline[u]}' "$UserlistTempFile" "$LogTempFile")
LastLoginsDateSorted=$(echo "$LastLoginsUnsorted" | sort --stable --key=1,2) # Sort by the timestamp
LastLoginsUsernameSorted=$(echo "$LastLoginsUnsorted" | sort --key=3 -V) # Sort by the username (see above for -V expl.)

echo "$LastLoginsDateSorted" > datesorted.txt
echo "$LastLoginsUsernameSorted" > usersorted.txt

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
