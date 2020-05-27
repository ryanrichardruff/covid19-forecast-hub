#!/usr/bin/env bash

set -e

if [[ "$TRAVIS_COMMIT_MESSAGE" == "[TRAVIS] Autogenerated files from travis" ]]; then
    echo "This is an auto commit from travis. Not doing anything."
    exit 0
fi


# Save some useful information
REPO=`git config remote.origin.url`
SSH_REPO=${REPO/https:\/\/github.com\//git@github.com:}
SHA=`git rev-parse --verify HEAD`


echo "Running test script..."
npm install
sudo apt-get install python3-pandas
sudo apt install python3-pip
pip3 install --upgrade setuptools
pip3 install pymmwr click requests urllib3 selenium webdriver-manager pyyaml python-dateutil numpy
pip3 install git+https://github.com/reichlab/zoltpy/
source ./travis/validate-data.sh
echo "build complete"

if [[ "$TRAVIS_BRANCH" != "master" ]]; then
    echo "Not on master. Not doing anything else."
    exit 0
fi

if [[ "$TRAVIS_EVENT_TYPE" == *"cron"* ]]; then
   echo "updating truth data..."
   bash ./travis/update-truth.sh
fi

if [[ "$TRAVIS_COMMIT_MESSAGE" == *"Merge pull request"* ]]; then
   echo "Upload forecasts to Zoltar "
   bash ./travis/upload-to-zoltar.sh
fi

if [ "$TRAVIS_PULL_REQUEST" = "false" ]; then 
   echo "NOT PULL REQUEST" 
   echo "replace validated files"
   cp ./code/validation/locally_validated_files.csv ./code/validation/validated_files.csv

   echo "Merge detected.. push to github"
   bash ./travis/push.sh
fi

# if [[ "$TRAVIS_COMMIT_MESSAGE" == *"trigger build"* ]]; then
#     source ./travis/vis-deploy.sh
# fi
#

# Functions below are for testing purposes
if [[ "$TRAVIS_COMMIT_MESSAGE" == *"test truth"* ]]; then
    echo "updating truth data..."
    bash ./travis/update-truth.sh
    echo "Push the truth"
    bash ./travis/push.sh
    echo "Upload truth to Zoltar"
    python3 ./code/zoltar-scripts/upload_truth_to_zoltar.py
fi

if [[ "$TRAVIS_COMMIT_MESSAGE" == *"test zoltar upload"* ]]; then
    echo "Upload forecasts to Zoltar"
    bash ./travis/upload-to-zoltar.sh
    echo "Push the validated file db to Zoltar"
    bash ./travis/push.sh
fi

if [[ "$TRAVIS_COMMIT_MESSAGE" == *"test truth zoltar"* ]]; then
    echo "Upload truth to Zoltar"
    python3 ./code/zoltar-scripts/upload_truth_to_zoltar.py
fi

if [[ "$TRAVIS_COMMIT_MESSAGE" == *"test zoltar validated db"* ]]; then
    echo "Create new validated zoltar forecast list"
    bash ./travis/create-validated-file-db.sh
    echo "Push the validated file db to Zoltar"
    bash ./travis/push.sh
fi