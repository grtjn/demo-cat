#!/bin/sh

sudo npm -g install bower
sudo npm -g install gulp
sudo npm -g install forever

cd ..
npm install
bower install
gulp jshint less scripts

cd /etc
sudo ln -s /space/projects/demo-cat.live/etc/prod demo-cat
sudo ln -s demo-cat demo-cat-watch
cd /etc/init.d
sudo ln -s /space/projects/demo-cat.live/etc/init.d/node-express-service demo-cat
sudo ln -s /space/projects/demo-cat.live/etc/init.d/node-gulp-service demo-cat-watch
sudo chkconfig --add demo-cat
sudo chkconfig --add demo-cat-watch
sudo chkconfig --levels 2345 demo-cat on
sudo chkconfig --levels 2345 demo-cat-watch on

sudo service demo-cat start
sudo service demo-cat-watch start
