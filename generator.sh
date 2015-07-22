#!/bin/bash

echo "What do you want your project to be called?"

read project_name

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

# replace scaffold with $project_name inside of files
egrep -lR "scaffold" . | tr '\n' '\0' | xargs -0 -n1 sed -i '' "s/scaffold/$project_name/g"  

# update submodule (this is done after replacing to
# avoid doing replaces inside of the submodule!)
git submodule update --init
