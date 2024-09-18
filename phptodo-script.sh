#!/bin/bash

set -x

# Define the database password
DATABASE_PASS='admin123'
ENV_FILE=".env"

# Add PHP repository (for PHP 7.4)
sudo add-apt-repository ppa:ondrej/php -y
sudo apt update

# Install required packages
sudo apt install -y git zip unzip mysql-server software-properties-common php7.4 \
php7.4-cli php7.4-fpm php7.4-opcache php7.4-gd \
php7.4-curl php7.4-mysql php7.4-mbstring php7.4-xml

# Start and enable the MySQL service
sudo systemctl start mysql
sudo systemctl enable mysql

# Set MySQL root password
sudo mysqladmin -u root password "$DATABASE_PASS"

# Secure MySQL and create the database and user
sudo mysql -u root -p"$DATABASE_PASS" <<EOF
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.db WHERE Db='test' OR Db='test_%';
FLUSH PRIVILEGES;
CREATE DATABASE homestead;
CREATE USER 'homestead'@'%' IDENTIFIED BY 'admin123';
GRANT ALL PRIVILEGES ON homestead.* TO 'homestead'@'%';
FLUSH PRIVILEGES;
EOF

echo "MySQL setup is complete."

# Start and enable PHP-FPM service
sudo systemctl start php7.4-fpm
sudo systemctl enable php7.4-fpm

# Clone the PHP todo project from GitHub
git clone https://github.com/nbomasi/php-todo.git

# Install Apache web server
sudo apt install -y apache2

# Restart Apache to load the PHP-FPM service
sudo systemctl restart apache2

# Check the status of Apache service
sudo systemctl status apache2

echo "PHP and Apache setup complete."

# Install MySQL client needed if you are running the app on a seperate server
#sudo apt install mysql-client -y

# Delete existing index.html
sudo rm -f /var/www/html/index.html

#Change html permission to writable
sudo chmod 777 -R /var/www/html

# Copy project files to Apache root directory
sudo cp -R php-todo/. /var/www/html

# Change to the Apache root directory
cd /var/www/html

# Rename .env.sample to .env
mv -f .env.sample $ENV_FILE

# Write the .env file
cat <<EOF > $ENV_FILE
APP_ENV=local
APP_DEBUG=true
APP_KEY=SomeRandomString
APP_URL=http://localhost

DB_HOST=127.0.0.1
DB_DATABASE=homestead
DB_USERNAME=homestead
DB_PASSWORD=admin123
AP_KEY=${AP_KEY}

CACHE_DRIVER=file
SESSION_DRIVER=file
QUEUE_DRIVER=sync

REDIS_HOST=127.0.0.1
REDIS_PASSWORD=null
REDIS_PORT=6379

MAIL_DRIVER=smtp
MAIL_HOST=mailtrap.io
MAIL_PORT=2525
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_ENCRYPTION=null
EOF

echo ".env file created successfully!"

# Download composer-setup.php
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"

# Install Composer
php composer-setup.php

# Remove the setup file after installation
php -r "unlink('composer-setup.php');"

# Move composer to /usr/local/bin for global usage
sudo mv composer.phar /usr/local/bin/composer

# Run composer install
composer install

if [ $? -ne 0 ]; then
    echo "Composer install command failed!"
    exit 1
else
    echo "Composer install completed."
fi

# Run migrations
php artisan migrate
if [ $? -ne 0 ]; then
    echo "Database migrations failed!"
    exit 1
else
    echo "Database migrations completed."
fi
AP_KEY=$(php artisan key:generate)

if [ $? -ne 0 ]; then
    echo "App key failed!"
    exit 1
else
    echo "App key generated."
fi

# Serve the application
php artisan serve --host=0.0.0.0

if [ $? -ne 0 ]; then
    echo "Failed to serve the application!"
    exit 1
else
    echo "Application is now running on http://0.0.0.0:8000"
fi

#sudo a2dissite 000-default.conf

# sudo a2enmod php
# sudo systemctl restart apache2
# sudo apt install php libapache2-mod-php

# sudo yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
# sudo yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm

# sudo yum install https://rpms.remirepo.net/enterprise/remi-release-8.rpm
# sudo dnf module enable php:remi-7.4
# sudo yum install php php-mbstring php-xml
# sudo systemctl restart httpd



