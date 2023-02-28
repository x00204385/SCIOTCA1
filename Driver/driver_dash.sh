#!/bin/bash
#
# driver_dash.sh
#
# DESCRIPION
# Simple dashboard script that loops continuously and displays status. This consists of a header, info on carriage brake settings and a footer.
# The driver.log file is also displayed. This is done using a simple cat
#
while true; do
    clear
    cat dash-header dash-carriage[0-9] dash-footer
    if [ -f driver.log ]; then
        cat driver.log
    fi
    sleep 5
done
