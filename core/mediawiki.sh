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


cms_mediawiki_upgrade()
{
	if [ -z "$TARGET_CMS" ] ; then
		echo 
		echo "CMS::Mediawiki::Error::TARGET_CMS not set yet"
		return
	fi
	
	echo 
	echo "CMS::Mediawiki::Info::Upgrade for site[$TARGET_CMS_MEDIAWIKI_SITE]"
}

cms_mediawiki_backup()
{
	if [ -z "$TARGET_CMS" ] ; then
		echo 
		echo "CMS::Mediawiki::Error::TARGET_CMS not set yet"
		return
	fi
	
	echo 
	echo "CMS::Mediawiki::Info::Backup for site[$TARGET_CMS_MEDIAWIKI_SITE]"
}

cms_mediawiki_custom()
{
	if [ -z "$TARGET_CMS" ] ; then
		echo 
		echo "CMS::Mediawiki::Error::TARGET_CMS not set yet"
		return
	fi
	
	echo 
	echo "CMS::Mediawiki::Info::Customize for site[$TARGET_CMS_MEDIAWIKI_SITE]"
	
	local cmstop=/home/www-data/$TARGET_CMS_MEDIAWIKI_SITE
	local config=LocalSettings.php
	local updated=false
	if [ ! -f $cmstop/$config ] ; then
		echo 
		echo "CMS::Mediawiki::Error::'$config' not existing yet under '$cmstop'"
		return
	fi
	
	# Set custom logo and favicon
	local image keys
	if [ ! -d $cmstop/images ] ; then
		sudo -u www-data mkdir $cmstop/images
	fi
	image=$TARGET_SITE_CONFIG/mediawiki/$TARGET_CMS_MEDIAWIKI_SITE_LOGO
	if [ -f $image ] ; then
		sudo -u www-data cp $image $cmstop/images
		
		keys=(`grep -e '^\$wgLogo.*$' $cmstop/$config`)
		if [ ! "keys" ] ; then
			sudo -u www-data sed -i -e '/^\$wgScriptPath.*$/a \$wgArticlePath = \"\/\$1\"\;' $cmstop/$config
		else
			sudo -u www-data sed -i -e 's/^\$wgLogo.*$/\$wgLogo = \"\$wgScriptPath\/images\/miing-logo.png\"\;/' $cmstop/$config
		fi
		updated=true
	fi
	image=$TARGET_SITE_CONFIG/mediawiki/$TARGET_CMS_MEDIAWIKI_SITE_FAVICON
	if [ -f $image ] ; then
		sudo -u www-data cp $image $cmstop/images
		
		keys=(`grep -e '^\$wgFavicon.*$' $cmstop/$config`)
		if [ ! "$keys" ] ; then
			sudo -u www-data sed -i -e '/^\$wgLogo.*$/a \$wgFavicon = \"\$wgScriptPath\/images\/favicon.ico\"\;' $cmstop/$config
		else
			sudo -u www-data sed -i -e 's/^\$wgFavicon.*$/\$wgFavicon = \"\$wgScriptPath\/images\/favicon.ico\"\;/' $cmstop/$config
		fi
		updated=true
	fi
	
	# Update settings
	if [ $updated ] ; then
		sudo -u www-data php $cmstop/maintenance/update.php
	fi
}

