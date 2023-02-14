#!/bin/bash
#
# driver.sh
# DESCRIPION
# This script implements the functions of the driver system for the bash MQTT train intercomm system
# The script subscribes to a number of MQTT topics and responds if a message is received. Messages received are logged to a
# log file which is truncated to a configureable maximum number of lines.
#
# The main messages which are processed:
#
# 1. Brake activiation messages from carriages.
# The brakes set to ON when a message is received. After a configurable period the brakes are restored to OFF. MQTT are posted when
# messages brakes are turned OFF or ON
#
# 2. Messages from carriagse
# The messages are logged in the log file
#
# Menu setup
menu_options=("Message to carriages")
menu_title="Driver menu "
menu_prompt="Menu choice: "

brake_duration=10
log_file_maxlen=20
mqtt_host=localhost
driver_message_prompt="Enter message for carriages: "

temp_file=/tmp/$$temp.txt

log_file="./driver.log"
log_message() {
    echo $(date +"%H:%M:%S") $* >>$log_file
    # Crop log file to 20 lines max
    tail -n $log_file_maxlen $log_file >$temp_file
    mv $temp_file $log_file
}

#
# Usage: brake_on carriage
# Turn brakes ON in carriage and log a message
#
brake_on() {
    log_message "Brakes ON in carriage $1"
    mosquitto_pub -h $mqtt_host -t "/carriage/$1/brake" -m "ON"
    echo "carriage$1: ON" >dash-carriage$1
}

#
# Usage: brake_off carriage
# Turn brakes OFF in carriage and log a message
#
brake_off() {
    log_message "Brakes OFF in carriage $1"
    mosquitto_pub -h $mqtt_host -t "/carriage/$1/brake" -m "OFF"
    echo "carriage$1: OFF" >dash-carriage$1
}

#
# Usage: apply_brake carriage
# Turn the brake ON in carriage, wait the configured number of seconds and turn the brake OFF again
#
apply_brake() {
    brake_on $1
    sleep $brake_duration
    brake_off $1
}

send_driver_message() {
    read -p "$driver_message_prompt" driver_message
    mosquitto_pub -h $mqtt_host -t "/driver/broadcast" -m "$driver_message"
}

# Ensure brakes are off
brake_off 1
brake_off 2

# Listen for messages from carriages (in the background)

mosquitto_sub -v -h $mqtt_host -t "/carriage/+/message" | while read line; do
    carriage_number=$(echo $line | cut -f 3 -d'/')
    log_message "Message received from carriage $carriage_number" $line
done &

# Subscribe to message feed for brake activations
mosquitto_sub -v -h $mqtt_host -t "/carriage/+/apply_brake" | while read line; do
    log_message $line
    carriage_number=$(echo $line | cut -f 3 -d'/')
    apply_brake $carriage_number
done &

# Kill background processes on exit
trap "trap - SIGTERM && kill -- -$$" SIGINT SIGTERM EXIT
#

# Display a menu of available options and ask the user to choose
#
PS3=$menu_prompt
echo $menu_title
select menu_item in "${menu_options[@]}" "Quit"; do
    case $menu_item in
    "Message to carriages")
        send_driver_message
        ;;
    "Quit")
        echo Goodbye
        break
        ;;
    *)
        echo "Invalid option. Please choose a valid option"
        ;;
    esac
done
