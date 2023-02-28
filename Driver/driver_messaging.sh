#!/bin/bash
#
# driver_messaging.sh
# USAGE
# driver_messaging [-h mqtt_host] [-l log_file_maxlen]
#
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
# Setup some variables
#
mqtt_host="${MQTT_HOST:-localhost}" # Set mqtt_host based on environment variable. Default to localhost
log_file_maxlen=20
#
# Process command line options
#
while getopts "h:l:" OPTION; do
    case $OPTION in
    l)
        log_file_maxlen=$OPTARG
        ;;
    h)
        mqtt_host=$OPTARG
        ;;
    *)
        echo "Usage: $(basename $0) [-h mqtt_host] [-l log_file_maxlen]"
        exit 1
        ;;
    esac
done
#
echo mqtt_host is $mqtt_host
echo log_file_maxlen is $log_file_maxlen
#
#
driver_message_prompt="Enter message for carriages: "
#
# Menu setup
menu_options=("Broadcast to carriages" "Direct message to carriage")
menu_title="Driver menu "
menu_prompt="Menu choice: "

temp_file=/tmp/$$temp.txt

log_file="./driver.log"
log_message() {
    echo $(date +"%H:%M:%S") $* >>$log_file
    # Crop log file to 20 lines max
    tail -n $log_file_maxlen $log_file >$temp_file
    mv $temp_file $log_file
}

#
# Usage: broadcast_message_to_carriages message
# Send a message to all carriages
#
broadcast_message_to_carriages() {
    read -p "$driver_message_prompt" driver_message
    mosquitto_pub -h $mqtt_host -t "/driver/message/broadcast" -m "$driver_message"
    log_message "Broadcast /driver/message/broadcast  " $driver_message " to all carriages"
}

#
# Usage: send_message_to_carriage
# Send a message to specific carriage. Prompt user for detail.
#
send_message_to_carriage() {
    select num in "1" "2" "Quit"; do
        case $num in
        "1" | "2")
            break
            ;;
        *)
            echo "Please select a valid option"
            ;;
        esac
    done
    # Read user input
    read -p "$driver_message_prompt" driver_message
    #
    # Post the message by publishing to MQTT topic
    #
    mosquitto_pub -h $mqtt_host -t "/driver/messsage/$num" -m "$driver_message"
}

# Listen for messages from carriages (in the background)

mosquitto_sub -v -h $mqtt_host -t "/carriage/+/message" | while read line; do
    carriage_number=$(echo $line | cut -f 3 -d'/')
    echo "Message received from carriage $carriage_number" $line
    log_message "Message received from carriage $carriage_number" $line
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
    "Broadcast to carriages")
        broadcast_message_to_carriages
        ;;
    "Direct message to carriage")
        send_message_to_carriage
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
