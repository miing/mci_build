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


its_bugzilla_upgrade()
{
	if [ -z "$TARGET_ITS" ] ; then
		echo 
		echo "ITS::Bugzilla::Error::TARGET_ITS not set yet"
		return
	fi
	
	echo
	echo "ITS::Bugzilla::Info::Updgrade for site[$TARGET_ITS_BUGZILLA_SITE]"
}

its_bugzilla_backup()
{
	if [ -z "$TARGET_ITS" ] ; then
		echo 
		echo "ITS::Bugzilla::Error::TARGET_ITS not set yet"
		return
	fi
	
	echo
	echo "ITS::Bugzilla::Info::Backup for site[$TARGET_ITS_BUGZILLA_SITE]"
}

its_bugzilla_custom()
{
	if [ -z "$TARGET_ITS" ] ; then
		echo 
		echo "ITS::Bugzilla::Error::TARGET_ITS not set yet"
		return
	fi
	
	echo
	echo "ITS::Bugzilla::Info::Customize for site[$TARGET_ITS_BUGZILLA_SITE]"
}

its_bugzilla_postconfig()
{
	if [ -z "$TARGET_ITS" ] ; then
		echo 
		echo "ITS::Bugzilla::Error::TARGET_ITS not set yet"
		return
	fi
	
	echo
	echo "ITS::Bugzilla::Info::Postconfigure for site[$TARGET_ITS_BUGZILLA_SITE]"
	
	local itstop=/home/www-data/$TARGET_ITS_BUGZILLA_SITE
	local config=localconfig 
	local updated=false
	sudo chmod -R a+rx $itstop
	cd $itstop
	if [ ! -f $itstop/$config ] ; then
		echo 
		echo "ITS::Bugzilla::Error::'$config' not existing yet under '$itstop'"
		return
	fi
	
	local SED SED_HEADER PERL PERL_HEADER
	SED=(`which sed`)
	SED_HEADER="sudo -u www-data $SED -i -e"
	PERL=(`which perl`)
	PERL_HEADER="sudo -u www-data $PERL"
	
	# SMTP
	
	# OpenID
	if [ "$TARGET_ITS_BUGZILLA_SITE_AUTH" = "openid" ] ; then
		if [ ! -d $MCITOP/extentions/bugzilla/OpenID ] ; then
			local url=git://github.com/miing/mci_extensions_bugzilla_openid.git
			sudo -u www-data git clone $url $itstop/extensions/OpenID
		else
			sudo -u www-data cp -rf extentions/bugzilla/OpenID $itstop/extensions/OpenID
		fi
		
		updated=true
	fi
	
	if [ $updated ] ; then 
		# Check if all modules required are installed 
		$PERL_HEADER $itstop/checksetup.pl --check-modules
		
		# Install all modules including necessary and optional
		$PERL_HEADER $itstop/install-module.pl --all
	fi
	# Update localconfig file in $itstop as well as modify permissions under $itstop
	$PERL_HEADER $itstop/checksetup.pl
	
	# After installing Bugzilla, we would prefer to go back to
	# the top of the whole project in order to make the subsequent parts of 
	# installation straightforward.
	mcitop
}

