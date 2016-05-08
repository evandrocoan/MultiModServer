#!/usr/bin/env bash

# 
# Run the version update script.
#



GIT_DIR_="$(git rev-parse --git-dir)"
githooksConfig=$(cat $GIT_DIR_/../githooks/githooksConfig.txt)

updateVersionProgram=$GIT_DIR_/../githooks/updateVersion.sh
updateFlagFile=$GIT_DIR_/isToUpdateTheGalileoFile.txt


# $updateFlagFile example: isToUpdateTheGalileoFile.txt
updateFlagFile=$GIT_DIR_/$(echo $githooksConfig | cut -d',' -f 4)


# Updates and changes the files if the flag file exits.
# '-C HEAD' do not prompt for a commit message, use the HEAD as commit message.
# '--no-verify' do not call the pre-commit hook to avoid infinity loop.
if [ -f $updateFlagFile ]
then
    if sh $updateVersionProgram build
    then
        echo "Successfully ran '$updateVersionProgram'"
    else
        echo "Could not run the update program '$updateVersionProgram' properly!"
        exit 1
    fi
    echo "Amending commits..."
    git commit --amend -C HEAD --no-verify
else
    echo "It is not time to amend as the file '$updateFlagFile' does not exist."
fi


# To clean any old missed file
if [ -f $updateFlagFile ]
then
    echo "Removing old post-commit configuration file '$updateFlagFile'..."
    rm $updateFlagFile
fi


# Exits the program using a successful exit status code.
exit 0





