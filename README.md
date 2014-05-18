LVM Backup with DUPLY
=====

Features
==
- automatic LVM Snap create, mount, backup, destroy
- Automatic Backup with Cronjob
- Logs for each duply profile, saved if failure
- E-Mail Notifications

Setup
==
1. Setup duply profiles to /root/duply. Set up, that First day Full Backup and all other 6 days incremental.
2. add for each pre and post script. NOTE: the commandline of the automatic script: LV-NAME root-partition-ID additional-partition-id=and name. Which means: you have to specify the number of the rootfs if mounted, and if you want for a additional Partition the number and name in format 5=home. Has do be the same for pre and post script.
3. Test it with duply root status
4. Setup the auto_backup.sh Script for your profiles, edit the E-Mail at the buttom. Put a Cron each day.