its_bugzilla_install()
{
	if [ -z "$TARGET_ITS" ] ; then
		echo 
		echo "ITS::Bugzilla::Error::TARGET_ITS not set yet"
		return
	fi
	
	echo 
	echo "ITS::Bugzilla::Info::Install for site[$TARGET_ITS_BUGZILLA_SITE]"
	
	if [ ! -d /home/www-data/$TARGET_ITS_BUGZILLA_SITE ] ; then
		sudo -u www-data mkdir /home/www-data/$TARGET_ITS_BUGZILLA_SITE
	fi
	
	local itstop=/home/www-data/$TARGET_ITS_BUGZILLA_SITE
	local config=localconfig localcfg=local.cfg
	local keys
	cd $itstop
	if [ ! -f $itstop/$config ] ; then
		# Pick up the latest stable version of bugzilla 
		# from http://www.bugzilla.org/download/#stable,
		# or from http://ftp.mozilla.org/pub/mozilla.org/webtools
		local url=http://ftp.mozilla.org/pub/mozilla.org/webtools
		local version=$TARGET_ITS_BUGZILLA_VERSION_INSTALLED
		local stable=bugzilla-$version.tar.gz
		sudo -u www-data wget -P $itstop $url/$stable
		sudo -u www-data tar xzvf $itstop/$stable -C $itstop
		sudo -u www-data mv $itstop/bugzilla-$version/* $itstop/
		sudo -u www-data mv $itstop/bugzilla-$version/.htaccess $itstop/
		sudo -u www-data rm -rf $itstop/bugzilla-$version
		sudo -u www-data rm $itstop/$stable
	
		local PERL PERL_HEADER SED SED_HEADER
		PERL=(`which perl`)
		PERL_HEADER="sudo -u www-data $PERL"
		SED=(`which sed`)
		SED_HEADER="sudo -u www-data $SED"
		
		# Check if all modules required are installed 
		$PERL_HEADER $itstop/checksetup.pl --check-modules
		
		# Install all modules including necessary and optional
		$PERL_HEADER $itstop/install-module.pl --all
		 	
		# Check if non-interactive mode is used for installation on bugzilla
		local no_interactive_mode=false
		if [ -f $MCITOP/$TARGET_SITE_CONFIG/bugzilla/$localcfg ] ; then
			keys=$($SED_HEADER -n "s/^\$answer{'NO_PAUSE'} = \([0-9]\).*/\1/p" $MCITOP/$TARGET_SITE_CONFIG/bugzilla/$localcfg)
			
			if [ "$keys" = "1" ] ; then
				no_interactive_mode=true
			fi
		fi
		
		if [ $no_interactive_mode ] ; then
			# Non-interactive mode
			local params_all_available=true
			local httpd_owner dbengine_host dbengine_port dbengine_rootpw baseurl
			
			sudo -u www-data cp $MCITOP/$TARGET_SITE_CONFIG/bugzilla/$localcfg .$localcfg
			if [ "$TARGET_ITS_BUGZILLA_HTTPD" = "apache" ] ; then
				httpd_owner=$TARGET_HTTPD_APACHE_OWNER
			fi
			if [ "$httpd_owner" ] ; then
				$SED_HEADER -i -e "s/\(^\$answer{'webservergroup'}\).*/\1 = '$httpd_owner'\;/" .$localcfg
			else
				params_all_available=false
			fi
			if [ "$TARGET_ITS_BUGZILLA_DBENGINE" ] ; then
				$SED_HEADER -i -e "s/\(^\$answer{'db_driver'}\).*/\1 = '$TARGET_ITS_BUGZILLA_DBENGINE'\;/" .$localcfg
			else
				params_all_available=false
			fi
			if [ "$TARGET_ITS_BUGZILLA_DBENGINE" = "mysql" ] ; then
				dbengine_host=$TARGET_DBENGINE_MYSQL_HOST
				dbengine_port=$TARGET_DBENGINE_MYSQL_PORT
				dbengine_rootpw=$TARGET_DBENGINE_MYSQL_ROOTPW
			elif [ "$TARGET_ITS_BUGZILLA_DBENGINE" = "postgresql" ] ; then
				dbengine_host=$TARGET_DBENGINE_PGSQL_HOST
				dbengine_port=$TARGET_DBENGINE_PGSQL_PORT
				dbengine_rootpw=$TARGET_DBENGINE_PGSQL_ROOTPW
			fi
			if [ "$dbengine_host" ] ; then
				$SED_HEADER -i -e "s/\(^\$answer{'db_host'}\).*/\1 = '$dbengine_host'\;/" .$localcfg
			else
				params_all_available=false
			fi
			if [ "$dbengine_port" ] ; then
				if [ "$dbengine_port" = "3306" -o "$dbengine_port" = "5432" ] ; then
					# Set db_port to 0, if database engine port is default value.
					$SED_HEADER -i -e "s/\(^\$answer{'db_port'}\).*/\1 = 0\;/" .$localcfg
				else
					# Set db_port to $dbengine_port, if database engine port is changed.
					$SED_HEADER -i -e "s/\(^\$answer{'db_port'}\).*/\1 = $dbengine_port\;/" .$localcfg
				fi
			else
				params_all_available=false
			fi
			if [ "$TARGET_ITS_BUGZILLA_DBENGINE_DBNAME" ] ; then
				$SED_HEADER -i -e "s/\(^\$answer{'db_name'}\).*/\1 = '$TARGET_ITS_BUGZILLA_DBENGINE_DBNAME'\;/" .$localcfg
			else
				params_all_available=false
			fi
			if [ "$TARGET_ITS_BUGZILLA_DBENGINE_DBUSER" ] ; then
				$SED_HEADER -i -e "s/\(^\$answer{'db_user'}\).*/\1 = '$TARGET_ITS_BUGZILLA_DBENGINE_DBUSER'\;/" .$localcfg
			else
				params_all_available=false
			fi
			if [ "$TARGET_ITS_BUGZILLA_DBENGINE_DBPW" ] ; then
				$SED_HEADER -i -e "s/\(^\$answer{'db_pass'}\).*/\1 = '$TARGET_ITS_BUGZILLA_DBENGINE_DBPW'\;/" .$localcfg
			else
				params_all_available=false
			fi
			if [ "$TARGET_ITS_BUGZILLA_SITE" -a "$TARGET_ITS_BUGZILLA_HTTPD_SCHEME" ] ; then
				baseurl=$TARGET_ITS_BUGZILLA_HTTPD_SCHEME://$TARGET_ITS_BUGZILLA_SITE
				baseurl=(`echo $baseurl | sed -e 's/\//\\\\\//g'`)
				$SED_HEADER -i -e "s/\(^\$answer{'urlbase'}\).*/\1 = '$baseurl'\;/" .$localcfg
			else
				params_all_available=false
			fi
			if [ "$TARGET_ITS_BUGZILLA_SITE_ADMIN_EMAIL" ] ; then
				$SED_HEADER -i -e "s/\(^\$answer{'ADMIN_EMAIL'}\).*/\1 = '$TARGET_ITS_BUGZILLA_SITE_ADMIN_EMAIL'\;/" .$localcfg
			else
				params_all_available=false
			fi
			if [ "$TARGET_ITS_BUGZILLA_SITE_ADMIN_PASSWORD" ] ; then
				$SED_HEADER -i -e "s/\(^\$answer{'ADMIN_PASSWORD'}\).*/\1 = '$TARGET_ITS_BUGZILLA_SITE_ADMIN_PASSWORD'\;/" .$localcfg
			else
				params_all_available=false
			fi
			if [ "$TARGET_ITS_BUGZILLA_SITE_ADMIN_REALNAME" ] ; then
				$SED_HEADER -i -e "s/\(^\$answer{'ADMIN_REALNAME'}\).*/\1 = '$TARGET_ITS_BUGZILLA_SITE_ADMIN_REALNAME'\;/" .$localcfg
			else
				params_all_available=false
			fi
			if [ "$TARGET_ITS_BUGZILLA_SITE_SMTP_SERVER" ] ; then
				$SED_HEADER -i -e "s/\(^\$answer{'SMTP_SERVER'}\).*/\1 = '$TARGET_ITS_BUGZILLA_SITE_SMTP_SERVER'\;/" .$localcfg
			else
				params_all_available=false
			fi
			
			if [ $params_all_available ] ; then
				
				$PERL_HEADER $itstop/checksetup.pl .$localcfg
				$PERL_HEADER $itstop/checksetup.pl .$localcfg
				
				sudo -u www-data rm .$localcfg
			else
				echo 
				echo "ITS::Bugzilla::Error::Too few parameters given"
				return
			fi
		else
			# Interactive Mode: prompt you to input admin email/name/password
			$PERL_HEADER $itstop/checksetup.pl
			$PERL_HEADER $itstop/checksetup.pl
		fi
	fi
	
	# After installing Bugzilla, we would prefer to go back to
	# the top of the whole project in order to make the subsequent parts of 
	# installation straightforward.
	mcitop
}