cms_mediawiki_postconfig()
{
	if [ -z "$TARGET_CMS" ] ; then
		echo 
		echo "CMS::Mediawiki::Error::TARGET_CMS not set yet"
		return
	fi
	
	echo 
	echo "CMS::Mediawiki::Info::Postconfigure for site[$TARGET_CMS_MEDIAWIKI_SITE]"
	
	local cmstop=/home/www-data/$TARGET_CMS_MEDIAWIKI_SITE
	local config=LocalSettings.php
	local updated=false
	if [ ! -f $cmstop/$config ] ; then
		echo 
		echo "CMS::Mediawiki::Error::'$config' not existing yet under '$cmstop'"
		return
	fi
	
	# Setup local settings to fit your needs
	if [ -f $TARGET_SITE_CONFIG/mediawiki/$config ] ; then
		local secret_key upgrade_key
		secret_key="`grep -e '^\$wgSecretKey.*$' $cmstop/$config`"
		upgrade_key="`grep -e '^\$wgUpgradeKey.*$' $cmstop/$config`"
	
		sudo -u www-data cp $TARGET_SITE_CONFIG/mediawiki/$config $cmstop
		
		if [ "$secret_key" ] ; then
			sudo -u www-data sed -i -e "s/^\$wgSecretKey.*$/$secret_key/" $cmstop/$config
		fi
		if [ "$upgrade_key" ] ; then
			sudo -u www-data sed -i -e "s/^\$wgUpgradeKey.*$/$upgrade_key/" $cmstop/$config
		fi
		
		updated=true
	fi
	
	# Short URL
#	local keys
#	keys=(`grep -e '^\$wgArticlePath.*$' $cmstop/$config`)
#	if [ ! "$keys" ] ; then
#		sudo -u www-data sed -i -e '/^\$wgScriptPath.*$/a \$wgArticlePath = \"\/\$1\"\;' $cmstop/$config
#		updated=true
#	else
#		sudo -u www-data sed -i -e 's/^\$wgArticlePath.*$/\$wgArticlePath = \"\/\$1\"\;/' $cmstop/$config
#		updated=true
#	fi
#	keys=(`grep -e '^\$wgUsePathInfo.*$' $cmstop/$config`)
#	if [ ! "$keys" ] ; then
#		sudo -u www-data sed -i -e '/^\$wgArticlePath.*$/a \$wgUsePathInfo = true\;' $cmstop/$config
#		updated=true
#	else
#		sudo -u www-data sed -i -e 's/^\$wgUsePathInfo.*$/\$wgUsePathInfo = true\;/' $cmstop/$config
#		updated=true
#	fi
	
	# Math
#	wget https://nodeload.github.com/wikimedia/mediawiki-extensions-Math/legacy.tar.gz/REL1_20
#	tar -xzf wikimedia-mediawiki-extensions-Math-a998a49.tar.gz -C /var/www/mediawiki/extensions
#	
#	sudo apt-get -y install imagemagick
#	sudo apt-get -y install ocaml make texlive cjk-latex

	# OpenID
	if [ "$TARGET_CMS_MEDIAWIKI_SITE_AUTH" = "openid" ] ; then
		if [ ! -d $cmstop/extensions/OpenID ] ; then
			local download_url=https://gerrit.wikimedia.org/r/p/mediawiki/extensions/OpenID.git
			sudo -u www-data git clone $download_url $cmstop/extensions/OpenID
			download_url=git://github.com/openid/php-openid.git
			sudo -u www-data git clone $download_url $cmstop/extensions/OpenID/php-openid
			sudo -u www-data mv $cmstop/extensions/OpenID/php-openid/Auth/ $cmstop/extensions/OpenID/Auth
			sudo -u www-data rm -rf $cmstop/extensions/OpenID/php-openid
		
			# Enable OpenID
			local keys=(`grep -e "OpenID.php" $cmstop/$config`)
			if [ ! "$keys" ] ; then
				sudo -u www-data sed -i -e '$ a\require_once\( \"\$IP\/extensions\/OpenID\/OpenID.php\" \)\;' $cmstop/$config
				updated=true
			fi
		fi
	fi
	
	# Update settings
	if [ $updated ] ; then
		sudo -u www-data php $cmstop/maintenance/update.php
	fi
}

