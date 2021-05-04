 #!/bin/bash -xe
sudo yum -y update
sudo yum -y install httpd
sudo cp /var/www/error/noindex.html /var/www/html/index.html
sudo service httpd start
sudo chkconfig httpd on
