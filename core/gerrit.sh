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


scmr_gerrit_upgrade()
{
	if [ -z "$TARGET_SCMR" ] ; then
		echo 
		echo "SCMR::Gerrit::Error::TARGET_SCMR not set yet"
		return
	fi
	
	echo 
	echo "SCMR::Gerrit::Info::Upgrade for site[$TARGET_SCMR_GERRIT_SITE]"
}

scmr_gerrit_backup()
{
	if [ -z "$TARGET_SCMR" ] ; then
		echo 
		echo "SCMR::Gerrit::Error::TARGET_SCMR not set yet"
		return
	fi
	
	echo 
	echo "SCMR::Gerrit::Info::Backup for site[$TARGET_SCMR_GERRIT_SITE]"
	
	# Refer to http://www.ovirt.org/Gerrit_server_backup
}

scmr_gerrit_custom()
{
	if [ -z "$TARGET_SCMR" ] ; then
		echo 
		echo "SCMR::Gerrit::Error::TARGET_SCMR not set yet"
		return
	fi
	
	echo 
	echo "SCMR::Gerrit::Info::Customize for site[$TARGET_SCMR_GERRIT_SITE]"
	
	local scmrtop=/home/gerrit
	local config=gerrit.config 
	local updated=false
	if [ ! -f $scmrtop/etc/$config ] ; then
		echo 
		echo "SCMR::Gerrit::Error::'$config' not existing yet under '$scmrtop'"
		return
	fi
	
	# Theme
	if [ -d $TARGET_SITE_THEMES/gerrit/$TARGET_SCMR_GERRIT_SITE_THEME ] ; then
		sudo -u gerrit cp $TARGET_SITE_THEMES/gerrit/$TARGET_SCMR_GERRIT_SITE_THEME/GerritSite* $scmrtop/etc/
		
		sudo -u gerrit cp $TARGET_SITE_THEMES/gerrit/$TARGET_SCMR_GERRIT_SITE_THEME/static/* $scmrtop/static/
	fi
}

scmr_gerrit_postconfig()
{
	if [ -z "$TARGET_SCMR" ] ; then
		echo 
		echo "SCMR::Gerrit::Error::TARGET_SCMR not set yet"
		return
	fi
	
	echo 
	echo "SCMR::Gerrit::Info::Postconfigure for site[$TARGET_SCMR_GERRIT_SITE]"
	
	local scmrtop=/home/gerrit
	local config=gerrit.config 
	local updated=false
	if [ ! -f $scmrtop/etc/$config ] ; then
		echo 
		echo "SCMR::Gerrit::Error::'$config' not existing yet under '$scmrtop'"
		return
	fi
	
	# Configure SSH for Gerrit access
	local conf=~/.ssh/config
	if [ -n "$TARGET_SCMR_GERRIT_SSHGIT_CONFIG" ] ; then
		if [ ! -f $conf ] ; then
			ssh-keygen -t rsa -C "$TARGET_SCMR_GERRIT_SSHGIT_USER $TARGET_SCMR_GERRIT_SSHGIT_EMAIL"
			cp $TARGET_SITE_CONFIG/gerrit/$TARGET_SCMR_GERRIT_SSHGIT_CONFIG $conf
		fi
	fi
	
	# Configure Git for Gerrit access
	conf=~/.gitconfig
	if [ ! -f $conf ] ; then
		local user email editor
		
		touch $conf
		if [ -z "$TARGET_SCMR_GERRIT_SSHGIT_USER" ] ; then
			while [ -z $user ] ; do
				echo -n "Your user name for Git is: " ; read user
			done
			TARGET_SCMR_GERRIT_SSHGIT_USER=$user
		else
			user=$TARGET_SCMR_GERRIT_SSHGIT_USER
		fi
		if [ -z "$TARGET_SCMR_GERRIT_SSHGIT_EMAIL" ] ; then
			while [ -z $email ] ; do
				echo -n "Your user email for Git is: " ; read email
			done
			TARGET_SCMR_GERRIT_SSHGIT_EMAIL=$email
		else
			email=$TARGET_SCMR_GERRIT_SSHGIT_EMAIL
		fi
		if [ -z "$TARGET_SCMR_GERRIT_SSHGIT_EDITOR" ] ; then
			while [ -z $editor ] ; do
				echo -n "Your core editor for Git is: " ; read editor
			done
			TARGET_SCMR_GERRIT_SSHGIT_EDITOR=$editor
		else
			editor=$TARGET_SCMR_GERRIT_SSHGIT_EDITOR
		fi
		git config --global user.name "$user"
		git config --global user.email "$email"
		git config --global core.editor "$editor"
		git config --global color.ui true
	fi
}

scmr_gerrit_install()
{
	if [ -z "$TARGET_SCMR" ] ; then
		echo 
		echo "SCMR::Gerrit::Error::TARGET_SCMR not set yet"
		return
	fi
	
	echo 
	echo "SCMR::Gerrit::Info::Install for site[$TARGET_SCMR_GERRIT_SITE]"
	
	local scmrtop=/home/gerrit
	if [ ! -f $scmrtop/bin/gerrit.sh ] ; then
		# Set paths
		local bin_path=$scmrtop/bin
		local keys=(`grep -i "$bin_path" $scmrtop/.bashrc 2>/dev/null`)
		if [ ! "$keys" ] ; then
			sudo -u gerrit bash -c "echo 'PATH=$bin_path:$PATH' >>$scmrtop/.bashrc"
		fi
		
		# Obtain libraries Gerrit depends on to automatically install it
		if [ ! -d $scmrtop/lib ] ; then
			sudo -u gerrit mkdir $scmrtop/lib
		fi
		local jar=bcprov-jdk16-144.jar
		local url
		if [ ! -f $scmrtop/lib/$jar ] ; then
			local OPENSSL=(`which openssl`)
			local default_sha1=6327a5f7a3dc45e0fd735adb5d08c5a74c05c20c
			local local_sha1
			url=http://www.bouncycastle.org/download
			
			sudo -u gerrit wget -P $scmrtop/lib $url/$jar
			local_sha1=(`$OPENSSL dgst -sha1 $scmrtop/lib/$jar | sed "s/^.* //"`)
			if [ "$default_sha1" != "$local_sha1" ] ; then
				echo
				echo "SCMR::Gerrit::Error::Unmatched checksum for '$jar'"	
				return
			fi
		fi
		
		# Set predefined configuration files 
		if [ ! -d $scmrtop/etc ] ; then
			sudo -u gerrit mkdir $scmrtop/etc
		fi
		local config=$TARGET_SITE_CONFIG/gerrit/gerrit.config.$TARGET_SCMR_GERRIT_HTTPD_SCHEME.$TARGET_SCMR_GERRIT_SITE_AUTH
		if [ ! -f $scmrtop/etc/gerrit.config ] ; then
			sudo -u gerrit cp $config $scmrtop/etc/gerrit.config
		fi
		config=$TARGET_SITE_CONFIG/gerrit/secure.config
		if [ ! -f $scmrtop/etc/secure.config ] ; then
			sudo -u gerrit cp $config $scmrtop/etc/secure.config
		fi
		
		# Pick up the up-to-date version of Gerrit 
		# from http://code.google.com/p/gerrit/downloads/list
		local stable=gerrit.war
		local installed=gerrit-$TARGET_SCMR_GERRIT_VERSION_INSTALLED.war
		url=http://gerrit.googlecode.com/files
		sudo -u gerrit wget -O $scmrtop/$stable $url/$installed
		if [ -f $scmrtop/etc/gerrit.config ] ; then
			sudo -H -u gerrit java -jar $scmrtop/$stable init --batch --no-auto-start -d $scmrtop
		else
			sudo -H -u gerrit java -jar $scmrtop/$stable init --no-auto-start -d $scmrtop
		fi
		sudo -u gerrit rm $scmrtop/$stable
	
		# Do some modifications in $scmrtop/etc/gerrit.config
		local item=canonicalWebUrl
		url=$TARGET_SCMR_GERRIT_HTTPD_SCHEME://$TARGET_SCMR_GERRIT_SITE
		keys=(`grep "$item" $scmrtop/etc/gerrit.config 2>/dev/null`)
		if [ ! "$keys" ] ; then
			sudo -u gerrit sed -i -e "/^[[:space:]]basePath.*/a\\\t$item = $url" $scmrtop/etc/gerrit.config
		fi
		if [ "$TARGET_SCMR_GERRIT_SITE_AUTH" = "openidsso" ] ; then
			if [ -n "$TARGET_SCMR_GERRIT_SITE_OPENIDSSO_URL" ] ; then
				item=openIdSsoUrl
				keys=(`grep "$item" $scmrtop/etc/gerrit.config 2>/dev/null`)
				if [ ! "$keys" ] ; then
					sudo -u gerrit sed -i -e "/^[[:space:]]type = OPENID_SSO.*/a\\\t$item = $TARGET_SCMR_GERRIT_SITE_OPENIDSSO_URL" $scmrtop/etc/gerrit.config
				else
					url=(`echo $TARGET_SCMR_GERRIT_SITE_OPENIDSSO_URL | sed -e 's/\//\\\\\//g'`)
					sudo -u gerrit sed -i -e "s/^[[:space:]]$item.*/\t$item = $url/" $scmrtop/etc/gerrit.config
				fi
			else
				echo 
				echo "SCMR::Gerrit::Error::OpenID SSO URL not specified yet"
				return
			fi
		fi
	fi
	
	# Launch Gerrit daemon
	if [ ! -L /etc/init.d/gerrit ] ; then
		sudo ln -snf $scmrtop/bin/gerrit.sh /etc/init.d/gerrit
		
		if [ ! -f /etc/default/gerritcodereview ] ; then
			sudo cp $TARGET_SITE_CONFIG/gerrit/gerritcodereview /etc/default/gerritcodereview
		fi
		sudo update-rc.d gerrit defaults 90 10
	fi
	keys=(`ps -ef | grep -i "^gerrit"`)
	if [ ! "$keys" ] ; then
		sudo /etc/init.d/gerrit start
	fi
}