its_bugzilla_configure()
{
	if [ -z "$TARGET_ITS" ] ; then
		echo 
		echo "ITS::Bugzilla::Error::TARGET_ITS not set yet"
		return
	fi
	
	echo 
	echo "ITS::Bugzilla::Info::Configure for site[$TARGET_ITS_BUGZILLA_SITE]"
	
	case $TARGET_ITS_BUGZILLA_DBENGINE in
		mysql)
			# Create a new database via mysql for Bugzilla use which is named 
			# after by means of this variable,TARGET_ITS_BUGZILLA_SITE. Let's say,
			# this name of the database would be bugs_mci_org if this value of
			# the variable is bugs.mci.org.
			local MYSQL MYSQL_HEADER MYSQL_ROOTPW 
			local dbhost dbname dbuser dbpw
			MYSQL=(`which mysql`)
			
			if [ -z $TARGET_ITS_BUGZILLA_DBENGINE_DBNAME ] ; then
				dbname=(`echo -n $TARGET_ITS_BUGZILLA_SITE | sed -e "s/\./_/g"`)
				TARGET_ITS_BUGZILLA_DBENGINE_DBNAME=$dbname
			else
				dbname=$TARGET_ITS_BUGZILLA_DBENGINE_DBNAME
			fi
			if [ -z "$TARGET_DBENGINE_MYSQL_ROOTPW" ] ; then
				read -s -p "Enter password for MySQL: " MYSQL_ROOTPW
				TARGET_DBENGINE_MYSQL_ROOTPW=$MYSQL_ROOTPW
			else
				MYSQL_ROOTPW=$TARGET_DBENGINE_MYSQL_ROOTPW
			fi
			MYSQL_HEADER="$MYSQL --user=root --password=$MYSQL_ROOTPW --batch --skip-column-names -e"
			if [ ! `$MYSQL_HEADER "SHOW DATABASES LIKE '$dbname';"` ] ; then
				if [ -z "$TARGET_ITS_BUGZILLA_DBENGINE_DBPW" ] ; then
					read -s -p "Enter password for 'Bugzilla' database: " dbpw
				else
					dbpw=$TARGET_ITS_BUGZILLA_DBENGINE_DBPW
				fi
				if [ -z "$TARGET_ITS_BUGZILLA_DBENGINE_DBUSER" ] ; then
					dbuser=bugzilla
					TARGET_ITS_BUGZILLA_DBENGINE_DBUSER=$dbuser
				else
					dbuser=$TARGET_ITS_BUGZILLA_DBENGINE_DBUSER
				fi
				if [ -z "$TARGET_DBENGINE_MYSQL_HOST" ] ; then
					dbhost=localhost
					TARGET_DBENGINE_MYSQL_HOST=$dbhost
				else
					dbhost=$TARGET_DBENGINE_MYSQL_HOST
				fi
				
				echo
				echo -n "ITS::Bugzilla::Info::Create database[$dbname] for user[$dbuser] in "
				echo "'$TARGET_ITS_BUGZILLA_DBENGINE'"
				
				MYSQL_HEADER="$MYSQL --user=root --password=$MYSQL_ROOTPW -e"
				$MYSQL_HEADER "CREATE DATABASE $dbname;"
				$MYSQL_HEADER "CREATE USER '$dbuser'@'$dbhost' IDENTIFIED BY '$dbpw';"
				$MYSQL_HEADER "GRANT ALL ON $dbname.* TO '$dbuser'@'$dbhost';"
				$MYSQL_HEADER "FLUSH PRIVILEGES;"
				$MYSQL_HEADER "QUIT"
			fi
			
			# Put fine tuning parameters of mysql for bugzilla use 
			# under /etc/mysql/conf.d
			if [ ! -f /etc/mysql/conf.d/mysqld_bugzilla.cnf ] ; then
				sudo bash -c "cat >/etc/mysql/conf.d/mysqld_bugzilla.cnf <<EOF
