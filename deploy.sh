#!/bin/bash
 
WEB_PATH='/usr/hexo'
 
echo "Start deployment"
cd $WEB_PATH
echo "pulling source code..."
git pull origin master
echo "pull finish."
npm install
echo "npm install finish"
hexo g
echo "hexo g"