scmr_gerrit_configure()
{
	if [ -z "$TARGET_SCMR" ] ; then
		echo 
		echo "SCMR::Gerrit::Error::TARGET_SCMR not set yet"
		return
	fi
	
	echo 
	echo "SCMR::Gerrit::Info::Configure site[$TARGET_SCMR_GERRIT_SITE]"
	
	# Add a new user on system which is named gerrit
	if [ ! `id -u gerrit 2>/dev/null` ] ; then
		sudo adduser \
			--system \
			--shell /bin/bash \
			--gecos 'Gerrit Code Review' \
			--group \
			--disabled-password \
			--home /home/gerrit \
			gerrit
	fi
	
	case $TARGET_SCMR_GERRIT_DBENGINE in
		mysql)
			# Create a new database via mysql for Gerrit use which is named 
			# by means of this variable, TARGET_SCMR_GERRIT_SITE. Let's say,
			# this name of the database would be review_mci_org if this 
			# value of the variable is review.mci.org.
			local MYSQL MYSQL_HEADER MYSQL_ROOTPW 
			local dbhost dbname dbuser dbpw
			MYSQL=(`which mysql`)
			
			if [ -z "$TARGET_SCMR_GERRIT_DBENGINE_DBNAME" ] ; then
				dbname=(`echo -n $TARGET_SCMR_GERRIT_SITE | sed -e "s/\./_/g"`)
				TARGET_SCMR_GERRIT_DBENGINE_DBNAME=$dbname
			else
				dbname=$TARGET_SCMR_GERRIT_DBENGINE_DBNAME
			fi
			if [ -z "$TARGET_DBENGINE_MYSQL_ROOTPW" ] ; then
				read -s -p "Enter password for MySQL: " MYSQL_ROOTPW
				TARGET_DBENGINE_MYSQL_ROOTPW=$MYSQL_ROOTPW
			else
				MYSQL_ROOTPW=$TARGET_DBENGINE_MYSQL_ROOTPW
			fi
			MYSQL_HEADER="$MYSQL --user=root --password=$MYSQL_ROOTPW --batch --skip-column-names -e"
			if [ ! `$MYSQL_HEADER "SHOW DATABASES LIKE '$dbname';"` ] ; then
				if [ -z "$TARGET_SCMR_GERRIT_DBENGINE_DBPW" ] ; then
					read -s -p "Enter password for 'Gerrit' database: " dbpw
				else
					dbpw=$TARGET_SCMR_GERRIT_DBENGINE_DBPW
				fi
				if [ -z "$TARGET_SCMR_GERRIT_DBENGINE_DBUSER" ] ; then
					dbuser=gerrit
					TARGET_SCMR_GERRIT_DBENGINE_DBUSER=$dbuser
				else
					dbuser=$TARGET_SCMR_GERRIT_DBENGINE_DBUSER
				fi
				if [ -z "$TARGET_DBENGINE_MYSQL_HOST" ] ; then
					dbhost=localhost
					TARGET_DBENGINE_MYSQL_HOST=$dbhost
				else
					dbhost=$TARGET_DBENGINE_MYSQL_HOST
				fi
				
				echo
				echo -n "SCMR::Gerrit::Info::Create database[$dbname] for user[$dbuser] in "
				echo "'$TARGET_SCMR_GERRIT_DBENGINE'"
				
				MYSQL_HEADER="$MYSQL --user=root --password=$MYSQL_ROOTPW -e"
				$MYSQL_HEADER "CREATE DATABASE $dbname;"
				$MYSQL_HEADER "ALTER DATABASE $dbname charset=latin1;"
				$MYSQL_HEADER "CREATE USER '$dbuser'@'$dbhost' IDENTIFIED BY '$dbpw';"
				$MYSQL_HEADER "GRANT ALL ON $dbname.* TO '$dbuser'@'$dbhost';"
				$MYSQL_HEADER "FLUSH PRIVILEGES;"
				$MYSQL_HEADER "QUIT"
			fi
			;;
		*)
			echo
			echo "SCMR::Gerrit::Error::Invalid dbengine type: '$TARGET_SCMR_GERRIT_DBENGINE'"
			return
			;;
	esac
	
	case $TARGET_SCMR_GERRIT_HTTPD in
		apache)
			local vhconfig keys
			
			case $TARGET_SCMR_GERRIT_HTTPD_SCHEME in
				https)
					sudo a2enmod ssl proxy proxy_http rewrite
					
					if [ ! -f /etc/apache2/sites-available/$TARGET_SCMR_GERRIT_SITE ] ; then
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
						if [ "$TARGET_SCMR_GERRIT_SITE_AUTH" = "httpbasic" ] ; then
							# For the sake of http authentication, instead of
							# OpenID, have to set up auth passwords for admin
							# and users of Gerrit
							if [ -z "$TARGET_SCMR_GERRIT_SITE_HTTPBASIC_ADMIN" ] ; then
								echo
								echo "SCMR::Gerrit::Error::No Admin for Httpbasic Auth"
								return
							fi
							sudo -H -u gerrit touch /home/gerrit/etc/passwords
							sudo -H -u gerrit /bin/bash -c "/usr/bin/htpasswd /home/gerrit/etc/passwords $TARGET_SCMR_GERRIT_SITE_HTTPBASIC_ADMIN"
							
							vhconfig=$TARGET_SCMR_GERRIT_SITE.$TARGET_SCMR_GERRIT_HTTPD_SCHEME.$TARGET_SCMR_GERRIT_SITE_AUTH
						else
							vhconfig=$TARGET_SCMR_GERRIT_SITE.$TARGET_SCMR_GERRIT_HTTPD_SCHEME
						fi
						if [ -f $TARGET_SITE_CONFIG/gerrit/$vhconfig ] ; then
							sudo cp $TARGET_SITE_CONFIG/gerrit/$vhconfig /etc/apache2/sites-available/$TARGET_SCMR_GERRIT_SITE
						else
							echo
							echo "SCMR::Gerrit::Error::No virtualhost with '$TARGET_SCMR_GERRIT_HTTPD_SCHEME' on $TARGET_SCMR_GERRIT_HTTPD"
							return
						fi 
		
						# Enable virtualhost at port 443 for ssl
						keys=(`grep "^[[:space:]]NameVirtualHost \*:443" /etc/apache2/ports.conf 2>/dev/null`)
						if [ ! "$keys" ] ; then
							sudo sed -i -e "/^<IfModule mod_ssl.c>.*/a\\\tNameVirtualHost \*:443" /etc/apache2/ports.conf
						fi
						
						# Match host names with IP address
						keys=(`cat /etc/hosts | grep -i -e "^[0-9\.]*[[:space:]]*$TARGET_SCMR_GERRIT_SITE"`)
						if [ ! "$keys" ] ; then
						sudo bash -c "cat >>/etc/hosts <<EOF
