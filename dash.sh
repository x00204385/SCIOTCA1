while true; do
    clear
    cat dash-header
    cat dash-carriage[0-9]
    cat dash-footer
    if [ -f driver.log ]; then
        tail -3 driver.log
    fi
    sleep 5
done
