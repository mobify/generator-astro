#!/bin/bash
set -o pipefail

MYDIR=$(pwd)
ROOT=$MYDIR # In some scripts ROOT != MYDIR

ASTRO_VERSION=0.7.0
SCAFFOLD_VERSION=$ASTRO_VERSION
SCAFFOLD_URL="https://github.com/mobify/astro-scaffold/archive/$SCAFFOLD_VERSION.zip"

read -p"--> We have a license you must read and agree to. Read license? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]] ; then
    exit 1
fi

curl -s -O -L https://raw.githubusercontent.com/mobify/generator-astro/develop/LICENSE
trap 'rm -f LICENSE' EXIT
less LICENSE

read -p"--> I have read, understand, and accept the terms and conditions stated in the license above. (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]] ; then
    exit 1
fi

read -p'--> What is the name of your project? ' project_name
# $project_name must not contain special characters.
project_name=$(echo $project_name | tr -dc '[:alnum:]\n\r' | tr '[:upper:]' '[:lower:]')

read -p"--> Continue with the project name '$project_name'? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]] ; then
    exit 1
fi

read -p'--> On iOS, which app scheme do you want for deep linking? (eg. mobify) ' app_scheme
read -p'--> On Android, which host would you like to use for deep linking? (eg. www.mobify.com) ' hostname
read -p"--> Which iOS Bundle Identifier and Android Package Name would you like to use? Begin with 'com.mobify.' to use HockeyApp. (eg. com.mobify.app) " bundle_identifier

ios_ci_support=0
android_ci_support=0

read -p'--> On iOS, do you want continuous integration? (y/n) ' -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]] ; then
    echo '    ↳ To setup iOS continuous integration, see README.md.'
    ios_ci_support=1
fi

read -p "--> On Android, do you want continuous integration? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]] ; then
    echo '    ↳ To setup Android continuous integration, see README.md.'
    android_ci_support=1
fi

# Prepare new project directory
project_dir="$ROOT/$project_name"
echo "Setting up new project in $project_dir"
mkdir "$project_dir"
cd "$project_dir" || exit
git init

# Download the scaffold and copy it into the project directory
WORKING_DIR=$(mktemp -d /tmp/astro-scaffold.XXXXX)
trap 'rm -rf "$WORKING_DIR"' EXIT

curl --progress-bar -L "$SCAFFOLD_URL" -o "$WORKING_DIR/astro-scaffold-$SCAFFOLD_VERSION.zip"
cd $WORKING_DIR || exit
unzip -q "$WORKING_DIR/astro-scaffold-$SCAFFOLD_VERSION.zip"
cp -R "$WORKING_DIR/astro-scaffold-$SCAFFOLD_VERSION/" "$project_dir"

cd "$project_dir"

# Set up CI support
if [[ $ios_ci_support -ne 1 && $android_ci_support -ne 1 ]]; then
    rm -rf circle.yml
    rm -rf circle
else
    if [ $ios_ci_support -ne 1 ]; then
        rm circle/add-ios-keys.sh
        rm circle/build-and-upload-ios.sh
        rm circle/remove-ios-keys.sh
        rm circle/config/mobify-qa-ios
        sed -i '' '/^## IOS_BEGIN$/,/^## IOS_END$/d' circle.yml
        rm -rf circle/certificates
        rm -rf circle/provisioning-profiles
    fi
    if [ $android_ci_support -ne 1 ]; then
        rm circle/build-and-upload-android.sh
        rm circle/install-android-dependencies.sh
        rm circle/wait-for-emulator-android.sh
        rm circle/config/mobify-qa-android
        sed -i '' '/^## ANDROID_BEGIN$/,/^## ANDROID_END$/d' circle.yml
    fi
fi

# Replace scaffold in the names of different files and folders with $project_name.
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

# Replace "com.mobify.astro" with $bundle_identifier inside of files.
egrep -lR "com\.mobify\.astro" . | tr '\n' '\0' | xargs -0 -n1 sed -i '' "s/com\.mobify\.astro\.\$(PRODUCT_NAME:rfc1034identifier)/$bundle_identifier/g" 2>/dev/null
egrep -lR "com\.mobify\.astro" . | tr '\n' '\0' | xargs -0 -n1 sed -i '' "s/com\.mobify\.astro\.scaffold/$bundle_identifier/g" 2>/dev/null

# Replace "www.mobify.com" with $hostname inside of the AndroidManifest.
egrep -lR "android:host=\"www.mobify.com\"" . | tr '\n' '\0' | xargs -0 -n1 sed -i '' "s/android:host=\"www.mobify.com\"/android:host=\"$hostname\"/g" 2>/dev/null

# Replace "scaffold" with $project_name inside of files.
egrep -lR "scaffold" . | tr '\n' '\0' | xargs -0 -n1 sed -i '' "s/scaffold/$project_name/g" 2>/dev/null

# Update symlink to "scaffold-www" folder in android/assets
ln -sfn ../../../../../app/$project_name-www/ android/$project_name/src/main/assets/$project_name-www

git init
git add .
git commit -am 'Your first Astro commit - AMAZING! 🌟 👍🏽'
npm install