[mysqld]
#
# * Fine Tuning
#
# Allow packets up to what you want (16MB by default)
max_allowed_packet = 8M
# Allow small words in full-text indexes (4 words by default)
ft_min_word_len = 2
EOF"
				sudo service mysql restart
			fi
			;;
		*)
			echo
			echo "ITS::Bugzilla::Error::Invalid dbengine type: '$TARGET_ITS_BUGZILLA_DBENGINE'"
			return
			;;
	esac
	
	case $TARGET_ITS_BUGZILLA_HTTPD in
		apache)
			local vhconfig keys
			
			case $TARGET_ITS_BUGZILLA_HTTPD_SCHEME in
				https)
					sudo a2enmod ssl rewrite
					
					if [ ! -f /etc/apache2/sites-available/$TARGET_ITS_BUGZILLA_SITE ] ; then
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
						vhconfig=$TARGET_ITS_BUGZILLA_SITE.$TARGET_ITS_BUGZILLA_HTTPD_SCHEME
						if [ -f $TARGET_SITE_CONFIG/bugzilla/$vhconfig ] ; then
							sudo cp $TARGET_SITE_CONFIG/bugzilla/$vhconfig /etc/apache2/sites-available/$TARGET_ITS_BUGZILLA_SITE
						else
							echo
							echo "ITS::Bugzilla::Error::No virtualhost with '$TARGET_ITS_BUGZILLA_HTTPD_SCHEME' on $TARGET_ITS_BUGZILLA_HTTPD"
							return
						fi
		
						# Enable virtualhost at port 443 for ssl
						keys=(`grep "^[[:space:]]NameVirtualHost \*:443" /etc/apache2/ports.conf`)
						if [ ! "$keys" ] ; then
							sudo sed -i -e "/^<IfModule mod_ssl.c>.*/a\\\tNameVirtualHost \*:443" /etc/apache2/ports.conf
						fi
						
						# Match host names with IP address
						keys=(`cat /etc/hosts | grep -i -e "^[0-9\.]*[[:space:]]*$TARGET_ITS_BUGZILLA_SITE"`)
						if [ ! "$keys" ] ; then
						sudo bash -c "cat >>/etc/hosts <<EOF
