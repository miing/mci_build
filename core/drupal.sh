#############################################################################
#
#  Copyright (C) 2013 Miing.org <samuel.miing@gmail.com>
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#  
#############################################################################


cms_drupal_upgrade()
{
	if [ -z "$TARGET_CMS" ] ; then
		echo 
		echo "CMS::Drupal::Error::TARGET_CMS not set yet"
		return
	fi
	
	echo 
	echo "CMS::Drupal::Info::Upgrade for site[$TARGET_CMS_DRUPAL_SITE]"
}

cms_drupal_backup()
{
	if [ -z "$TARGET_CMS" ] ; then
		echo 
		echo "CMS::Drupal::Error::TARGET_CMS not set yet"
		return
	fi
	
	echo 
	echo "CMS::Drupal::Info::Backup for site[$TARGET_CMS_DRUPAL_SITE]"
}

cms_drupal_custom()
{
	if [ -z "$TARGET_CMS" ] ; then
		echo 
		echo "CMS::Drupal::Error::TARGET_CMS not set yet"
		return
	fi
	
	echo 
	echo "CMS::Drupal::Info::Customize for site[$TARGET_CMS_DRUPAL_SITE]"
}

cms_drupal_postconfig()
{
	if [ -z "$TARGET_CMS" ] ; then
		echo 
		echo "CMS::Drupal::Error::TARGET_CMS not set yet"
		return
	fi
	
	echo 
	echo "CMS::Drupal::Info::Postconfigure for site[$TARGET_CMS_DRUPAL_SITE]"
}

