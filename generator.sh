#!/bin/bash
set -o pipefail

MYDIR=$(pwd)
ROOT=$MYDIR # In some scripts ROOT != MYDIR

SCAFFOLD_VERSION_OR_BRANCH=master
SCAFFOLD_URL="https://github.com/mobify/astro-scaffold/archive/$SCAFFOLD_VERSION_OR_BRANCH.zip"

echo '                                '
echo '        _       _               '
echo '       /_\  ___| |_ _ __ ___    '
echo '      //_\\/ __| __|  __/ _ \   '
echo '     /  _  \__ \ |_| | | (_) |  '
echo '     \_/ \_/___/\__|_|  \___/   '
echo '                                '
echo '                                '

read -p"➞ Press any key to review the Astro license..." -n 1 -r
echo

curl -s -O -L https://raw.githubusercontent.com/mobify/generator-astro/master/LICENSE
trap 'rm -f LICENSE' EXIT
less LICENSE

read -p"➞ I have read, understand, and accept the terms and conditions stated in the license above. (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]] ; then
    echo "  ↳ License rejected. Aborting..."
    exit 1
else
    echo "  ↳ License accepted. Continuing..."
fi

read -p'➞ What is the name of your project? ' project_name
# $project_name must not contain special characters.
project_name=$(echo "$project_name" | tr -dc '[:alnum:]\n\r' | tr '[:upper:]' '[:lower:]' | tr -d ' ')

read -p"  ↳ Continue with the project name '$project_name'? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]] ; then
    echo "  ↳ Aborting..."
    exit 1
fi

# Currently we do nothing with 'app_scheme' so we won't prompt for it right now
# read -p'➞ On iOS, which app scheme do you want for deep linking? (eg. mobify) ' app_scheme

hostname=""
bundle_identifier=""

bundle_regex="^[a-zA-Z]+(\.?[a-zA-Z]+\w*)+$"

while [ -z "$hostname" ]; do
    read -p'➞ On Android, which host would you like to use for deep linking? (eg. www.mobify.com) ' hostname
done

while [ -z "$bundle_identifier" ]; do
    read -p"➞ Which iOS Bundle Identifier and Android Package Name would you like to use? (eg. com.mobify.build.app) " bundle_identifier

    if [[ "$bundle_identifier" =~ $bundle_regex ]]; then
        read -p"  ↳ Continue with the iOS Bundle Identifier and Android Package Name $bundle_identifier? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]] ; then
            bundle_identifier=''
        fi
    else
        bundle_identifier=''
        echo '      Invalid package name'
        echo '      The name may contain uppercase or lowercase letters ('A' through 'Z'), numbers, and underscores ('_').'
        echo '      However, individual package name parts may only start with letters.'
    fi
done

ios_ci_support=0
android_ci_support=0
buddybuild_support=0
tab_layout="false"
project_type="adaptive.js"

read -p'➞ On iOS, do you want continuous integration? (y/n) ' -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]] ; then
    echo '  ↳ To setup iOS continuous integration, see README.md.'
    ios_ci_support=1
fi

read -p "➞ On Android, do you want continuous integration? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]] ; then
    echo '  ↳ To setup Android continuous integration, see README.md.'
    android_ci_support=1
fi

if [[ $ios_ci_support -ne 1 && $android_ci_support -ne 1 ]]; then
    echo '  ↳ Skipping buddybuild integration because continuous integration was not included'
else
    read -p "➞ Do you want buddybuild support? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]] ; then
        buddybuild_support=1
    fi
fi

read -p '➞ Do you want to enable Mobify preview? (y/n) ' -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]] ; then
    echo '  ↳ To enable Mobify preview later, see README.md.'
else
    REPLY=

    echo "➞ What type of project is this?"
    echo "    1. Mobify.js (legacy)"
    echo "    2. Adaptive.js (legacy)"

    while [ ! "$REPLY" ]; do
        read -p '    Choices (1 or 2): ' -n 1 -r
        echo
        case $REPLY in
        1)
            echo "  ↳ Setting project type to Mobify.js (legacy)"
            project_type="mobify.js"
            ;;
        2)
            echo "  ↳ Setting project type to Adaptive.js (legacy)"
            project_type="adaptive.js"
            ;;
        *)
            REPLY=
            echo "    !! Invalid selection: '$REPLY'. Please enter 1, 2, or 3."
            ;;
        esac
    done
fi

read -p'➞ Do you want to use a tab layout (otherwise a drawer layout will be used)? (y/n) ' -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]] ; then
    tab_layout="true"
fi

echo
echo

# ******************* END OF QUESTIONS / START GENERATING ******************* #

# Prepare new project directory
project_dir="$ROOT/$project_name"
echo "Setting up new project in $project_dir"
mkdir "$project_dir"
cd "$project_dir" || exit
git init

# Download the scaffold and copy it into the project directory
WORKING_DIR=$(mktemp -d /tmp/astro-scaffold.XXXXX)
trap 'rm -rf "$WORKING_DIR"' EXIT

curl --progress-bar -L "$SCAFFOLD_URL" -o "$WORKING_DIR/astro-scaffold-$SCAFFOLD_VERSION_OR_BRANCH.zip"
cd "$WORKING_DIR" || exit
unzip -q "$WORKING_DIR/astro-scaffold-$SCAFFOLD_VERSION_OR_BRANCH.zip"
cp -R "$WORKING_DIR/astro-scaffold-$SCAFFOLD_VERSION_OR_BRANCH/" "$project_dir"

cd "$project_dir" || exit

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

if [ $buddybuild_support -ne 1 ]; then
    rm buddybuild_postclone.sh
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

# Replace "com.mobify.astro" with $bundle_identifier inside of apple-app-site-association file
egrep -lR "DEV_TEAM_ID.com.mobify.astro" . | tr '\n' '\0' | xargs -0 -n1 sed -i '' "s/DEV_TEAM_ID.com.mobify.astro/DEV_TEAM_ID.$bundle_identifier/g" 2>/dev/null

# Replace "www.mobify.com" with $hostname inside of the AndroidManifest.
egrep -lR "android:host=\"www.mobify.com\"" . | tr '\n' '\0' | xargs -0 -n1 sed -i '' "s/android:host=\"www.mobify.com\"/android:host=\"$hostname\"/g" 2>/dev/null

# Replace "www.mobify.com" with $hostname inside of the ios entitlements file.
egrep -lR "applinks:www.mobify.com" . | tr '\n' '\0' | xargs -0 -n1 sed -i '' "s/applinks:www.mobify.com/applinks:$hostname/g" 2>/dev/null


# Replace "scaffold" with $project_name inside of files.
egrep -lR "scaffold" . | tr '\n' '\0' | xargs -0 -n1 sed -i '' "s/scaffold/$project_name/g" 2>/dev/null

# Configure preview plugin
egrep -lR "previewBundle = \'<preview_bundle>\'" . | tr '\n' '\0' | xargs -0 -n1 sed -i '' "s/previewBundle = \'<preview_bundle>\'/previewBundle = \'https:\/\/localhost:8443\/$project_type\'/g" 2>/dev/null

# Configure the navigation layout
egrep -lR "useTabLayout = false" . | tr '\n' '\0' | xargs -0 -n1 sed -i '' "s/useTabLayout = false/useTabLayout = $tab_layout/g" 2>/dev/null

git init
git add .
git commit -am 'Your first Astro commit - AMAZING! 🌟 👍🏽'
npm run deps
