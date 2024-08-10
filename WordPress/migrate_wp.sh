#!/bin/bash
# This script will migrate an old WordPress site to a new one

# Old WordPress directory
old_wp_directory="/current/wp/directory"

# New WordPress directory
wp_directory="/new/wp/directory"

# New MySQL database credentials
host="your_host"
user="your_username"
password="your_password"
database="your_database"

# New domain and name
new_domain="www.newdomain.com"
new_name="New Website Name"

# Migrate the website files to another directory on the same server (empties the destination directory first)
rm -rf "$wp_directory/*" && cp -r "$old_wp_directory/"* "$wp_directory" &

# Mysqldump database and pipe to remote db
# Credit: https://dba.stackexchange.com/questions/174/how-can-i-move-a-database-from-one-server-to-another

mysqldump -h$host -u$user -p$password $database | mysql -h$host -u$user -p$password $database

# SET New domain and name
sql="
UPDATE wp_options SET option_value = replace(option_value, 'http://www.olddomain.com', '$new_domain') WHERE option_name = 'home' OR option_name = 'siteurl';
UPDATE wp_posts SET guid = replace(guid, 'http://www.olddomain.com','$new_domain');
UPDATE wp_posts SET post_content = replace(post_content, 'http://www.olddomain.com', '$new_domain');
UPDATE wp_postmeta SET meta_value = replace(meta_value,'http://www.olddomain.com','$new_domain');
UPDATE wp_options SET option_value = '$new_name' WHERE option_name = 'blogname';
"

# Execute SQL query
echo "$sql" | mysql -h$host -u$user -p$password $database