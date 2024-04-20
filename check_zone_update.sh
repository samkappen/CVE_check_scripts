#!/bin/bash

if [ $# -ne 2 ]; then
  echo "Usage: $0 <CentO Risk analysis sheet> <Zone file(contents of https://support.mvista.com/centosX/centos-x.y/x86_64/os/Packages/ )>"
  exit 1
fi


# Read the contents of Risk sheet a variable
contents=$(cat $1)

# Use grep to find the line containing the word "version" and extract the string after it
version=$(echo "$contents" | grep -oP 'Version[^"]*')

# Print the extracted version string
echo "$version" | awk '{print $3}' > ver_file.txt

while read line; do
  if grep -q "$line" $2; then
    echo "$line is present"
  else
    echo -e  "\033[31m $line is not present \033[0m"
  fi
done < ver_file.txt
