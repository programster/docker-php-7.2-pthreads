#!/bin/bash

# ensure running bash
if ! [ -n "$BASH_VERSION" ];then
    echo "this is not bash, calling self with bash....";
    SCRIPT=$(readlink -f "$0")
    /bin/bash $SCRIPT
    exit;
fi

# Get the path to script just in case executed from elsewhere.
SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")
cd $SCRIPTPATH

# Load the variables from settings file.
source docker_settings.sh

IMAGE_NAME="`echo $REGISTRY`/`echo $PROJECT_NAME`"

# Ask the user if they want to use the docker cache
read -p "Do you want to use a cached build (y/n)? " -n 1 -r
echo ""   # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    docker build --pull --tag="$IMAGE_NAME" .
else
    docker build --no-cache --pull --tag="$IMAGE_NAME" .
fi

echo "============================="
echo ""

# Uncomment the line below if you have setup a registry and defined
# it within the docker_settings.sh file
read -p "Do you want to push this image to the public repository? (y/n) " -n 1 -r
echo ""   # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    docker push $REGISTRY/$PROJECT_NAME
fi

echo ""
echo "Image built. Why not try it out with:"
echo "docker run -it `echo $IMAGE_NAME`:latest /bin/bash"
echo ""