$TARGET_SCMR_GERRIT_HTTPD_IPADDR $TARGET_SCMR_GERRIT_SITE
EOF"
						fi
						
						# Make virtualhost take effect
						sudo a2ensite $TARGET_SCMR_GERRIT_SITE
						sudo a2dissite default
						sudo /etc/init.d/apache2 restart
					fi
					;;
				*)
					echo 
					echo "SCMR::Gerrit::Error::Invalid httpd scheme: '$TARGET_SCMR_GERRIT_HTTPD_SCHEME'"
					return
					;;
			esac
			;;
		*)
			echo
			echo "SCMR::Gerrit::Error::Invalid httpd type: '$TARGET_SCMR_GERRIT_HTTPD'"
			return
			;;
	esac
}

scmr_gerrit_preinstall()
{
	if [ -z "$TARGET_SCMR" ] ; then
		echo 
		echo "SCMR::Gerrit::Error::TARGET_SCMR not set yet"
		return
	fi
	
	echo 
	echo "SCMR::Gerrit::Info::Preinstall for site[$TARGET_SCMR_GERRIT_SITE]"
	
	if [ -n "$TARGET_SCMR_GERRIT_HTTPD" ] ; then
		httpd $TARGET_SCMR_GERRIT_HTTPD
	fi
	if [ -n "$TARGET_SCMR_GERRIT_DBENGINE" ] ; then
		dbengine $TARGET_SCMR_GERRIT_DBENGINE
	fi
	if [ "$TARGET_SCMR_GERRIT_HTTPD_SCHEME" = "https" ] ; then
		if [[ ! `which ssh` || ! `which sshd` ]] ; then
			sudo apt-get -y install openssh-client openssh-server
		
			# After installation of ssh client/server, I would like to generate
			# new ssh public/private key pair, although the key pair may have
			# been already there for some reason.
			# ssh-keygen -t rsa
			ssh-add
		fi
	fi
	
	# Set up JAVA runtime environment on which Gerrit runs
	if [ ! `which java` ] ; then
		sudo apt-get -y install openjdk-6-jdk
	fi
	
	# Install Git as well as a Webfront for browsing git repositories
	if [ ! `which git` ] ; then
		sudo apt-get -y install git git-doc
	fi
	case $TARGET_SCMR_GERRIT_SITE_WEBFRONT in
		gitweb)
			if [ ! -f /etc/gitweb.conf ] ; then
				sudo apt-get install gitweb highlight
			fi
			;;
		cgit)
			echo
			echo "Stay tuned for cGit"
			;;
		*)
			echo
			echo "SCMR::Gerrit::Error::Invalid Webfront: '$TARGET_SCMR_GERRIT_SITE_WEBFRONT'"
			;;
	esac
	
	# Install Git-review to interact with Gerrit from command line
	if [ ! `which pip` ] ; then
		sudo apt-get install python-pip
	fi
	if [ ! `which git-review` ] ; then
		sudo pip install git-review
	fi
}

