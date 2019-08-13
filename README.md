# Sync 2 piholes together

This bash script syncs 2 piholes together, including the white & black lists. This allows redundancy of DNS
on the local network incase one of the pihole servers goes offline.

This syncs all files needed (blacklists, whitelists, adlists) to keep a second pihole in sync with the first.

# Credits
Credit to redditor /u/jvinch76  https://www.reddit.com/user/jvinch76 for creating the basis for this modification.
Original Source https://www.reddit.com/r/pihole/comments/9gw6hx/sync_two_piholes_bash_script/

Then this was updated reddit user /u/LandlordTiberius, source: https://pastebin.com/KFzg7Uhi
Reddit link https://www.reddit.com/r/pihole/comments/9hi5ls/dual_pihole_sync_20/

Then, this was edited by Mitch Schwenk @ https://Yombo.Net and created this git repo.

There's no license information found for any previous versions, so this is being released
what should be the most liberal open source license: MIT license.

# Improvements since
* Restart the local pihole if change is detected.
* Add some additional checks before restarting pihole. Simple whitelist timestamp change doesn't count!
* Add pretty status updates.
* Don't show installation directions when the script runs.
* Remove running this script in debug.

# Recommended adlists.list
An included adlists.lists.recommended file is provided to get new users up and running quickly.
On a scale of 0 (conservative) to 10 (agressive), I (Mitch) would put it around a 3.5. This list
should be mostly "set it and forget it".

As of August 2019, this list blocks around 1,051,000 domains. Many other lists can block up to
3 million domains, but requires someone to be around to constantly add domains to the whitelist when
users run into trouble.

To use this list, simply replace the file /etc/pihole/adlists.list with this one.

# Installation
## Primary pihole
1. Login to pihole
1. Download file:
   * type "wget "
1. edit the script: type "pico piholesync.sh"
1. edit PIHOLE2 and HAUSER to match your SECONDARY pihole settings
1. save and exit
1. type "chmod +x ~/piholesync.sh" to make file executable
1. type "ssh-keygen"
1. type "ssh-copy-id root@192.168.1.3" <- type the same HAUSER and IP as PIHOLE2, this IP is specific to your network, 192.168.1.3 is an example only
   1. You may have to edit /etc/ssh/sshd_config on the second pihole to comment out: PermitRootLogin prohibit-password
   1. Besure to uncomment out this line once you are done.
1. type "yes" - YOU MUST TYPE "yes", not "y"
1. type the password of your secondary pihole
1. type "crontab -e"
1. scroll to the bottom of the editor, and on a new blank line,
1. add line "*/5 * * * * /bin/bash /root/piholesync.sh"
   1. This just syncs everything.
   1. Do not include quotes
   1. This will run rsync every 5 minutes, edit per your preferences\tolerence
   1. See https://crontab.guru/every-5-minutes for help
1. add line "17 2 */2 * * /bin/bash /root/piholesync.sh full"
   1. This downloads helpful whitelists and merges it into the current whitelist, then syncs everything.
   1. Change the default times. The first number should be 0-59 and the second number should be 0-23.
   1. Do not include quotes
   1. This will run rsync every 5 minutes, edit per your preferences\tolerence
   1. See https://crontab.guru/every-5-minutes for help

1. add line "*/5 * * * * /bin/bash /root/piholesync.sh" <- this will run rsync every 5 minutes, edit per your preferences\tolerence, see https://crontab.guru/every-5-minutes for help
1. save and exit

## Remote pihole
1  type "cd ~/.ssh"
1. type "eval `ssh-agent`" <- this step may not be needed, depending upon what is running on your primary pihole
1. type "ssh-add id_rsa.pub"
1. type "scp id_rsa.pub root@192.168.1.3:~/.ssh/"
1. login to secondary pihole (PIHOLE2) by typing "ssh root@192.168.1.3"
1. type "cd ~/.ssh"
1. type "cat id_rsa.pub >> authorized_keys"

Since pihole requests gravity to run when there's changes, no need to duplicate the efforts.
1. type "pico /etc/cron.d/pihole"
1. Comment out the line with these contents:
   *. PATH="$PATH:/usr/local/bin/" pihole updateGravity >/var/log/pihole_updateGravity.log || cat /var/log/pihole_updateGravity.log

## References
See https://www.dotkam.com/2009/03/10/run-commands-remotely-via-ssh-with-no-password/
for further information on running ssh commands remotely without a password.

#  Command line arguments
To download helpful lists of whitelist domains, use the "full" command line argument:
./piholesync.sh full

# Runtime details.
This script performs the following actions:
* Syncs these files: black.list blacklist.txt regex.list whitelist.txt lan.list
  * If any of these files have changed, the local and remove FTL service will be restarted on local and remote piholes.
* Syncs the adlists.list
  * If this file changes, then gravity willbe updated with "pihole -g" on the remote pihole only.


