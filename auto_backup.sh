#!/bin/bash
profile[0]='root' #DUPLY PROFILE NAME
profile[1]='...'


TODAY=`date '+%d.%m'`
rm /root/auto_backup_logs/log_*

echo "Running Backups.." > /root/auto_backup_logs/auto_backup.log
echo "STARTTIME: " `date '+%d.%m.%y %H:%M:%S'` >> /root/auto_backup_logs/auto_backup.log
echo "------------------------------- - - - -" >> /root/auto_backup_logs/auto_backup.log

for i in "${profile[@]}" 
	do
	echo "" >> /root/auto_backup_logs/auto_backup.log
	echo "STARTING Backup for Profile $i" >> /root/auto_backup_logs/auto_backup.log
        time=`{ time duply $i backup >> /root/auto_backup_logs/log_${i}.log; } 2>&1 | awk '/real/ { print $2 }'`
	grep -q "Finished state OK" /root/auto_backup_logs/log_${i}.log
        if [ $? -ne 0 ]; then
                echo "  FAIL: Check /root/auto_backup_logs/fail/log_${i}_${TODAY}.log" >> /root/auto_backup_logs/auto_backup.log
		mv /root/auto_backup_logs/log_${i}.log /root/auto_backup_logs/fail/log_${i}_${TODAY}.log
	else
		echo "  Done: $time" >> /root/auto_backup_logs/auto_backup.log
        fi
done
echo "------------------------------- - - - -" >> /root/auto_backup_logs/auto_backup.log
echo "" >> /root/auto_backup_logs/auto_backup.log
echo "STOPTIME: " `date '+%d.%m.%y %H:%M:%S'` >> /root/auto_backup_logs/auto_backup.log
cat /root/auto_backup_logs/auto_backup.log | mail -r from@someserver.com -s "Daily Backup-Log $TODAY." to@someserver.com
