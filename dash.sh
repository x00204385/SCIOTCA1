while true; do
    clear
    cat dash-header dash-carriage[0-9] dash-footer
    if [ -f driver.log ]; then
        cat driver.log
    fi
    sleep 5
done
