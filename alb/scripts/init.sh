 #!/bin/bash -xe
sudo yum -y update
sudo yum -y install httpd
echo $HOSTNAME | sudo tee /var/www/html/index.html
sudo service httpd start
sudo chkconfig httpd on
