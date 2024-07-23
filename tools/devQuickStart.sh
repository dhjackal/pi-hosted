#!/bin/bash

function error {
  echo -e "\\e[91m$1\\e[39m"
  exit 1
}

function check_internet() {
  printf "Checking if you are online..."
  wget -q --spider http://github.com
  if [ $? -eq 0 ]; then
    echo "Online. Continuing."
  else
    error "Offline. Go connect to the internet then run the script again."
  fi
}

check_internet

echo "Updating and upgrading system packages"
sudo apt update && sudo apt upgrade -y
echo ""
echo "Installing neofetch"
sudo apt install neofetch
echo ""
echo "Installing shellinabox"
sudo apt install shellinabox
echo ""
echo "Conmfiguring shellinabox"
sed -i 's/SHELLINABOX_PORT=4200/SHELLINABOX_PORT=4656/g' /etc/defaults/shellinabox
echo "Restarting shellinabox service"
sudo /etc/init.d/shellinabox restart
echo ""
echo "Installing rpi-connect"
sudo apt install rpi-connect
systemctl --user start rpi-connect
echo ""
echo "Installing samba"
sudo apt install samba samba-common-bin
mkdir ~/shared
echo -e "[cretefs]\n\npath = /home/pi/shared\n\nwriteable = yes\n\nbrowseable = yes\n\npublic=no"  >> /etc/samba/smb.conf
echo chmod 777 ~/shared 
sudo systemctl restart smbd
echo ""
echo "Installing docker"
curl -sSL https://get.docker.com | sh
sudo usermod -aG docker pi
echo "Testing docker installation"
sudo docker run hello-world


# Now for the real stuff

#echo "Creating directories..."

# nginx

sudo apt remove apache2

sudo apt install nginx -y

sudo systemctl start nginx

# PHP

sudo apt install php8.2-fpm php8.2-mbstring php8.2-mysql php8.2-curl php8.2-gd php8.2-curl php8.2-zip php8.2-xml -y

sudo nano /etc/nginx/sites-enabled/default

#sed -i 's/index index.html index.htm/index index.php index.html index.htm/g' /etc/defaults/shellinabox

# Find
#location ~ \.php$ {
        #       include snippets/fastcgi-php.conf;
        #
        #       # With php5-cgi alone:
        #       fastcgi_pass 127.0.0.1:9000;
        #       # With php5-fpm:
        #       fastcgi_pass unix:/var/run/php5-fpm.sock;
        #}

# Replace with 
#location ~ \.php$ {
#              include snippets/fastcgi-php.conf;
#             fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
#     }

sudo systemctl reload nginx

sudo nano /var/www/html/index.php

# Add

<?php phpinfo(); ?>

# MySQL

sudo apt install mariadb-server

sudo mysql -u root -p

sudo apt install php-mysql

sudo apt install php8.2-intl

# Download the latest version of joomla to /var/www

Create the joomla.conf file containing ; 

`
server {
    listen 80;
    listen [::]:80;

    root /var/www/joomla;

    index index.php index.html index.htm;
    server_name _;

    client_max_body_size 100M;
    autoindex off;
    
    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    # deny running scripts inside writable directories
    location ~* /(images|cache|media|logs|tmp)/.*.(php|pl|py|jsp|asp|sh|cgi)$ {
      return 403;
      error_page 403 /403_error.html;
    }

    location ~ .php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }

    # caching of files 
    location ~* \.(ico|pdf|flv)$ {
            expires 1y;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|swf|xml|txt)$ {
            expires 14d;
    }
}
`

sudo ln -s /etc/nginx/sites-available/joomla.conf /etc/nginx/sites-enabled/joomla.conf

sudo rm /etc/nginx/sites-enabled/default
