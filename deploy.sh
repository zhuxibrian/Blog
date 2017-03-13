#!/bin/bash
 
WEB_PATH='/usr/hexo'
 
echo "Start deployment"
cd $WEB_PATH
echo "pulling source code..."
git reset --hard origin/master
git clean -f
git pull
git checkout master
echo "Finished."