#!/bin/sh

S="${1}"
STRING="${2}"

# Removes duplicate appearances of `S` from `STRING`.

# Count how many times S appears in STRING.
# Do so by converting spaces to newlines,
# and use `grep` to count those lines that contain S.
COUNT=$(echo "${STRING}" | perl -pe 's/ /\n/g' | grep --count "${S}")

[ ${COUNT} -gt 0 ] &&
  echo "$(echo "${STRING}" | perl -pe "s/${S}\s*//g") ${S}" || 
  echo "${STRING}"
