#!/bin/bash

crontab -l -u root 2>/dev/null; echo "* * * * * /path/to/new/cron" | less
( crontab -l -u root 2>/dev/null; echo "* * * * * /path/to/new/cron"; ) | less
{ crontab -l -u root 2>/dev/null; echo "* * * * * /path/to/new/cron"; } | less