cms_mediawiki_install()
{
	if [ -z "$TARGET_CMS" ] ; then
		echo 
		echo "CMS::Mediawiki::Error::TARGET_CMS not set yet"
		return
	fi
	
	echo 
	echo "CMS::Mediawiki::Info::Install for site[$TARGET_CMS_MEDIAWIKI_SITE]"
	
	local cmstop=/home/www-data/$TARGET_CMS_MEDIAWIKI_SITE
	local config=LocalSettings.php
	if [ ! -d $cmstop ] ; then
		sudo -u www-data mkdir $cmstop
	fi
	# Pick up the latest stable version of Mediawiki 
	# from http://www.mediawiki.org/wiki/Download,
	# or from http://download.wikimedia.org/mediawiki/
	if [ ! -f $cmstop/$config ] ; then
		local download_url=http://download.wikimedia.org/mediawiki
		local full_version=$TARGET_CMS_MEDIAWIKI_VERSION_INSTALLED
		local main_version=(`echo -n $full_version | sed -e "s/\(^[0-9]*\.[0-9]*\).*/\1/"`)
		local stable=mediawiki-$full_version.tar.gz
		sudo -u www-data wget -P $cmstop $download_url/$main_version/$stable
		sudo -u www-data tar xzvf $cmstop/$stable -C $cmstop
		sudo -u www-data mv $cmstop/mediawiki-$full_version/* $cmstop
		sudo -u www-data rm -rf $cmstop/mediawiki-$full_version
		sudo -u www-data rm $cmstop/$stable
		
		local OPTIONS ARGUMENTS params_all_available=true
		local dbengine_host dbengine_rootpw
		OPTIONS="--server $TARGET_CMS_MEDIAWIKI_HTTPD_SCHEME://$TARGET_CMS_MEDIAWIKI_SITE"
		#OPTIONS="$OPTIONS --scriptpath ''"
		OPTIONS="$OPTIONS --confpath $cmstop"
		if [ "$TARGET_CMS_MEDIAWIKI_DBENGINE" ] ; then
			OPTIONS="$OPTIONS --dbtype $TARGET_CMS_MEDIAWIKI_DBENGINE"
		else
			params_all_available=false
		fi
		if [ "$TARGET_CMS_MEDIAWIKI_DBENGINE" = "mysql" ] ; then
			dbengine_host=$TARGET_DBENGINE_MYSQL_HOST
			dbengine_rootpw=$TARGET_DBENGINE_MYSQL_ROOTPW
		elif [ "$TARGET_CMS_MEDIAWIKI_DBENGINE" = "postgresql" ] ; then
			dbengine_host=$TARGET_DBENGINE_PGSQL_HOST
			dbengine_rootpw=$TARGET_DBENGINE_PGSQL_ROOTPW
		fi
		if [ "$dbengine_host" ] ; then
			OPTIONS="$OPTIONS --dbserver $dbengine_host"
		else
			params_all_available=false
		fi
		if [ "$TARGET_CMS_MEDIAWIKI_DBENGINE_DBNAME" ] ; then
			OPTIONS="$OPTIONS --dbname $TARGET_CMS_MEDIAWIKI_DBENGINE_DBNAME"
		else
			params_all_available=false
		fi
		if [ "$TARGET_CMS_MEDIAWIKI_DBENGINE_DBUSER" ] ; then
			OPTIONS="$OPTIONS --dbuser $TARGET_CMS_MEDIAWIKI_DBENGINE_DBUSER"
		else
			params_all_available=false
		fi
		if [ "$TARGET_CMS_MEDIAWIKI_DBENGINE_DBPW" ] ; then
			OPTIONS="$OPTIONS --dbpass $TARGET_CMS_MEDIAWIKI_DBENGINE_DBPW"
		else
			params_all_available=false
		fi
		if [ "$TARGET_CMS_MEDIAWIKI_SITE_ADMIN_PASSWORD" ] ; then
			OPTIONS="$OPTIONS --pass $TARGET_CMS_MEDIAWIKI_SITE_ADMIN_PASSWORD"
		else
			params_all_available=false
		fi
		if [ "$TARGET_CMS_MEDIAWIKI_SITE_NAME" -a "$TARGET_CMS_MEDIAWIKI_SITE_ADMIN" ] ; then
			ARGUMENTS="$TARGET_CMS_MEDIAWIKI_SITE_NAME $TARGET_CMS_MEDIAWIKI_SITE_ADMIN"
		else
			params_all_available=false
		fi
		if [ $params_all_available ] ; then
			sudo -u www-data php $cmstop/maintenance/install.php $OPTIONS --scriptpath "" $ARGUMENTS
		else
			echo 
			echo "CMS::Mediawiki::Error::Too few parameters given"
			return
		fi
	fi
}

cms_mediawiki_configure()
{
	if [ -z "$TARGET_CMS" ] ; then
		echo 
		echo "CMS::Mediawiki::Error::TARGET_CMS not set yet"
		return
	fi
	
	echo 
	echo "CMS::Mediawiki::Info::Configure for site[$TARGET_CMS_MEDIAWIKI_SITE]"
	
	case $TARGET_CMS_MEDIAWIKI_DBENGINE in
		mysql)
			local MYSQL MYSQL_HEADER MYSQL_ROOTPW
			local dbhost dbname dbuser dbpw
			MYSQL=(`which mysql`)
			
			# Create a new database via mysql for Mediawiki use which is named 
			# after by means of this variable,TARGET_CMS_MEDIAWIKI_SITE. Let's say,
			# this name of the database would be wiki_mci_org if this value of
			# the variable is wiki.mci.org.
			if [ -z "$TARGET_CMS_MEDIAWIKI_DBENGINE_DBNAME" ] ; then
				dbname=(`echo -n $TARGET_CMS_MEDIAWIKI_SITE | sed -e "s/\./_/g"`)
				export TARGET_CMS_MEDIAWIKI_DBENGINE_DBNAME=$dbname
			else
				dbname=$TARGET_CMS_MEDIAWIKI_DBENGINE_DBNAME
			fi
			if [ -z "$TARGET_DBENGINE_MYSQL_ROOTPW" ] ; then
				read -s -p "Enter password for MySQL: " MYSQL_ROOTPW
				export TARGET_DBENGINE_MYSQL_ROOTPW=$MYSQL_ROOTPW
			else
				MYSQL_ROOTPW=$TARGET_DBENGINE_MYSQL_ROOTPW
			fi
			MYSQL_HEADER="$MYSQL --user=root --password=$MYSQL_ROOTPW --batch --skip-column-names -e"
			if [ ! `$MYSQL_HEADER "SHOW DATABASES LIKE '$dbname';"` ] ; then
				if [ -z "$TARGET_CMS_MEDIAWIKI_DBENGINE_DBPW" ] ; then
					read -s -p "Enter password for 'Mediawiki' database: " dbpw
				else
					dbpw=$TARGET_CMS_MEDIAWIKI_DBENGINE_DBPW
				fi
				if [ -z "$TARGET_CMS_MEDIAWIKI_DBENGINE_DBUSER" ] ; then
					dbuser=mediawiki
					export TARGET_CMS_MEDIAWIKI_DBENGINE_DBUSER=$dbuser
				else
					dbuser=$TARGET_CMS_MEDIAWIKI_DBENGINE_DBUSER
				fi
				if [ -z "$TARGET_DBENGINE_MYSQL_HOST" ] ; then
					dbhost=localhost
					export TARGET_DBENGINE_MYSQL_HOST=$dbhost
				else
					dbhost=$TARGET_DBENGINE_MYSQL_HOST
				fi
				
				echo 
				echo -n "CMS::Mediawiki::Info::Create database[$dbname] for user[$dbuser] in "
				echo "'$TARGET_CMS_MEDIAWIKI_DBENGINE'"
				
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
			echo "CMS::Mediawiki::Error::Invalid dbengine type: '$TARGET_CMS_MEDIAWIKI_DBENGINE'"
			return
			;;
	esac
	
	# Adjust parameters in php.ini to fit your needs when running Mediawiki
	local phpconfig=/etc/php5/apache2/php.ini
	if [ -f "$phpconfig" ] ; then
		local threshold=32 #32M used as the minimum for size of file upload
		local defsize=(`grep -e "^upload_max_filesize" $phpconfig | sed -e "s/[^0-9]//g"`)
		if [ "$defsize" -lt "$threshold" ] ; then
			sudo sed -i -e "s/\(^upload_max_filesize = \).*/\132M/" $phpconfig
		fi
		
		defsize=(`grep -e "^memory_limit" $phpconfig | sed -e "s/[^0-9]//g"`)
		if [ "$defsize" -lt "$threshold" ] ; then
			sudo sed -i -e "s/\(^memory_limit = \).*/\132M/" $phpconfig
		fi
		
		case $TARGET_CMS_MEDIAWIKI_DBENGINE in
			mysql)
				local keys=(`grep -e "^extension=mysql.so" $phpconfig`)
				if [ ! "$keys" ] ; then
					local line=(`cat $phpconfig | grep -n "^\; Dynamic Extensions \;" | grep -o "^[0-9]*"`)
					line=$((line+2))
					sudo sed -i -e "$line i\extension=mysql.so" $phpconfig
				fi
				;;
			*)
				echo
				echo "CMS::Mediawiki::Error::Invalid dbengine type: '$TARGET_CMS_MEDIAWIKI_DBENGINE'"
				return
				;;
		esac				
	fi
	
	case $TARGET_CMS_MEDIAWIKI_HTTPD in
		apache)
			local vhconfig keys
			
			case $TARGET_CMS_MEDIAWIKI_HTTPD_SCHEME in
				http)
					sudo a2enmod rewrite
					
					if [ ! -f /etc/apache2/sites-available/$TARGET_CMS_MEDIAWIKI_SITE ] ; then
						# Configure virtualhost
						vhconfig=$TARGET_CMS_MEDIAWIKI_SITE.$TARGET_CMS_MEDIAWIKI_HTTPD_SCHEME
						if [ -f $TARGET_SITE_CONFIG/mediawiki/$vhconfig ] ; then
							sudo cp $TARGET_SITE_CONFIG/mediawiki/$vhconfig /etc/apache2/sites-available/$TARGET_CMS_MEDIAWIKI_SITE
						else
							echo
							echo "CMS::Mediawiki::Error::No virtualhost with '$TARGET_CMS_MEDIAWIKI_HTTPD_SCHEME' on $TARGET_CMS_MEDIAWIKI_HTTPD"
							return
						fi
		
						# Enable virtualhost at port 443 for ssl
						keys=(`grep "^[[:space:]]NameVirtualHost \*:443" /etc/apache2/ports.conf`)
						if [ ! "$keys" ] ; then
							sudo sed -i -e "/^<IfModule mod_ssl.c>.*/a\\\tNameVirtualHost \*:443" /etc/apache2/ports.conf
						fi
						
						# Match host names with IP address
						keys=(`cat /etc/hosts | grep -i -e "^[0-9\.]*[[:space:]]*$TARGET_CMS_MEDIAWIKI_SITE"`)
						if [ ! "$keys" ] ; then
							sudo bash -c "cat >>/etc/hosts <<EOF