cms_drupal_install()
{
	if [ -z "$TARGET_CMS" ] ; then
		echo 
		echo "CMS::Drupal::Error::TARGET_CMS not set yet"
		return
	fi
	
	echo 
	echo "CMS::Drupal::Info::Install for site[$TARGET_CMS_DRUPAL_SITE]"
	
	local cmstop=/home/www-data/$TARGET_CMS_DRUPAL_SITE
	if [ ! -d $cmstop ] ; then
		sudo -u www-data mkdir $cmstop
	fi
	# Pick up the latest stable version of Drupal 
	# from http://drupal.org/project/drupal
	if [ ! -f $cmstop/sites/default/settings.php ] ; then
		local download_url=http://ftp.drupal.org/files/projects
		local full_version=$TARGET_CMS_DRUPAL_VERSION_INSTALLED
		local stable=drupal-$full_version.tar.gz
		sudo -u www-data wget -P $cmstop $download_url/$stable
		sudo -u www-data tar xzvf $cmstop/$stable -C $cmstop
		sudo -u www-data mv $cmstop/drupal-$full_version/* $cmstop/
		sudo -u www-data mv $cmstop/drupal-$full_version/.htaccess $cmstop/
		sudo -u www-data rm -rf $cmstop/drupal-$full_version
		sudo -u www-data rm $cmstop/$stable
		
		sudo -u www-data cp $cmstop/sites/default/default.settings.php $cmstop/sites/default/settings.php
	fi
}

cms_drupal_configure()
{
	if [ -z "$TARGET_CMS" ] ; then
		echo 
		echo "CMS::Drupal::Error::TARGET_CMS not set yet"
		return
	fi
	
	echo 
	echo "CMS::Drupal::Info::Configure for site[$TARGET_CMS_DRUPAL_SITE]"
	
	case $TARGET_CMS_DRUPAL_DBENGINE in
		mysql)
			local MYSQL MYSQL_HEADER MYSQL_ROOTPW
			local dbhost dbname dbuser dbpw
			MYSQL=(`which mysql`)
			
			# Create a new database via mysql for Drupal use which is named 
			# after by means of this variable,TARGET_CMS_DRUPAL_SITE. Let's say,
			# this name of the database would be mci_org if this value of
			# the variable is mci.org.
			if [ -z "$TARGET_CMS_DRUPAL_DBENGINE_DBNAME" ] ; then
				dbname=(`echo -n $TARGET_CMS_DRUPAL_SITE | sed -e "s/\./_/g"`)
				export TARGET_CMS_DRUPAL_DBENGINE_DBNAME=$dbname
			else
				dbname=$TARGET_CMS_DRUPAL_DBENGINE_DBNAME
			fi
			if [ -z "$TARGET_DBENGINE_MYSQL_ROOTPW" ] ; then
				read -s -p "Enter password for MySQL: " MYSQL_ROOTPW
				export TARGET_DBENGINE_MYSQL_ROOTPW=$MYSQL_ROOTPW
			else
				MYSQL_ROOTPW=$TARGET_DBENGINE_MYSQL_ROOTPW
			fi
			MYSQL_HEADER="$MYSQL --user=root --password=$MYSQL_ROOTPW --batch --skip-column-names -e"
			if [ ! `$MYSQL_HEADER "SHOW DATABASES LIKE '$dbname';"` ] ; then
				if [ -z "$TARGET_CMS_DRUPAL_DBENGINE_DBPW" ] ; then
					read -s -p "Enter password for 'Drupal' database: " dbpw
				else
					dbpw=$TARGET_CMS_DRUPAL_DBENGINE_DBPW
				fi
				if [ -z "$TARGET_CMS_DRUPAL_DBENGINE_DBUSER" ] ; then
					dbuser=drupal
					export TARGET_CMS_DRUPAL_DBENGINE_DBUSER=$dbuser
				else
					dbuser=$TARGET_CMS_DRUPAL_DBENGINE_DBUSER
				fi
				if [ -z "$TARGET_DBENGINE_MYSQL_HOST" ] ; then
					dbhost=localhost
					export TARGET_DBENGINE_MYSQL_HOST=$dbhost
				else
					dbhost=$TARGET_DBENGINE_MYSQL_HOST
				fi
				
				echo 
				echo -n "CMS::Drupal::Info::Create database[$dbname] for user[$dbuser] in "
				echo "'$TARGET_CMS_DRUPAL_DBENGINE'"
				
				MYSQL_HEADER="$MYSQL --user=root --password=$MYSQL_ROOTPW -e"
				$MYSQL_HEADER "CREATE DATABASE $dbname;"
				$MYSQL_HEADER "CREATE USER '$dbuser'@'$dbhost' IDENTIFIED BY '$dbpw';"
				$MYSQL_HEADER "GRANT ALL ON $dbname.* TO '$dbuser'@'$dbhost';"
				$MYSQL_HEADER "FLUSH PRIVILEGES;"
				$MYSQL_HEADER "QUIT"
			fi
			;;
		*)
			echo
			echo "CMS::Drupal::Error::Invalid dbengine type: '$TARGET_CMS_DRUPAL_DBENGINE'"
			return
			;;
	esac
	
	case $TARGET_CMS_DRUPAL_HTTPD in
		apache)
			local vhconfig keys
			
			case $TARGET_CMS_DRUPAL_HTTPD_SCHEME in
				http)
					sudo a2enmod rewrite
					
					# Configure virtualhost 
					if [ ! -f /etc/apache2/sites-available/$TARGET_CMS_DRUPAL_SITE ] ; then
						vhconfig=$TARGET_CMS_DRUPAL_SITE.$TARGET_CMS_DRUPAL_HTTPD_SCHEME
						if [ -f $TARGET_SITE_CONFIG/drupal/$vhconfig ] ; then
							sudo cp $TARGET_SITE_CONFIG/drupal/$vhconfig /etc/apache2/sites-available/$TARGET_CMS_DRUPAL_SITE
						else
							echo
							echo "CMS::Drupal::Error::No virtualhost with '$TARGET_CMS_DRUPAL_HTTPD_SCHEME' on $TARGET_CMS_DRUPAL_HTTPD"
							return
						fi
						
						# Match host names with IP address
						keys=(`cat /etc/hosts | grep -i -e "^[0-9\.]*[[:space:]]*$TARGET_CMS_DRUPAL_SITE"`)
						if [ ! "$keys" ] ; then
							sudo bash -c "cat >>/etc/hosts <<EOF
$TARGET_CMS_DRUPAL_HTTPD_IPADDR $TARGET_CMS_DRUPAL_SITE
$TARGET_CMS_DRUPAL_HTTPD_IPADDR www.$TARGET_CMS_DRUPAL_SITE
EOF"
						fi
						
						# Make virtualhost take effect
						sudo a2ensite $TARGET_CMS_DRUPAL_SITE
						sudo a2dissite default
						sudo /etc/init.d/apache2 restart
					fi
					;;
				https)
					sudo a2enmod ssl rewrite
					
					if [ ! -f /etc/apache2/sites-available/$TARGET_CMS_DRUPAL_SITE ] ; then
						# Generate a self-signed certificate for SSL
						if [ ! -d /etc/apache2/ssl ] ; then
							sudo mkdir /etc/apache2/ssl
						fi
						if [ ! -f /etc/apache2/ssl/$TARGET_SITE.crt -o ! -f /etc/apache2/ssl/$TARGET_SITE.key ] ; then
							local OPENSSL=(`which openssl`)
							sudo $OPENSSL req -new -x509 -days 365 -nodes -out $TARGET_SITE.crt -keyout $TARGET_SITE.key
							sudo mv $TARGET_SITE.crt /etc/apache2/ssl
							sudo mv $TARGET_SITE.key /etc/apache2/ssl
						fi
						
						# Configure virtualhost
						vhconfig=$TARGET_CMS_DRUPAL_SITE.$TARGET_CMS_DRUPAL_HTTPD_SCHEME
						if [ -f $TARGET_SITE_CONFIG/drupal/$vhconfig ] ; then
							sudo cp $TARGET_SITE_CONFIG/drupal/$vhconfig /etc/apache2/sites-available/$TARGET_CMS_DRUPAL_SITE
						else
							echo
							echo "CMS::Drupal::Error::No virtualhost with '$TARGET_CMS_DRUPAL_HTTPD_SCHEME' on $TARGET_CMS_DRUPAL_HTTPD"
							return
						fi
		
						# Enable virtualhost at port 443 for ssl
						keys=(`grep "^[[:space:]]NameVirtualHost \*:443" /etc/apache2/ports.conf`)
						if [ ! "$keys" ] ; then
							sudo sed -i -e "/^<IfModule mod_ssl.c>.*/a\\\tNameVirtualHost \*:443" /etc/apache2/ports.conf
						fi
						
						# Match host names with IP address
						keys=(`cat /etc/hosts | grep -i -e "^[0-9\.]*[[:space:]]*$TARGET_CMS_DRUPAL_SITE"`)
						if [ ! "$keys" ] ; then
							sudo bash -c "cat >>/etc/hosts <<EOF
$TARGET_CMS_DRUPAL_HTTPD_IPADDR $TARGET_CMS_DRUPAL_SITE
$TARGET_CMS_DRUPAL_HTTPD_IPADDR www.$TARGET_CMS_DRUPAL_SITE
EOF"
						fi
					
						# Make virtualhost take effect
						sudo a2ensite $TARGET_CMS_DRUPAL_SITE
						sudo a2dissite default
						sudo /etc/init.d/apache2 restart
					fi
					;;
				*)
					echo 
					echo "CMS::Drupal::Error::Invalid httpd scheme: '$TARGET_CMS_DRUPAL_HTTPD_SCHEME'"
					return
					;;
			esac
			;;
		*)
			echo
			echo "CMS::Drupal::Error::Invalid httpd type: '$TARGET_CMS_DRUPAL_HTTPD'"
			return
			;;
	esac
}