$TARGET_ITS_BUGZILLA_HTTPD_IPADDR $TARGET_ITS_BUGZILLA_SITE
EOF"
						fi
					
						# Make virtualhost take effect
						sudo a2ensite $TARGET_ITS_BUGZILLA_SITE
						sudo a2dissite default
						sudo /etc/init.d/apache2 restart
					fi
					;;
				*)
					echo 
					echo "ITS::Bugzilla::Error::Invalid httpd scheme: '$TARGET_ITS_BUGZILLA_HTTPD_SCHEME'"
					return
					;;
			esac
			;;
		*)
			echo
			echo "ITS::Bugzilla::Error::Invalid httpd type: '$TARGET_ITS_BUGZILLA_HTTPD'"
			return
			;;
	esac
}

its_bugzilla_preinstall()
{
	if [ -z "$TARGET_ITS" ] ; then
		echo 
		echo "ITS::Bugzilla::Error::TARGET_ITS not set yet"
		return
	fi
	
	echo 
	echo "ITS::Bugzilla::Info::Preinstall for site[$TARGET_ITS_BUGZILLA_SITE]"
	
	if [ -n "$TARGET_ITS_BUGZILLA_HTTPD" ] ; then
		httpd $TARGET_ITS_BUGZILLA_HTTPD
	fi
	if [ -n "$TARGET_ITS_BUGZILLA_DBENGINE" ] ; then
		dbengine $TARGET_ITS_BUGZILLA_DBENGINE
	fi
	if [ "$TARGET_ITS_BUGZILLA_HTTPD_SCHEME" = "https" ] ; then
		if [[ ! `which ssh` || ! `which sshd` ]] ; then
			sudo apt-get -y install openssh-client openssh-server
		
			# After installation of ssh client/server, I would like to generate
			# new ssh public/private key pair, although the key pair may have
			# been already there for some reason.
			# ssh-keygen -t rsa
			ssh-add
		fi
	fi
	
	if [ ! `which perl` ] ; then
		sudo apt-get -y install perl
	fi
	if [ ! `which wget` ] ; then
		sudo apt-get -y install wget
	fi
}