$TARGET_CMS_MEDIAWIKI_HTTPD_IPADDR $TARGET_CMS_MEDIAWIKI_SITE
EOF"
						fi
					
						# Make virtualhost take effect
						sudo a2ensite $TARGET_CMS_MEDIAWIKI_SITE
						sudo a2dissite default
						sudo /etc/init.d/apache2 restart
					fi
					;;
				https)
					sudo a2enmod ssl rewrite
					
					if [ ! -f /etc/apache2/sites-available/$TARGET_CMS_MEDIAWIKI_SITE ] ; then
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
						vhconfig=$TARGET_CMS_MEDIAWIKI_SITE.$TARGET_CMS_MEDIAWIKI_HTTPD_SCHEME
						if [ -f $TARGET_SITE_CONFIG/mediawiki/$vhconfig ] ; then
							sudo cp $TARGET_SITE_CONFIG/mediawiki/$vhconfig /etc/apache2/sites-available/$TARGET_CMS_MEDIAWIKI_SITE
						else
							echo
							echo "CMS::Mediawiki::Error::No virtualhost with '$TARGET_CMS_MEDIAWIKI_HTTPD_SCHEME' on $TARGET_CMS_MEDIAWIKI_HTTPD"
							return
						fi
		
						# Enable virtualhost at port 443 for ssl
						keys=(`grep "^[[:space:]]NameVirtualHost \*:443" /etc/apache2/ports.conf`)
						if [ ! "$keys" ] ; then
							sudo sed -i -e "/^<IfModule mod_ssl.c>.*/a\\\tNameVirtualHost \*:443" /etc/apache2/ports.conf
						fi
						
						# Match host names with IP address
						keys=(`cat /etc/hosts | grep -i -e "^[0-9\.]*[[:space:]]*$TARGET_CMS_MEDIAWIKI_SITE"`)
						if [ ! "$keys" ] ; then
							sudo bash -c "cat >>/etc/hosts <<EOF