cms_drupal_preinstall()
{
	if [ -z "$TARGET_CMS" ] ; then
		echo 
		echo "CMS::Drupal::Error::TARGET_CMS not set yet"
		return
	fi
	
	echo 
	echo "CMS::Drupal::Info::Preinstall for site[$TARGET_CMS_DRUPAL_SITE]"
	
	if [ -n "$TARGET_CMS_DRUPAL_HTTPD" ] ; then
		httpd $TARGET_CMS_DRUPAL_HTTPD
	fi
	if [ -n "$TARGET_CMS_DRUPAL_DBENGINE" ] ; then
		dbengine $TARGET_CMS_DRUPAL_DBENGINE
	fi
	if [ "$TARGET_CMS_DRUPAL_HTTPD_SCHEME" = "https" ] ; then
		if [[ ! `which ssh` || ! `which sshd` ]] ; then
			sudo apt-get -y install openssh-client openssh-server
		
			# After installation of ssh client/server, I would like to generate
			# new ssh public/private key pair, although the key pair may have
			# been already there for some reason.
			# ssh-keygen -t rsa
			ssh-add
		fi
	fi
	
	# Install minimum packages for PHP5 to run Drupal
	sudo apt-get -y install php5 php5-gd
	case $TARGET_CMS_DRUPAL_HTTPD in
		apache)
			sudo apt-get -y install libapache2-mod-php5
			sudo a2enmod php5
			;;
		*)
			echo
			echo "CMS::Drupal::Error::Invalid httpd type: '$TARGET_CMS_DRUPAL_HTTPD'"
			return
			;;
	esac
	case $TARGET_CMS_DRUPAL_DBENGINE in
		mysql)
			sudo apt-get -y install php5-mysql
			;;
		*)
			echo
			echo "CMS::Drupal::Error::Invalid dbengine type: '$TARGET_CMS_DRUPAL_DBENGINE'"
			return
			;;
	esac
}