its_bugzilla_clean()
{
	if [ -z "$TARGET_ITS" ] ; then
		echo 
		echo "ITS::Bugzilla::Error::TARGET_ITS not set yet"
		return
	fi
	
	echo 
	echo "ITS::Bugzilla::Info::Clean for site[$TARGET_ITS_BUGZILLA_SITE]"
	
	case $TARGET_ITS_BUGZILLA_DBENGINE in
		mysql)
			local MYSQL MYSQL_HEADER_COMPLEX MYSQL_HEADER_SIMPLE MYSQL_ROOTPW 
			local dbhost dbuser dbname
			MYSQL=(`which mysql`)
			
			if [ -z "$TARGET_ITS_BUGZILLA_DBENGINE_DBNAME" ] ; then
				dbname=(`echo -n $TARGET_ITS_BUGZILLA_SITE | sed -e "s/\./_/g"`)
				export TARGET_ITS_BUGZILLA_DBENGINE_DBNAME=$dbname
			else
				dbname=$TARGET_ITS_BUGZILLA_DBENGINE_DBNAME
			fi
			if [ -z "$TARGET_DBENGINE_MYSQL_ROOTPW" ] ; then
				read -s -p "Enter password for MySQL: " MYSQL_ROOTPW
				export TARGET_DBENGINE_MYSQL_ROOTPW=$MYSQL_ROOTPW
			else
				MYSQL_ROOTPW=$TARGET_DBENGINE_MYSQL_ROOTPW
			fi
			if [ -z "$TARGET_ITS_BUGZILLA_DBENGINE_DBUSER" ] ; then
				dbuser=bugzilla
				export TARGET_ITS_BUGZILLA_DBENGINE_DBUSER=$dbuser
			else
				dbuser=$TARGET_ITS_BUGZILLA_DBENGINE_DBUSER
			fi
			if [ -z "$TARGET_DBENGINE_MYSQL_HOST" ] ; then
				dbhost=localhost
				TARGET_DBENGINE_MYSQL_HOST=$dbhost
			else
				dbhost=$TARGET_DBENGINE_MYSQL_HOST
			fi
			
			echo 
			echo -n "ITS::Bugzilla::Info::Clean database[$dbname] for user[$dbuser] in "
			echo "'$TARGET_ITS_BUGZILLA_DBENGINE'"
			
			MYSQL_HEADER_COMPLEX="$MYSQL --user=root --password=$MYSQL_ROOTPW --batch --skip-column-names -e"
			MYSQL_HEADER_SIMPLE="$MYSQL --user=root --password=$MYSQL_ROOTPW -e"
			if [ `$MYSQL_HEADER_COMPLEX "SHOW DATABASES LIKE '$dbname';"` ] ; then
				$MYSQL_HEADER_SIMPLE "DROP DATABASE $dbname;"
			fi
			if [ `$MYSQL_HEADER_COMPLEX "SELECT USER FROM mysql.user WHERE user='$dbuser';"` ] ; then
				$MYSQL_HEADER_SIMPLE "DROP USER $dbuser@$dbhost;"
			fi
			
			if [ -f /etc/mysql/conf.d/mysqld_bugzilla.cnf ] ; then
				sudo rm /etc/mysql/conf.d/mysqld_bugzilla.cnf
				sudo service mysql restart
			fi
			;;
		*)
			echo
			echo "ITS::Bugzilla::Error::Invalid dbengine type: '$TARGET_ITS_BUGZILLA_DBENGINE'"
			return
			;;
	esac
			
	case $TARGET_ITS_BUGZILLA_HTTPD in
		apache)
			if [ -f /etc/apache2/sites-available/$TARGET_ITS_BUGZILLA_SITE ] ; then
				sudo rm /etc/apache2/sites-available/$TARGET_ITS_BUGZILLA_SITE
			fi
			if [ -L /etc/apache2/sites-enabled/$TARGET_ITS_BUGZILLA_SITE ] ; then
				sudo rm /etc/apache2/sites-enabled/$TARGET_ITS_BUGZILLA_SITE
			fi
			;;
		*)
			echo
			echo "ITS::Bugzilla::Error::Invalid httpd type: '$TARGET_ITS_BUGZILLA_HTTPD'"
			return
			;;
	esac
	
	if [ -d /home/www-data/$TARGET_ITS_BUGZILLA_SITE ] ; then
		sudo rm -rf /home/www-data/$TARGET_ITS_BUGZILLA_SITE
	fi
}

its_bugzilla()
{
	if [ -z "$TARGET_ITS" ] ; then
		echo 
		echo "ITS::Bugzilla::Error::TARGET_ITS not set yet"
		return
	fi
	
	local goal
	for goal in ${TARGET_SITE_GOALS[@]}
	do
		case $goal in
			clean)
				its_bugzilla_clean
				;;
			preinstall)
				its_bugzilla_preinstall
				;;
			configure)
				its_bugzilla_configure
				;;
			install)
				its_bugzilla_install
				;;
			postconfig)
				its_bugzilla_postconfig
				;;
			custom)
				its_bugzilla_custom
				;;
			backup)
				its_bugzilla_backup
				;;
			upgrade)
				its_bugzilla_upgrade
				;;
			lite)
				its_bugzilla_clean
				its_bugzilla_preinstall
				its_bugzilla_configure
				its_bugzilla_install
				;;
			all)
				its_bugzilla_clean
				its_bugzilla_preinstall
				its_bugzilla_configure
				its_bugzilla_install
				its_bugzilla_postconfig
				its_bugzilla_custom
				;;
			*)
				echo
				echo "ITS::Bugzilla::Error::Invalid target site goal: '$goal'"
				return
				;;
		esac
	done
}
