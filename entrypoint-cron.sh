#!/bin/bash
set -e

# Update crontab file using whenever command
bundle exec whenever --update-crontab

# Follow the log file in the background
tail -f /var/log/cron.log &

# Then exec the container's main process (what's set as CMD in the Dockerfile).
exec "$@"
