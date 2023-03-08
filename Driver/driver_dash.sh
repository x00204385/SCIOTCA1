#!/bin/bash
#
# driver_dash.sh
#
# DESCRIPION
# Simple dashboard script that loops continuously and displays status. This consists of a header, info on carriage brake settings and a footer.
# The driver.log file is also displayed. This is done using a simple cat
#
log_file="./driver.log"
if [ -f $log_file ]; then
    echo Found old log file. Deleting.
    rm -f $log_file
fi
while true; do
    clear
    cat dash-header dash-carriage[0-9] dash-footer
    if [ -f $log_file ]; then
        cat $log_file
    fi
    sleep 5
done