$TARGET_CMS_MEDIAWIKI_HTTPD_IPADDR $TARGET_CMS_MEDIAWIKI_SITE
EOF"
						fi
					
						# Make virtualhost take effect
						sudo a2ensite $TARGET_CMS_MEDIAWIKI_SITE
						sudo a2dissite default
						sudo /etc/init.d/apache2 restart
					fi
					;;
				*)
					echo 
					echo "CMS::Mediawiki::Error:: Invalid httpd scheme: '$TARGET_CMS_MEDIAWIKI_HTTPD_SCHEME'"
					return
					;;
			esac
			;;
		*)
			echo
			echo "CMS::Mediawiki::Error::Invalid httpd type: '$TARGET_CMS_MEDIAWIKI_HTTPD'"
			return
			;;
	esac
}

cms_mediawiki_preinstall()
{
	if [ -z "$TARGET_CMS" ] ; then
		echo 
		echo "CMS::Mediawiki::Error::TARGET_CMS not set yet"
		return
	fi
	
	echo 
	echo "CMS::Mediawiki::Info::Preinstall for site[$TARGET_CMS_MEDIAWIKI_SITE]"
	
	if [ -n "$TARGET_CMS_MEDIAWIKI_HTTPD" ] ; then
		httpd $TARGET_CMS_MEDIAWIKI_HTTPD
	fi
	if [ -n "$TARGET_CMS_MEDIAWIKI_DBENGINE" ] ; then
		dbengine $TARGET_CMS_MEDIAWIKI_DBENGINE
	fi
	if [ "$TARGET_CMS_MEDIAWIKI_HTTPD_SCHEME" = "https" ] ; then
		if [[ ! `which ssh` || ! `which sshd` ]] ; then
			sudo apt-get -y install openssh-client openssh-server
		
			# After installation of ssh client/server, I would like to generate
			# new ssh public/private key pair, although the key pair may have
			# been already there for some reason.
			# ssh-keygen -t rsa
			ssh-add
		fi
	fi
	
	# Install minimum packages for PHP5 to run Mediawiki
	sudo apt-get -y install php5
	case $TARGET_CMS_MEDIAWIKI_HTTPD in
		apache)
			sudo apt-get -y install libapache2-mod-php5
			sudo a2enmod php5
			;;
		*)
			echo
			echo "CMS::Mediawiki::Error::Invalid httpd type: '$TARGET_CMS_MEDIAWIKI_HTTPD'"
			return
			;;
	esac
	case $TARGET_CMS_MEDIAWIKI_DBENGINE in
		mysql)
			sudo apt-get -y install php5-mysql
			;;
		*)
			echo
			echo "CMS::Mediawiki::Error::Invalid dbengine type: '$TARGET_CMS_MEDIAWIKI_DBENGINE'"
			return
			;;
	esac
	sudo apt-get -y install php-pear php5-cli php5-intl
}

