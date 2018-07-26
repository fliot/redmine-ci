#!/bin/sh

export REPO=$1
echo "Initializing the Git repository :: $REPO"

if [ -d "/data/git/$REPO" ]; then
    
    echo "The /data/git/$REPO directory already exists !"
    exit 1
    
else
    
    # Init
    cd /data/git
    mkdir $REPO
    cd $REPO
    git init --bare --shared
    
    # First commit
    cd /tmp
    git clone /data/git/$REPO
    cd $REPO
    echo "" > README.md
    git add README.md
    git config --global user.email "nobody@nowhere.com"
    git config --global user.name "admin"
    git commit -m "initializing the Git repository"
    git status
    git push
    
    echo """#!/usr/bin/env ruby
message_file = ARGV[0]
message = File.read(message_file)

$regex = /(refs #(\d+)|fixes #(\d+))/

if !$regex.match(message)
  puts \"Your message is not formatted correctly (missing refs #XXX or fixes #XXX)\"
  exit 1
end
""" >  /data/git/$REPO/hooks/commit-msg
    chmod +x /data/git/$REPO/hooks/commit-msg
    
    echo ""
    echo "Local path (to configure to local redmine instance):"
    echo "  /data/git/$REPO"
    echo ""
    echo "Remote path:"
    echo "  http://"`/sbin/ifconfig | grep 'inet' | head -n 1 | awk '{ print $2 '}`":80/git/$REPO"
    echo ""
fi
