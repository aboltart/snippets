#!/bin/bash

###############################################################################
# Script using which can find and verify public key length on Linix and MAC OS
#
# Find and check keys under current and it child directories:
#    /key_checker.sh
#
# Find and check keys under passed directory and it child directories:
#    SEARCH_FROM=/home/foo/ /key_checker.sh
#
# Extra variables
#    MIN_KEY_SIZE   - can pass min key size. Default 2048
#    DEBUG          - run script in debug mode
#
###############################################################################

if [ -n "$DEBUG" ]; then
  set -x
fi

min_key_size=${MIN_KEY_SIZE:="2048"}
search_from=${SEARCH_FROM:=${PWD}}
# Make tempfile. Support Linux and OSX
tmp_file=$(mktemp 2>/dev/null || mktemp -t key)
number_regexp='^[0-9]+$'

echo "Min key size: $min_key_size"

echo "Finding all key files starting from $search_from can take some time..."
key_files=($(find $search_from -name "authorized_keys" -o -name "id_rsa.pub"))

for key_file in "${key_files[@]}"; do

  echo "Verify file: $key_file"

  # To make sure the last line is always read - whether newline-terminated or not
  while read line || [[ -n $line ]]; do

    echo $line > "$tmp_file"
    check=$(ssh-keygen -lf "$tmp_file")

    # Get keysize
    [[ $check =~ ^([^[:space:]]+)(.*) ]]
    key_size=${BASH_REMATCH[1]}
    rest_check_data=${BASH_REMATCH[2]}

    # Skip if not number
    if ! [[ $key_size =~ $number_regexp ]] ; then
      echo -e "  \e[33mSkip line. Seams is not a key\e[0m $line"
      continue
    fi

    # Get key parts
    [[ $line =~ ^([^[:space:]]+)[[:space:]]+([^[:space:]]+)?[[:space:]]+?([^[:space:]]+)? ]];
    key_type=${BASH_REMATCH[1]}
    key=${BASH_REMATCH[2]};
    key_comment=${BASH_REMATCH[3]}

    if [ "$key_size" -lt "$min_key_size" ]; then
      echo -e "  Key size: \e[31m$key_size\e[0m"
      echo "    $key_type"

      if [ -n $key_comment ]; then
        echo "    $key_comment"
      else
        echo "    $key"
      fi
    elif [ "$key_size" -gt "$min_key_size" ]; then
      echo -e "  Key size: \e[32m$key_size\e[0m"
    else
      echo "  Key size: $key_size"
    fi

  done < "$key_file"
done
echo "DONE!"
