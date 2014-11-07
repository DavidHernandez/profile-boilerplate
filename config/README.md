# Configuration
Copy the configuration files of your site into this folder. The deployment script only covers the default settings.php file, if your site needs other configuration files, you will have 
to update the deploy.sh script.
* settings.php: This file will be copied into the active release, to use the live database.
* vhost.conf: A sample Apache Virtual host you can use to point to the site. It points to a folder that will be created with each deploy: profile-boilerplate/active
