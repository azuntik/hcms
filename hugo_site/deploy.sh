#!/bin/sh
# Hugo build and rsync deployment script

USER=erik
HOST=kahuna
DIR=Server/websites/smltags_com/public/

# Navigate to Hugo site directory
cd "$(dirname "$0")"

# Build the Hugo site
echo "Building Hugo site..."
hugo --minify

if [ $? -ne 0 ]; then
    echo "Hugo build failed!"
    exit 1
fi

# Deploy via rsync
echo "Deploying to ${USER}@${HOST}..."
rsync -avz --delete public/ ${USER}@${HOST}:~/${DIR}

if [ $? -eq 0 ]; then
    echo "Deployment successful!"
    exit 0
else
    echo "Deployment failed!"
    exit 1
fi
