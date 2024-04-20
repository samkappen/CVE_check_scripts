#!/bin/bash 
#filename='projects/common/packages'
if [ $# -ne 1 ]; then
  echo "Usage: $0 <CentO Risk analysis sheet>"
  exit 1
fi


# Read the contents of Risk sheet to a variable
contents=$(cat $1)
# Use grep to find the line containing the word "Package Name" and extract the string after it
package_list=$(echo "$contents" | grep -oP 'Package Name[^"]*')

# Write the extracted package string to a file
echo "$package_list" | awk '{print $4}' > package_file
filename="package_file"
# Remove package kernel since cloning takes long time 
sed -i "/kernel/d" "$filename"
###########################################
cvefile="/tmp/cve_file.txt" 
prev_release_date="2023-05-01" # YYYY-MM-DD 
n=1
while read package; do
  # reading each line
  echo "Package Name: $package"
  make clone_$package > /dev/null 2>&1
  if [ $? != 0 ]; then
    echo "WARNING: Fail to clone $package package"
    continue;
  fi
  if [ -d packages/$package ]; then
    pushd packages/$package > /dev/null
    package_name=`git config -l  | grep packages |xargs  basename`
    all_commits=`git log --oneline --source  --no-merges --since=$prev_release_date -G 'CVE-[0-9]{4}-[0-9]{4,19}' SPECS/*.spec |  cut  -f1`
    echo "CVE NUMBER, PACKAGE, COMMIT_ID, DESCRIPTION, COMMITED BY, COMMITED DATE"
    for commit in ${all_commits[@]}; do
      cve_string=`git show $commit SPECS/*.spec |grep -i '^+-'|grep -Eo 'CVE-[0-9]{4}-[0-9]{4,19}' | sort | uniq`
      for cve_number in ${cve_string[@]}; do
        commit_details=`git log -1 --pretty='tformat:%h, %s, %cn, %ch' $commit`
      echo -e  "$cve_number, $package_name, $commit_details"
      echo -e "$cve_number" >> $cvefile
      done
    done
    popd > /dev/null
  fi
  n=$((n+1))
done < $filename

echo "=============================================="
echo "Comparing the CVE's with the Risk sheet......"
echo "=============================================="
while read line; do
  if grep -q "$line" $1; then
    echo "$line is present"
  else
    echo -e  "\033[31m $line is not present \033[0m"
  fi
done < $cvefile
>  /tmp/cve_file.txt

