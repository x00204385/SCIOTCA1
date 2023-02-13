#!/bin/bash
#
carriage_number=${1:-"1"}
menu_options=("Apply brake" "Send message")
menu_title="Select an option "
menu_prompt="Menu choice: "
driver_message_prompt="Enter message for driver: "

send_message() {
    read -p "$driver_message_prompt" driver_message
    mosquitto_pub -h localhost -t "/carriage/$carriage_number/message" -m "$driver_message"
}

apply_brake() {
    echo "activating brake"
    mosquitto_pub -h localhost -t "/carriage/$carriage_number/apply_brake" -m "activate"
}

echo "Carriage number is " $carriage_number

PS3=$menu_prompt
echo $menu_title
select menu_item in "${menu_options[@]}" "Quit"; do
    case $menu_item in
    "Apply brake")
        apply_brake
        ;;
    "Send message")
        send_message
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
