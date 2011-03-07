#!/bin/sh
# inserts $3 in the $1st line of the file $2
sed -i.bak -e "$1i\\
$3" $2
