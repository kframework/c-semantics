#!/bin/sh
# inserts $2 in the last of file $1
set -e
sed -i.bak -e "\$a\\
$2" $1
