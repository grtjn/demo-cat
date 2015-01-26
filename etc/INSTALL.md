# Installing services

The code includes service scripts, and service configs to make installing express server service and gulp watch service as easy as possible. The following files are involved:

- etc/init.d/node-express-service (generic express server service script)
- etc/init.d/node-gulp-service (generic gulp watch service script)
- etc/{env}/conf.sh (env specific service configuration, any env name allowed)
- startup.js (entry point for express service, calls out to server.js)
- server.js (called by both gulp server and startup.js)
- gulpfile.js (entry point for gulp service, which executes default task)

The conf.sh is 'sourced' by the service scripts, and allows overriding the built-in defaults. Usually you only need to override SOURCE\_DIR, APP\_PORT, and ML\_PORT. Make sure they match the appropriate environment.

Next step is to push all source files to the appropriate server. The following assumes it was dropped under /space/projects/ in a folder called demo-cat.live. Take these steps to install the services:

- cd /etc
- sudo ln -s /space/projects/demo-cat.live/etc/{env} demo-cat
- sudo ln -s demo-cat demo-cat-watch
- cd /etc/init.d
- sudo ln -s /space/projects/demo-cat.live/etc/init.d/node-express-service demo-cat
- sudo ln -s /space/projects/demo-cat.live/etc/init.d/node-gulp-service demo-cat-watch
- sudo chkconfig --add demo-cat
- sudo chkconfig --add demo-cat-watch
- sudo chkconfig --levels 2345 demo-cat on
- sudo chkconfig --levels 2345 demo-cat-watch on

NOTE: make sure bower, gulp, and forever are installed, and npm install, and bower install have run, before starting the services! And you probably want to bootstrap, and deploy modules as well.

Next to start them, use the following commands (from any directory):

- sudo service demo-cat start
- sudo service demo-cat-watch start

These services will also print usage without param, but they support info, restart, start, status, and stop. The info param is very useful to check the settings.

# Initializing httpd

Next to this, you likely want to enable the httpd daemon. Only ports 8000 through 8099 are exposed on demo servers, and we usually deliberately configure (part of) the application outside that scope. Add a forwarding rule for the appropriate dns:

- sudo chkconfig --levels 2345 httpd on
- sudo service httpd stop
- sudo vi /etc/httpd/conf/httpd.conf, uncomment the line with:

NameVirtualHost *:80

- and append:

<VirtualHost *:80>
  ServerName catalog.demo.marklogic.com
  RewriteEngine On
  RewriteRule ^(.*)$ http://localhost:4000$1 [P]
</VirtualHost>

- sudo service httpd start
