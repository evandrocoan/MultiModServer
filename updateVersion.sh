#!/usr/bin/env bash

# 
# Change log:
# v1.1
#  Implemented build incrementing number.
#  Created variables to hold the used files names.
#  Added file search and replace to update the version numbers.
# 
# v1.0
#  Downloaded from: https://github.com/cloudfoundry/cli/blob/master/bin/bump-version
# 
# 


versionFileName=VERSION.txt
filesToUpdate=scripting/include/galileo.inc

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
echo "Replacing the version v$originalVersion -> v$currentVersion in $filesToUpdate"
echo $currentVersion > $versionFileName
sed -i -- "s/v$originalVersion/v$currentVersion/g" $filesToUpdate


echo "Staging $versionFileName and $filesToUpdate..."
git add $versionFileName
git add $filesToUpdate


exit 0






