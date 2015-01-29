#!/bin/sh

# See also http://wiki.centos.org/HowTos/Https

sudo yum -y install mod_ssl openssl

sudo openssl genrsa -out demo-cat.key 2048 
echo "Command-line input is requested, enter US, MarkLogic, and catalog-new.demo.marklogic.com as answers.."
sudo openssl req -new -key demo-cat.key -out demo-cat.csr
sudo openssl x509 -req -days 365 -in demo-cat.csr -signkey demo-cat.key -out demo-cat.crt

sudo cp demo-cat.crt /etc/pki/tls/certs
sudo cp demo-cat.key /etc/pki/tls/private/demo-cat.key
sudo cp demo-cat.csr /etc/pki/tls/private/demo-cat.csr
sudo restorecon -RvF /etc/pki