cms_mediawiki_clean()
{
	if [ -z "$TARGET_CMS" ] ; then
		echo 
		echo "CMS::Mediawiki::Error::TARGET_CMS not set yet"
		return
	fi
	
	echo
	echo "CMS::Mediawiki::Info::Clean for site[$TARGET_CMS_MEDIAWIKI_SITE]"
	
	case $TARGET_CMS_MEDIAWIKI_DBENGINE in
		mysql)
			local MYSQL MYSQL_HEADER_COMPLEX MYSQL_HEADER_SIMPLE MYSQL_ROOTPW 
			local dbhost dbname dbuser
			MYSQL=(`which mysql`)
			
			if [ -z $TARGET_CMS_MEDIAWIKI_MYSQL_DBNAME ] ; then
				dbname=(`echo -n $TARGET_CMS_MEDIAWIKI_SITE | sed -e "s/\./_/g"`)
				export TARGET_CMS_MEDIAWIKI_MYSQL_DBNAME=$dbname
			else
				dbname=$TARGET_CMS_MEDIAWIKI_MYSQL_DBNAME
			fi
			if [ -z "$TARGET_DBENGINE_MYSQL_ROOTPW" ] ; then
				read -s -p "Enter password for MySQL: " MYSQL_ROOTPW
				export TARGET_DBENGINE_MYSQL_ROOTPW=$MYSQL_ROOTPW
			else
				MYSQL_ROOTPW=$TARGET_DBENGINE_MYSQL_ROOTPW
			fi
			if [ -z "$TARGET_CMS_MEDIAWIKI_MYSQL_DBUSER" ] ; then
				dbuser=mediawiki
				export TARGET_CMS_MEDIAWIKI_MYSQL_DBUSER=$dbuser
			else
				dbuser=$TARGET_CMS_MEDIAWIKI_MYSQL_DBUSER
			fi
			if [ -z "$TARGET_DBENGINE_MYSQL_HOST" ] ; then
				dbhost=localhost
				TARGET_DBENGINE_MYSQL_HOST=$dbhost
			else
				dbhost=$TARGET_DBENGINE_MYSQL_HOST
			fi
			
			echo 
			echo -n "CMS::Mediawiki::Info::Clean database[$dbname] for user[$dbuser] in "
			echo "'$TARGET_CMS_MEDIAWIKI_DBENGINE'"
			
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
			echo "CMS::Mediawiki::Error::Invalid dbengine type: '$TARGET_CMS_MEDIAWIKI_DBENGINE'"
			return
			;;
	esac
			
	case $TARGET_CMS_MEDIAWIKI_HTTPD in
		apache)
			if [ -f /etc/apache2/sites-available/$TARGET_CMS_MEDIAWIKI_SITE ] ; then
				sudo rm /etc/apache2/sites-available/$TARGET_CMS_MEDIAWIKI_SITE
			fi
			if [ -L /etc/apache2/sites-enabled/$TARGET_CMS_MEDIAWIKI_SITE ] ; then
				sudo rm /etc/apache2/sites-enabled/$TARGET_CMS_MEDIAWIKI_SITE
			fi
			;;
		*)
			echo
			echo "CMS::Mediawiki::Error::Invalid httpd type: '$TARGET_CMS_MEDIAWIKI_HTTPD'"
			return
			;;
	esac
	
	if [ -d /home/www-data/$TARGET_CMS_MEDIAWIKI_SITE ] ; then
		sudo rm -rf /home/www-data/$TARGET_CMS_MEDIAWIKI_SITE
	fi
}

