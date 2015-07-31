#!/bin/bash

set -o pipefail

echo "What do you want your project to be called?"
read project_name

# ensure the project name has no special characters
project_name=$(echo $project_name | tr -dc '[:alnum:]\n\r' | tr '[:upper:]' '[:lower:]')

# ask them to confirm the project name
read -p "The project name is \"$project_name\". Would you like to proceed? (y/n) " -n 1 -r
echo    # (optional) move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit 1
fi

# ask them for the app scheme
echo "What app scheme do you want for deep linking into your iOS app? (ex: facebook://, but don't include the ://)"
read app_scheme

# ask for the host name for Android deep linking
echo "What host would you like to override for deep linking into your Android app? (ex: www.example.com)"
read hostname

# ask for the bundle identifier 
echo "What Bundle Identifier would you like to use? (ex: com.yourcompany.yourapp)"
read bundle_identifier

mkdir $project_name
cd $project_name

git init
git pull git@github.com:mobify/astro-scaffold.git --depth 1

# replace scaffold in the names of different files and folders with $project_name
while true; do
    FOLDER=$(find . -name "*scaffold*" | head -n 1)
    if [ -z "$FOLDER" ]; then
        echo "Done"
        break
    else
        echo $FOLDER
        mv -vf "$FOLDER" "${FOLDER/scaffold/$project_name}"
    fi
done

# replace "com.mobify.astro" with $bundle_identifier inside of files
egrep -lR "com\.mobify\.astro" . | tr '\n' '\0' | xargs -0 -n1 sed -i '' "s/com\.mobify\.astro\.\$(PRODUCT_NAME:rfc1034identifier)/$bundle_identifier/g" 2>/dev/null
egrep -lR "com\.mobify\.astro" . | tr '\n' '\0' | xargs -0 -n1 sed -i '' "s/com\.mobify\.astro\.scaffold/$bundle_identifier/g" 2>/dev/null

# replace "www.mobify.com" with $hostname inside of the AndroidManifest
egrep -lR "android:host=\"www.mobify.com\"" . | tr '\n' '\0' | xargs -0 -n1 sed -i '' "s/android:host=\"www.mobify.com\"/android:host=\"$hostname\"/g" 2>/dev/null

# replace "scaffold" with $project_name inside of files
egrep -lR "scaffold" . | tr '\n' '\0' | xargs -0 -n1 sed -i '' "s/scaffold/$project_name/g" 2>/dev/null 

# update submodule (this is done after replacing to
# avoid doing replaces inside of the submodule!)
git submodule update --init
