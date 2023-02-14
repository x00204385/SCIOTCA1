#!/bin/bash
#
#!/bin/bash
echo "This script can make any of the files in this directory private."
echo "Enter the number of the file you want to protect:"
PS3="Your choice: "
QUIT="QUIT THIS PROGRAM - I feel safe now."
touch "$QUIT"
select FILENAME in *; do
    echo $FILENAME chosen
    case $FILENAME in
    "$QUIT")
        break
        ;;
    esac
done
rm "$QUIT"
