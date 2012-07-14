#
# Regular cron jobs for the puppet-git-receiver package
#
0 4	* * *	root	[ -x /usr/bin/puppet-git-receiver_maintenance ] && /usr/bin/puppet-git-receiver_maintenance