cms_mediawiki()
{
	if [ -z "$TARGET_CMS" ] ; then
		echo 
		echo "CMS::Mediawiki::Error::TARGET_CMS not set yet"
		return
	fi
	
	local goal
	for goal in ${TARGET_SITE_GOALS[@]}
	do
		case $goal in
			clean)
				cms_mediawiki_clean
				;;
			preinstall)
				cms_mediawiki_preinstall
				;;
			configure)
				cms_mediawiki_configure
				;;
			install)
				cms_mediawiki_install
				;;
			postconfig)
				cms_mediawiki_postconfig
				;;
			custom)
				cms_mediawiki_custom
				;;
			backup)
				cms_mediawiki_backup
				;;
			upgrade)
				cms_mediawiki_upgrade
				;;
			lite)
				cms_mediawiki_clean
				cms_mediawiki_preinstall
				cms_mediawiki_configure
				cms_mediawiki_install
				;;
			all)
				cms_mediawiki_clean
				cms_mediawiki_preinstall
				cms_mediawiki_configure
				cms_mediawiki_install
				cms_mediawiki_postconfig
				cms_mediawiki_custom
				;;
			*)
				echo
				echo "CMS::Mediawiki::Error::Invalid target site goal: '$goal'"
				return
				;;
		esac
	done
}