cms_drupal_clean()
{
	if [ -z "$TARGET_CMS" ] ; then
		echo 
		echo "CMS::Drupal::Error::TARGET_CMS not set yet"
		return
	fi
	
	echo
	echo "CMS::Drupal::Info::Clean for site[$TARGET_CMS_DRUPAL_SITE]"
	
	case $TARGET_CMS_DRUPAL_DBENGINE in
		mysql)
			local MYSQL MYSQL_HEADER_COMPLEX MYSQL_HEADER_SIMPLE MYSQL_ROOTPW 
			local dbhost dbname dbuser
			MYSQL=(`which mysql`)
			if [ -z "$TARGET_CMS_DRUPAL_MYSQL_DBNAME" ] ; then
				dbname=(`echo -n $TARGET_CMS_DRUPAL_SITE | sed -e "s/\./_/g"`)
				export TARGET_CMS_DRUPAL_MYSQL_DBNAME=$dbname
			else
				dbname=$TARGET_CMS_DRUPAL_MYSQL_DBNAME
			fi
			if [ -z "$TARGET_DBENGINE_MYSQL_ROOTPW" ] ; then
				read -s -p "Enter password for MySQL: " MYSQL_ROOTPW
				export TARGET_DBENGINE_MYSQL_ROOTPW=$MYSQL_ROOTPW
			else
				MYSQL_ROOTPW=$TARGET_DBENGINE_MYSQL_ROOTPW
			fi
			if [ -z "$TARGET_CMS_DRUPAL_MYSQL_DBUSER" ] ; then
				dbuser=drupal
				export TARGET_CMS_DRUPAL_MYSQL_DBUSER=$dbuser
			else
				dbuser=$TARGET_CMS_DRUPAL_MYSQL_DBUSER
			fi
			if [ -z "$TARGET_DBENGINE_MYSQL_HOST" ] ; then
				dbhost=localhost
				TARGET_DBENGINE_MYSQL_HOST=$dbhost
			else
				dbhost=$TARGET_DBENGINE_MYSQL_HOST
			fi
			
			echo 
			echo -n "CMS::Drupal::Info::Clean database[$dbname] for user[$dbuser] in "
			echo "'$TARGET_CMS_DRUPAL_DBENGINE'"
			
			MYSQL_HEADER_COMPLEX="$MYSQL --user=root --password=$MYSQL_ROOTPW --batch --skip-column-names -e"
			MYSQL_HEADER_SIMPLE="$MYSQL --user=root --password=$MYSQL_ROOTPW -e"
			if [ `$MYSQL_HEADER_COMPLEX "SHOW DATABASES LIKE '$dbname';"` ] ; then
				$MYSQL_HEADER_SIMPLE "DROP DATABASE $dbname;"
			fi
			if [ `$MYSQL_HEADER_COMPLEX "SELECT USER FROM mysql.user WHERE user='$dbuser';"` ] ; then
				$MYSQL_HEADER_SIMPLE "DROP USER $dbuser@$dbhost;"
			fi
			;;
		*)
			echo
			echo "CMS::Drupal::Error::Invalid dbengine type: '$TARGET_CMS_DRUPAL_DBENGINE'"
			return
			;;
	esac
			
	case $TARGET_CMS_DRUPAL_HTTPD in
		apache)
			if [ -f /etc/apache2/sites-available/$TARGET_CMS_DRUPAL_SITE ] ; then
				sudo rm /etc/apache2/sites-available/$TARGET_CMS_DRUPAL_SITE
			fi
			if [ -L /etc/apache2/sites-enabled/$TARGET_CMS_DRUPAL_SITE ] ; then
				sudo rm /etc/apache2/sites-enabled/$TARGET_CMS_DRUPAL_SITE
			fi
			;;
		*)
			echo
			echo "CMS::Drupal::Error::Invalid httpd type: '$TARGET_CMS_DRUPAL_HTTPD'"
			return
			;;
	esac
	
	if [ -d /home/www-data/$TARGET_CMS_DRUPAL_SITE ] ; then
		sudo rm -rf /home/www-data/$TARGET_CMS_DRUPAL_SITE
	fi
}

cms_drupal()
{
	if [ -z "$TARGET_CMS" ] ; then
		echo 
		echo "CMS::Drupal::Error::TARGET_CMS not set yet"
		return
	fi
	
	local goal
	for goal in ${TARGET_SITE_GOALS[@]}
	do
		case $goal in
			clean)
				cms_drupal_clean
				;;
			preinstall)
				cms_drupal_preinstall
				;;
			configure)
				cms_drupal_configure
				;;
			install)
				cms_drupal_install
				;;
			postconfig)
				cms_drupal_postconfig
				;;
			custom)
				cms_drupal_custom
				;;
			backup)
				cms_drupal_backup
				;;
			upgrade)
				cms_drupal_upgrade
				;;
			lite)
				cms_drupal_clean
				cms_drupal_preinstall
				cms_drupal_configure
				cms_drupal_install
				;;
			all)
				cms_drupal_clean
				cms_drupal_preinstall
				cms_drupal_configure
				cms_drupal_install
				cms_drupal_postconfig
				cms_drupal_custom
				;;
			*)
				echo
				echo "CMS::Drupal::Error::Invalid target site goal: '$goal'"
				return
				;;
		esac
	done
}
