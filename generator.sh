#!/bin/bash

set -o pipefail

echo "What do you want your project to be called?"
read project_name

# ensure the project name has no special characters
project_name=$(echo "$project_name" | tr -dc '[:alnum:]\n\r' | tr '[:upper:]' '[:lower:]')

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
echo "What Bundle Identifier would you like to use? (ex: com.yourcompany.yourapp - if you want Mobify projects to work out of the box with hockeyapp, it must start with "com.mobify.")"
read bundle_identifier

ios_ci_support=0
android_ci_support=0

# if yes, inform user of Circle setup document
read -p "Do you want iOS CI support? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo "Please see the main README about setting up iOS CI support"
    ios_ci_support=1
fi

read -p "Do you want Android CI support? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo "Please see the main README about setting up Android CI support"
    android_ci_support=1
fi

mkdir "$project_name"
cd "$project_name" || exit

git init
git pull git@github.com:mobify/astro-scaffold.git --depth 1

if [[ "$ios_ci_support" -ne 1 && "$android_ci_support" -ne 1 ]]; then
    rm -rf circle.yml
    rm -rf circle
else
    if [ "$ios_ci_support" -ne 1 ]; then
        rm circle/add-ios-keys.sh
        rm circle/build-and-upload-ios.sh
        rm circle/remove-ios-keys.sh
        rm circle/config/mobify-qa-ios
        sed -i '' '/^## IOS_BEGIN$/,/^## IOS_END$/d' circle.yml
        rm -rf circle/certificates
        rm -rf circle/provisioning-profiles
    fi
    if [ "$android_ci_support" -ne 1 ]; then
        rm circle/build-and-upload-android.sh
        rm circle/install-android-dependencies.sh
        rm circle/wait-for-emulator-android.sh
        rm circle/config/mobify-qa-android
        sed -i '' '/^## ANDROID_BEGIN$/,/^## ANDROID_END$/d' circle.yml
    fi
fi

# replace scaffold in the names of different files and folders with $project_name
while true; do
    FOLDER=$(find . -name "*scaffold*" | head -n 1)
    if [ -z "$FOLDER" ]; then
        echo "Done"
        break
    else
        echo "$FOLDER"
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