scmr_gerrit_clean()
{
	if [ -z "$TARGET_SCMR" ] ; then
		echo 
		echo "SCMR::Gerrit::Error::TARGET_ITS not set yet"
		return
	fi
	
	echo
	echo "SCMR::Gerrit::Info::Clean for site[$TARGET_SCMR_GERRIT_SITE]"
	
	local keys
	keys=(`ps -ef | grep -i "^gerrit" 2>/dev/null`)
	if [ "$keys" ] ; then
		sudo /etc/init.d/gerrit stop
	fi
	if [ -L /etc/init.d/gerrit ] ; then
		sudo rm /etc/init.d/gerrit
		
		if [ -f /etc/default/gerritcodereview ] ; then
			sudo rm /etc/default/gerritcodereview
		fi
	fi
	
	case $TARGET_SCMR_GERRIT_DBENGINE in
		mysql)
			local MYSQL MYSQL_HEADER_COMPLEX MYSQL_HEADER_SIMPLE MYSQL_ROOTPW 
			local dbhost dbname dbuser
			MYSQL=(`which mysql`)
			
			if [ -z "$TARGET_SCMR_GERRIT_DBENGINE_DBNAME" ] ; then
				dbname=(`echo -n $TARGET_SCMR_GERRIT_SITE | sed -e "s/\./_/g"`)
				TARGET_SCMR_GERRIT_DBENGINE_DBNAME=$dbname
			else
				dbname=$TARGET_SCMR_GERRIT_DBENGINE_DBNAME
			fi
			if [ -z "$TARGET_DBENGINE_MYSQL_ROOTPW" ] ; then
				read -s -p "Enter password for MySQL: " MYSQL_ROOTPW
				TARGET_DBENGINE_MYSQL_ROOTPW=$MYSQL_ROOTPW
			else
				MYSQL_ROOTPW=$TARGET_DBENGINE_MYSQL_ROOTPW
			fi
			if [ -z "$TARGET_SCMR_GERRIT_DBENGINE_DBUSER" ] ; then
				dbuser=gerrit
				TARGET_SCMR_GERRIT_DBENGINE_DBUSER=$dbuser
			else
				dbuser=$TARGET_SCMR_GERRIT_DBENGINE_DBUSER
			fi
			if [ -z "$TARGET_DBENGINE_MYSQL_HOST" ] ; then
				dbhost=localhost
				TARGET_DBENGINE_MYSQL_HOST=$dbhost
			else
				dbhost=$TARGET_DBENGINE_MYSQL_HOST
			fi
			
			echo 
			echo -n "SCMR::Gerrit::Info::Clean database[$dbname] for user[$dbuser] in "
			echo "'$TARGET_SCMR_GERRIT_DBENGINE'"
			
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
			echo "SCMR::Gerrit::Error::Invalid dbengine type: '$TARGET_SCMR_GERRIT_DBENGINE'"
			return
			;;
	esac
			
	case $TARGET_SCMR_GERRIT_HTTPD in
		apache)
			if [ -f /etc/apache2/sites-available/$TARGET_SCMR_GERRIT_SITE ] ; then
				sudo rm /etc/apache2/sites-available/$TARGET_SCMR_GERRIT_SITE
			fi
			if [ -L /etc/apache2/sites-enabled/$TARGET_SCMR_GERRIT_SITE ] ; then
				sudo rm /etc/apache2/sites-enabled/$TARGET_SCMR_GERRIT_SITE
			fi
			;;
		*)
			echo
			echo "SCMR::Gerrit::Error::Invalid httpd type: '$TARGET_SCMR_GERRIT_HTTPD'"
			return
			;;
	esac
	
	if [ `id -u gerrit 2>/dev/null` ] ; then
		sudo deluser gerrit
	fi
	if [ -d /home/gerrit ] ; then
		sudo rm -rf /home/gerrit
	fi
}

