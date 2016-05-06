#!/usr/bin/env bash


#
# This file must be ran from the main repository folder. It updates the software version number
# indicated at "fileToUpdate" and "versionFileName". The versions at these two files must to be
# synchronized for a correct version update. 
#
# You can also update the version manually, but you must to update both files: "./githooks/VERSION.txt"
# and "./scripting/galileo.sma" using the same version number.
#
# Program usage: updateVersion [major | minor | patch | build]
# Example: ./updateVersion build
#
#
# Change log:
# v1.1.1
# Placed this file within the repository sub-folder "./githooks".
#
# v1.1
#  Implemented build incrementing number.
#  Created variables to hold the used files names.
#  Added file search and replace to update the version numbers.
#
# v1.0
#  Downloaded from: https://github.com/cloudfoundry/cli/blob/master/bin/bump-version
#
#


versionFileName=githooks/GALILEO_VERSION.txt
fileToUpdate=scripting/galileo.sma


currentVersion=$(cat $versionFileName)
originalVersion=$currentVersion
component=$1


major=$(echo $currentVersion | cut -d'.' -f 1)
minor=$(echo $currentVersion | cut -d'.' -f 2)
patch=$(echo $currentVersion | cut -d'.' -f 3)
build=$(echo $currentVersion | cut -d'.' -f 4)



if [ -z "${major}" ]
then
    echo "VAR major is unset or set to the empty string"
    exit 1
fi


case "$component" in
    major )
        major=$(expr $major + 1)
        minor=0
        patch=0
        ;;
        
    minor )
        minor=$(expr $minor + 1)
        patch=0
        ;;
        
    patch )
        patch=$(expr $patch + 1)
        ;;
        
    build )
        ;;
        
    * )
        echo "Error - argument must be 'major', 'minor', 'patch' or 'build'"
        echo "Usage: updateVersion [major | minor | patch | build]"
        exit 1
        ;;
esac


build=$(expr $build + 1)
currentVersion=$major.$minor.$patch.$build


# sed -i -- 's/v2.6.0.0/v2.6.0.1/g' scripting/galileo.sma
#
echo "Replacing the version v$originalVersion -> v$currentVersion in $fileToUpdate"
echo $currentVersion > $versionFileName


# To prints a error message when it does not find the version number on the files.
if ! sed -i -- "s/v$originalVersion/v$currentVersion/g" $fileToUpdate
then
    echo "Error! Could not find $originalVersion and update the file $fileToUpdate."
    echo "The current version number on this file must be v$originalVersion!"
    exit 1
fi


# To add the recent updated files to the commit
echo "Staging $versionFileName and $fileToUpdate..."
git add $versionFileName
git add $fileToUpdate


exit 0






