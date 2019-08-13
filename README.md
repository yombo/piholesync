# Sync 2 piholes together
This bash script syncs 2 piholes together, including the white & black lists.
This allows redundancy of DNS on the local network incase one of the pihole
servers goes offline.

This syncs all files needed (blacklists, whitelists, adlists) to keep a
second pihole in sync with the first.

# Runtime details.
This script performs the following actions:
* Syncs these files: black.list blacklist.txt regex.list whitelist.txt lan.list
  * If any of these files have changed, the local and remote FTL service will
   be restarted.
* Syncs the adlists.list
  * If this file changes, then gravity will be updated with "pihole updateGravity" on the
   remote pihole only.

# Improvements since
* Restart the local pihole if change is detected.
* Add some additional checks before restarting pihole. Simple whitelist
 timestamp change doesn't count!
* Add pretty status updates.
* Don't show installation directions when the script runs.
* Remove running this script in debug.

# Recommended adlists.list
An included adlists.lists.recommended file is provided to get new users up
and running quickly. On a scale of 0 (conservative) to 10 (aggressive), I
(Mitch) would put it around a 3.5. This list should be mostly "set it and
forget it".

As of August 2019, this list blocks around 1,051,000 domains. Many other lists
can block up to 3 million domains, but requires someone to be around to
constantly add domains to the whitelist when users run into trouble.

To use this list, simply replace the file /etc/pihole/adlists.list with this
one.

# Recommendations
## IP addressing
Most routers use 192.168.0.1 or 192.168.1.1 as the gateway. Use your
gateway's DHCP server function to assign a static IP address to each
Raspberry pi. To remember the DNS servers easier, use .2 and .3 as the
last number in the IP address. Refer to your router manual or Google on
how to complete this.

_Expert tip_: Change the router's default DHCP IP address range to
something other than 192.168.1.x, for example anything in 10.x.x.x
range will work great. To help remember IP address, take the first 4
numbers of your home address and simply use that. If you home address
number is 7503 use: 10.75.3.x

## Passwords
The default Raspbery PI password is known to everyone. Change the
password! To do that, login to the Raspberry PI and type passwd.
This will change the use 'pi' password.  

# Installation
## Primary pihole
1. Login to pihole
1. Download file:
   * type "wget https://raw.githubusercontent.com/yombo/piholesync/master/piholesync.sh"
1. edit the script: type "pico piholesync.sh"
1. edit PIHOLE2 and HAUSER to match your SECONDARY pihole instance
1. save and exit
1. type "chmod +x piholesync.sh" to make file executable
1. type "ssh-keygen"
1. type "ssh-copy-id root@192.168.1.3"
   * Update the username and IP address to match HAUSER and PIHOLE2.
   * You may have to edit /etc/ssh/sshd_config on the **secondary** pihole
    to comment out: PermitRootLogin prohibit-password
   * Be sure to uncomment out this line once you are done with ssh setup.
1. type "yes" - YOU MUST TYPE "yes", not "y"
1. type the password of your secondary pihole

**Add 2 cron jobs**

Their are 2 cronjobs that are used to sync the piholes together. The first one
syncs everything, but does not download external whitelists. The second,
optional, cron job downloads external whitelists and merges it with yours.

Whitelist can be edited through the primary pihole web interface and will be
synced to the secondary.

Syncing without full download every 5 minutes is fine. The secondary pihole
will only be restarted if a change has been detected. This allows updates
to whitelists and blacklists to change effect within 5 minutes.

1. type "crontab -e"
1. scroll to the bottom of the editor, and on a new blank line,
1. add line "*/5 * * * * /bin/bash /root/piholesync.sh > /dev/null"
   * **Do not include quotes.**
   * This just syncs everything, but doesn't download external whitelists.
   * This will run rsync every 5 minutes, edit per your preferences\tolerence
   * See https://crontab.guru/every-5-minutes for help
1. add line "17 2 3 * * /bin/bash /root/piholesync.sh full > /dev/null"
   * **Do not include quotes.**
   * Change the default times.
     * The first number should be between 0-59. **Do not pick a number
      divisible by 5!**
     * Second number should be between 0-23
     * Third number should be between 0-6
   * This downloads external helpful whitelists and merges it into the current
    whitelist, then syncs everything to the secondary pihole.
   * This should only be ran once a week or so.
1. save and exit

## Remote secondary pihole
1  type "cd ~/.ssh"
1. type "eval `ssh-agent`" <- this step may not be needed, depending upon what
 is running on your primary pihole
1. type "ssh-add id_rsa.pub"
1. type "scp id_rsa.pub root@192.168.1.3:~/.ssh/"
1. login to secondary pihole (PIHOLE2) by typing "ssh root@192.168.1.3"
1. type "cd ~/.ssh"
1. type "cat id_rsa.pub >> authorized_keys"

# Testing
After you complete the installation, you can simply run the pihole sync tool
to verify everything is working.

1. ~/piholesync.sh
1. Make a change on the primary pihole. Add an item to the black or white lists,
 add a comment to the adlists, whatever you want.
1. ~/piholesync.sh
1. Validate the change appears on the secondary pihole.

## References
See https://www.dotkam.com/2009/03/10/run-commands-remotely-via-ssh-with-no-password/
for further information on running ssh commands remotely without a password.

#  Command line arguments
To download helpful lists of whitelist domains, use the "full" command line
argument:
./piholesync.sh full
This shouldn't be regularly used, only once a week or so is suggested.

# Credits
Credit to redditor
[Reddit /u/jvinch76](https://www.reddit.com/user/jvinch76 "/u/jvinch76") for
creating the basis for this modification. Original source
https://www.reddit.com/r/pihole/comments/9gw6hx/sync_two_piholes_bash_script/

Then this was updated reddit user 
[Reddit /u/LandlordTiberius](https://www.reddit.com/user/LandlordTiberius "/u/LandlordTiberius"),
source at: https://pastebin.com/KFzg7Uhi
Details about this version at:
https://www.reddit.com/r/pihole/comments/9hi5ls/dual_pihole_sync_20/

This script was then edit by by Mitch Schwenk @ https://Yombo.Net
and created this git repo.

There's no license information found for any previous versions, so this is
being released with what should be the most liberal open source license:
MIT license.