scmr_gerrit()
{
	if [ -z "$TARGET_SCMR" ] ; then
		echo 
		echo "SCMR::Gerrit::Error::TARGET_SCMR not set yet"
		return
	fi
	
	local goal
	for goal in ${TARGET_SITE_GOALS[@]}
	do
		case $goal in
			clean)
				scmr_gerrit_clean
				;;
			preinstall)
				scmr_gerrit_preinstall
				;;
			configure)
				scmr_gerrit_configure
				;;
			install)
				scmr_gerrit_install
				;;
			postconfig)
				scmr_gerrit_postconfig
				;;
			custom)
				scmr_gerrit_custom
				;;
			backup)
				scmr_gerrit_backup
				;;
			upgrade)
				scmr_gerrit_upgrade
				;;
			lite)
				scmr_gerrit_clean
				scmr_gerrit_preinstall
				scmr_gerrit_configure
				scmr_gerrit_install
				;;
			all)
				scmr_gerrit_clean
				scmr_gerrit_preinstall
				scmr_gerrit_configure
				scmr_gerrit_install
				scmr_gerrit_postconfig
				scmr_gerrit_custom
				;;
			*)
				echo
				echo "SCMR::Gerrit::Error::Invalid target site goal: '$goal'"
				return
				;;
		esac
	done
}
