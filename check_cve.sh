#!/bin/bash 
#filename='projects/common/packages'
if [ $# -ne 2 ]; then
  echo "Usage: $0 <CentO Risk analysis sheet>  <csv report>"
  exit 1
fi
filename=$1
branch=$(grep 'Risk Analysis' "$filename" | awk 'NR==1 {print $3}')
prev_release_date="2023-10-31" # YYYY-MM-DD

case $branch in
    CentOS7_9)
        branch="c7-9-mv"
        ;;
    CentOS7_8)
        branch="c7-8-mv"
        ;;
    CentOS7_6)
        branch="c7-6-mv"
        ;;
    CentOS7_5)
        branch="c7-5-mv"
        ;;
    Rocky8_5)
        branch="r8-5-mv"
        ;;
    Rocky8_6)
        branch="r8-6-mv"
        ;;
    Rocky8_7)
        branch="r8-7-mv"
        ;;
    Rocky8_8)
        branch="r8-8-mv"
        ;;
	
    *)
        echo " could not identify a valid branch exiting..."
	exit 1
        ;;
esac
echo "The CVE checking is proceeing for the branch:$branch"
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
cvefile="/tmp/cve_file_$branch.txt" 
n=1
while read package; do
  # reading each line
  echo "Package Name: $package"
  pkg_git=""
  pkg_git+="$package.git"
  echo "cloning package $package ..."
  git clone --branch $branch git://gitcentos.mvista.com/centos/upstream/packages/$pkg_git 
  #> /dev/null 2>&1
  #if [ $? != 0 ]; then
   # echo "WARNING: Fail to clone $package package"
    #continue;
  #fi
  if [ -d $package ]; then
    pushd $package > /dev/null
    package_name=`git config -l  | grep packages |xargs  basename`
    all_commits=`git log --oneline --source  --no-merges --since=$prev_release_date -G 'CVE-[0-9]{4}-[0-9]{4,19}' SPECS/*.spec |  cut  -f1`
    echo "CVE NUMBER, PACKAGE, COMMIT_ID, DESCRIPTION, COMMITED BY, COMMITED DATE"
    for commit in ${all_commits[@]}; do
      cve_string=`git show $commit SPECS/*.spec |grep -i '^+'|grep -Eo 'CVE-[0-9]{4}-[0-9]{4,19}' | sort | uniq`
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
echo "Comparing the CVE's with the CSV report......"
echo "=============================================="
while read line; do
  if grep -q "$line" $2; then
    echo "The CVE: $line is found in the report sheet"
  else
    echo -e  "The CVE: \033[31m $line \033[0m is not found in the report sheet"
  fi
done < $cvefile
>  $cvefile



