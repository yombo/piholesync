#!/bin/bash

#VARS
FILES=(black.list blacklist.txt regex.list whitelist.txt lan.list) #list of files you want to sync
PIHOLEDIR=/etc/pihole #working dir of PiHole
PIHOLE2=192.168.1.3 #IP of 2nd PiHole
HAUSER=root #user of second pihole
TICK="[\e[32m ✔ \e[0m]"
UNTICK="[\e[32m   \e[0m]"
SLEEPTIME=7

echo -e " ${TICK} \e[32m PiHole sync starting... \e[0m"

if [ "$1" == "full" ]; then
  echo -ne " ${UNTICK} \e[32m Adding remote domains to whitelist. \e[0m\033[0K\r"
  # Comment one or more out if you do not wish to use any of these.
  curl -sS https://raw.githubusercontent.com/anudeepND/whitelist/master/domains/whitelist.txt | sudo tee -a "${PIHOLEDIR}"/whitelist.txt >/dev/null
  curl -sS https://raw.githubusercontent.com/Ultimate-Hosts-Blacklist/DShield.org-Suspicious-Domain-List/master/whitelisted.list | sudo tee -a "${PIHOLEDIR}"/whitelist.txt >/dev/null
  curl -sS https://raw.githubusercontent.com/Ultimate-Hosts-Blacklist/whitelist/master/domains.list | sudo tee -a "${PIHOLEDIR}"/whitelist.txt >/dev/null
  curl -sS https://raw.githubusercontent.com/anudeepND/whitelist/master/domains/optional-list.txt | sudo tee -a "${PIHOLEDIR}"/whitelist.txt >/dev/null
  echo -e " ${TICK} \e[32m Adding remote domains to whitelist. \e[0m"
  echo -ne " ${UNTICK} \e[32m Removing duplicate whitelist entries. \e[0m\033[0K\r"
  mv "${PIHOLEDIR}"/whitelist.txt "${PIHOLEDIR}"/whitelist.txt.old && cat "${PIHOLEDIR}"/whitelist.txt.old | sort | uniq >> "${PIHOLEDIR}"/whitelist.txt
  echo -e " ${TICK} \e[32m Removing duplicate whitelist entries. \e[0m"
fi

echo -e " ${TICK} \e[32m Syncing files to peer PiHole. \e[0m"
#LOOP FOR FILE TRANSFER
RESTART=0 # flag determine if service restart is needed
for FILE in ${FILES[@]}
do
  if [[ -f $PIHOLEDIR/$FILE ]]; then
  RSYNC_COMMAND=$(rsync -a --out-format='%i' $PIHOLEDIR/$FILE $HAUSER@$PIHOLE2:$PIHOLEDIR)
    if [ "$RSYNC_COMMAND" != "<f..t......" ] && [ "$RSYNC_COMMAND" != "" ]; then
      # rsync copied changes
      RESTART=1 # restart flagged
      echo -e "\e[32m         - File change detected: $FILE \e[0m"
     # else 
       # no changes
     fi
  # else
    # file does not exist, skipping
  fi
done

FILE="adlists.list"
RSYNC_COMMAND=$(rsync -ai $PIHOLEDIR/$FILE $HAUSER@$PIHOLE2:$PIHOLEDIR)
if [[ -n "${RSYNC_COMMAND}" ]]; then
  # rsync copied changes, update GRAVITY
  ssh $HAUSER@$PIHOLE2 "sudo -S pihole updateGravity >/var/log/pihole_updateGravity.log || cat /var/log/pihole_updateGravity.log
# else
  # no changes
fi

if [ $RESTART == "1" ]; then
  # INSTALL FILES AND RESTART pihole
  echo -ne " ${UNTICK} \e[32m Restarting local PiHole. (Step 1 of 3) \e[0m\033[0K\r"
  sudo -S service pihole-FTL stop
  echo -ne " ${UNTICK} \e[32m Restarting local PiHole. (Step 2 of 3) \e[0m\033[0K\r"
  sudo -S pkill pihole-FTL
  echo -ne " ${UNTICK} \e[32m Restarting local PiHole. (Step 3 of 3) \e[0m\033[0K\r"
  sudo -S service pihole-FTL start
  echo -e " ${TICK} \e[32m Restarting local pihole...Done.               \e[0m"

  echo -ne " ${UNTICK} \e[32m Sleeping for $SLEEPTIME second for client health. Remaining: $SLEEPTIME \e[0m\033[0K\r"
  while [ $SLEEPTIME -gt 0 ]; do
     echo -ne " ${UNTICK} \e[32m Sleeping for $SLEEPTIME second for client health. Remaining: \e[0m$SLEEPTIME\033[0K\r"
     sleep 1
     : $((SLEEPTIME--))
  done
  echo -e " ${TICK} \e[32m Sleeping for $SLEEPTIME second for client health. Remaining: Done         \e[0m"

  echo -ne " ${UNTICK} \e[32m Restarting peer PiHole. (Step 1 of 3) \e[0m\033[0K\r"
  ssh $HAUSER@$PIHOLE2 "sudo -S service pihole-FTL stop"
  echo -ne " ${UNTICK} \e[32m Restarting peer PiHole. (Step 2 of 3) \e[0m\033[0K\r"
  ssh $HAUSER@$PIHOLE2 "sudo -S pkill pihole-FTL"
  echo -ne " ${UNTICK} \e[32m Restarting peer PiHole. (Step 3 of 3) \e[0m\033[0K\r"
  ssh $HAUSER@$PIHOLE2 "sudo -S service pihole-FTL start"
  echo -e " ${TICK} \e[32m Restarting peer PiHole...Done.              \e[0m"
fi

echo -e " ${TICK} \e[32m PiHole sync complete. \e[0m"

