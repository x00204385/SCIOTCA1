#!/bin/bash
#
brake_duration=10
log_file_maxlen=20
temp_file=/tmp/$$temp.txt

log_file="./driver.log"
log_message() {
    echo $(date +"%H:%M:%S") $* >>$log_file
    # Crop log file to 20 lines max
    tail -n $log_file_maxlen $log_file >$temp_file
    mv $temp_file $log_file
}

brake_on() {
    log_message "Brakes ON in carriage $1"
    mosquitto_pub -h localhost -t "/carriage/$1/brake" -m "ON"
    echo "carriage$1: ON" >dash-carriage$1
}

brake_off() {
    log_message "Brakes OFF in carriage $1"
    mosquitto_pub -h localhost -t "/carriage/$1/brake" -m "OFF"
    echo "carriage$1: OFF" >dash-carriage$1
}

apply_brake() {
    brake_on $1
    sleep $brake_duration
    brake_off $1
}

# Ensure brakes are off
brake_off 1
brake_off 2

# Listen for messages from carriages in the background

mosquitto_sub -v -h localhost -t "/carriage/+/message" | while read line; do
    carriage_number=$(echo $line | cut -f 3 -d'/')
    log_message "Message received from carriage $carriage_number" $line
done &

# Subscribe to message feed for brake activations
mosquitto_sub -v -h localhost -t "/carriage/+/apply_brake" | while read line; do
    log_message $line
    carriage_number=$(echo $line | cut -f 3 -d'/')
    echo Carriage number is $carriage_number
    apply_brake $carriage_number
done
