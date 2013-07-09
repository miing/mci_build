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


lms_sentry_upgrade()
{
	if [ -z "$TARGET_LMS" ] ; then
		echo 
		echo "LMS::Sentry::Error::TARGET_LMS not set yet"
		return
	fi
	
	echo 
	echo "LMS::Sentry::Upgrade::Install for site[$TARGET_LMS_SENTRY_SITE]"
}

lms_sentry_backup()
{
	if [ -z "$TARGET_LMS" ] ; then
		echo 
		echo "LMS::Sentry::Error::TARGET_LMS not set yet"
		return
	fi
	
	echo 
	echo "LMS::Sentry::Info::Backup for site[$TARGET_LMS_SENTRY_SITE]"
}

lms_sentry_custom()
{
	if [ -z "$TARGET_LMS" ] ; then
		echo 
		echo "LMS::Sentry::Error::TARGET_LMS not set yet"
		return
	fi
	
	echo 
	echo "LMS::Sentry::Info::Customize for site[$TARGET_LMS_SENTRY_SITE]"
}

lms_sentry_postconfig()
{
	if [ -z "$TARGET_LMS" ] ; then
		echo 
		echo "LMS::Sentry::Error::TARGET_LMS not set yet"
		return
	fi
	
	echo 
	echo "LMS::Sentry::Info::Postconfigure for site[$TARGET_LMS_SENTRY_SITE]"
}

lms_sentry_install() 
{
	if [ -z "$TARGET_LMS" ] ; then
		echo 
		echo "LMS::Sentry::Error::TARGET_LMS not set yet"
		return
	fi
	
	echo 
	echo "LMS::Sentry::Info::Install for site[$TARGET_LMS_SENTRY_SITE]"
	
	local lmstop=/home/sentry
	local config=sentry.conf.py conf=sentry.conf
	if [ ! -f $lmstop/etc/$config ] ; then
		sudo -u sentry virtualenv /home/sentry/
		
		sudo -u sentry bash -c ". $lmstop/bin/activate && pip install sentry"
		if [ "$TARGET_LMS_SENTRY_DBENGINE" = "postgresql" ] ; then
			sudo -u sentry bash -c ". $lmstop/bin/activate && pip install psycopg2"
		fi
		sudo -u sentry bash -c ". $lmstop/bin/activate && sentry init $lmstop/etc/$config"
	fi
	
	if [ -f $TARGET_SITE_CONFIG/sentry/$config ] ; then
		local sentry_key
		sentry_key="`grep -e '^SENTRY_KEY.*$' $lmstop/etc/$config`"
		
		sudo -u sentry cp $TARGET_SITE_CONFIG/sentry/$config $lmstop/etc
		
		if [ "$sentry_key" ] ; then
			sudo -u sentry sed -i -e "s/^SENTRY_KEY.*$/$sentry_key/" $lmstop/etc/$config
		fi
	fi
	
	if [ ! -f /etc/supervisor/conf.d/$conf ] ; then
		sudo cp $TARGET_SITE_CONFIG/sentry/$conf /etc/supervisor/conf.d/
		sudo killall supervisord
		sleep 10
		sudo /etc/init.d/supervisor start
		sleep 20
	fi
	sudo -u sentry bash -c ". $lmstop/bin/activate && sentry --config=$lmstop/etc/$config createsuperuser"
}

lms_sentry_configure()
{
	if [ -z "$TARGET_LMS" ] ; then
		echo 
		echo "LMS::Sentry::Error::TARGET_LMS not set yet"
		return
	fi
	
	echo 
	echo "LMS::Sentry::Info::Configure for site[$TARGET_LMS_SENTRY_SITE]"
	
	# Add a new user on system which is named sentry
	if [ ! `id -u sentry 2>/dev/null` ] ; then
		sudo adduser \
			--system \
			--shell /bin/bash \
			--gecos 'Sentry Logging Review' \
			--group \
			--disabled-password \
			--home /home/sentry \
			sentry
	fi
	
	case $TARGET_LMS_SENTRY_DBENGINE in
		postgresql)
			# Create a new database via postgresql for Sentry use which is named 
			# by means of this variable, TARGET_LMS_SENTRY_SITE. Let's say,
			# this name of the database would be logs_mci_org if this 
			# value of the variable is logs.mci.org.
			local PGSQL_HEADER PGSQL_ROOTPW 
			local PSQL PGSQL_CREATEUSER PGSQL_CREATEDB
			local dbhost dbname dbuser dbpw ret keys
			PSQL=(`which psql`) 
			PGSQL_CREATEUSER=(`which createuser`)
			PGSQL_CREATEDB=(`which createdb`)
			
			if [ -z "$TARGET_LMS_SENTRY_DBENGINE_DBNAME" ] ; then
				dbname=(`echo -n $TARGET_LMS_SENTRY_SITE | sed -e "s/\./_/g"`)
				TARGET_LMS_SENTRY_DBENGINE_DBNAME=$dbname
			else
				dbname=$TARGET_LMS_SENTRY_DBENGINE_DBNAME
			fi
			if [ -z "$TARGET_DBENGINE_PGSQL_ROOTPW" ] ; then
				read -s -p "Enter password for PGSQL: " PGSQL_ROOTPW
				TARGET_DBENGINE_PGSQL_ROOTPW=$PGSQL_ROOTPW
			else
				PGSQL_ROOTPW=$TARGET_DBENGINE_PGSQL_ROOTPW
			fi
			PGSQL_HEADER="sudo -u postgres"
			ret=(`$PGSQL_HEADER $PSQL -d $dbname -c "\q" 2>/dev/null`)
			if [ $? -ne 0 ] ; then
				if [ -z "$TARGET_LMS_SENTRY_DBENGINE_DBPW" ] ; then
					read -s -p "Enter password for Sentry database: " dbpw
				else
					dbpw=$TARGET_LMS_SENTRY_DBENGINE_DBPW
				fi
				if [ -z "$TARGET_LMS_SENTRY_DBENGINE_DBUSER" ] ; then
					dbuser=sentry
					TARGET_LMS_SENTRY_DBENGINE_DBUSER=$dbuser
				else
					dbuser=$TARGET_LMS_SENTRY_DBENGINE_DBUSER
				fi
				if [ -z "$TARGET_DBENGINE_PGSQL_HOST" ] ; then
					dbhost=localhost
					TARGET_DBENGINE_PGSQL_HOST=$dbhost
				else
					dbhost=$TARGET_DBENGINE_PGSQL_HOST
				fi
				
				echo 
				echo -n "LMS::Sentry::Info::Create database[$dbname] for user[$dbuser] in "
				echo "'$TARGET_LMS_SENTRY_DBENGINE'"
				
				$PGSQL_HEADER $PSQL -c "CREATE USER $dbuser NOSUPERUSER NOCREATEROLE NOCREATEDB ENCRYPTED PASSWORD '$dbpw'"
				$PGSQL_HEADER $PGSQL_CREATEDB -E UTF8 --owner=$dbuser $dbname
				
				keys=(`sudo grep "^local[[:space:]]\+$dbname[[:space:]]\+$dbuser[[:space:]]\+md5" /etc/postgresql/*/main/pg_hba.conf 2>/dev/null`)
				if [ ! "$keys" ] ; then
					sudo sed -i -e "/^local[[:space:]]\+all[[:space:]]\+postgres/i\local\t$dbname\t$dbuser\tmd5" /etc/postgresql/*/main/pg_hba.conf
				fi
			fi
			;;
		*)
			echo
			echo "LMS::Sentry::Error::Invalid dbengine type: '$TARGET_LMS_SENTRY_DBENGINE'"
			return
			;;
	esac
	
	case $TARGET_LMS_SENTRY_HTTPD in
		apache)
			local vhconfig keys
			
			case $TARGET_LMS_SENTRY_HTTPD_SCHEME in
				https)
					sudo a2enmod ssl proxy proxy_http rewrite
					
					if [ ! -f /etc/apache2/sites-available/$TARGET_LMS_SENTRY_SITE ] ; then
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
						vhconfig=$TARGET_LMS_SENTRY_SITE.$TARGET_LMS_SENTRY_HTTPD_SCHEME
						if [ -f $TARGET_SITE_CONFIG/sentry/$vhconfig ] ; then
							sudo cp $TARGET_SITE_CONFIG/sentry/$vhconfig /etc/apache2/sites-available/$TARGET_LMS_SENTRY_SITE
						else
							echo
							echo "LMS::Sentry::Error::No virtualhost with '$TARGET_LMS_SENTRY_HTTPD_SCHEME' on $TARGET_LMS_SENTRY_HTTPD"
							return
						fi 
		
						# Enable virtualhost at port 443 for ssl
						keys=(`grep "^[[:space:]]NameVirtualHost \*:443" /etc/apache2/ports.conf 2>/dev/null`)
						if [ ! "$keys" ] ; then
							sudo sed -i -e "/^<IfModule mod_ssl.c>.*/a\\\tNameVirtualHost \*:443" /etc/apache2/ports.conf
						fi
						
						# Match host names with IP address
						keys=(`cat /etc/hosts | grep -i -e "^[0-9\.]*[[:space:]]*$TARGET_LMS_SENTRY_SITE"`)
						if [ ! "$keys" ] ; then
						sudo bash -c "cat >>/etc/hosts <<EOF
$TARGET_LMS_SENTRY_HTTPD_IPADDR $TARGET_LMS_SENTRY_SITE
EOF"
						fi
					
						# Make virtualhost take effect
						sudo a2ensite $TARGET_LMS_SENTRY_SITE
						sudo a2dissite default
						sudo /etc/init.d/apache2 restart
					fi
					;;
				*)
					echo 
					echo "LMS::Sentry::Error::Invalid httpd scheme: '$TARGET_LMS_SENTRY_HTTPD_SCHEME'"
					return
					;;
			esac
			;;
		*)
			echo
			echo "LMS::Sentry::Error::Invalid httpd type: '$TARGET_LMS_SENTRY_HTTPD'"
			return
			;;
	esac
}

lms_sentry_preinstall()
{
	if [ -z "$TARGET_LMS" ] ; then
		echo 
		echo "LMS::Sentry::Error::TARGET_LMS not set yet"
		return
	fi
	
	echo 
	echo "LMS::Sentry::Info::Preinstall for site[$TARGET_LMS_SENTRY_SITE]"
	
	if [ -n "$TARGET_LMS_SENTRY_HTTPD" ] ; then
		httpd $TARGET_LMS_SENTRY_HTTPD
	fi
	if [ -n "$TARGET_LMS_SENTRY_DBENGINE" ] ; then
		dbengine $TARGET_LMS_SENTRY_DBENGINE
	fi
	if [ "$TARGET_LMS_SENTRY_HTTPD_SCHEME" = "https" ] ; then
		if [[ ! `which ssh` || ! `which sshd` ]] ; then
			sudo apt-get -y install openssh-client openssh-server
		
			# After installation of ssh client/server, I would like to generate
			# new ssh public/private key pair, although the key pair may have
			# been already there for some reason.
			# ssh-keygen -t rsa
			ssh-add
		fi
	fi
	
	# Setup Python on which Sentry runs depending
	if [ ! `which python` ] ; then
		sudo apt-get -y install python
	fi
	if [ ! `which supervisord` ] ; then
		sudo apt-get -y install supervisord
	fi
}

lms_sentry_clean()
{
	if [ -z "$TARGET_LMS" ] ; then
		echo 
		echo "LMS::Sentry::Error::TARGET_LMS not set yet"
		return
	fi
	
	echo
	echo "LMS::Sentry::Info::Clean for site[$TARGET_LMS_SENTRY_SITE]"
	
	local config=sentry.conf
	if [ -f /etc/supervisor/conf.d/$config ] ; then
		sudo rm /etc/supervisor/conf.d/$config
		sudo killall supervisord
		sudo /etc/init.d/supervisor start
	fi
	
	case $TARGET_LMS_SENTRY_DBENGINE in
		postgresql)
			local PSQL PGSQL_HEADER PGSQL_ROOTPW 
			local dbhost dbname dbuser ret
			PSQL=(`which psql`)
			if [ -z "$TARGET_LMS_SENTRY_PGSQL_DBNAME" ] ; then
				dbname=(`echo -n $TARGET_LMS_SENTRY_SITE | sed -e "s/\./_/g"`)
				TARGET_LMS_SENTRY_PGSQL_DBNAME=$dbname
			else
				dbname=$TARGET_LMS_SENTRY_PGSQL_DBNAME
			fi
			if [ -z "$TARGET_DBENGINE_PGSQL_ROOTPW" ] ; then
				read -s -p "Enter password for PGSQL: " PGSQL_ROOTPW
				TARGET_DBENGINE_PGSQL_ROOTPW=$PGSQL_ROOTPW
			else
				PGSQL_ROOTPW=$TARGET_DBENGINE_PGSQL_ROOTPW
			fi
			if [ -z "$TARGET_LMS_SENTRY_PGSQL_DBUSER" ] ; then
				dbuser=sentry
				TARGET_LMS_SENTRY_PGSQL_DBUSER=$dbuser
			else
				dbuser=$TARGET_LMS_SENTRY_PGSQL_DBUSER
			fi
			if [ -z "$TARGET_DBENGINE_PGSQL_HOST" ] ; then
				dbhost=localhost
				TARGET_DBENGINE_PGSQL_HOST=$dbhost
			else
				dbhost=$TARGET_DBENGINE_PGSQL_HOST
			fi
			
			echo
			echo -n "LMS::Sentry::Info::Clean database[$dbname] for user[$dbuser] in "
			echo "'$TARGET_LMS_SENTRY_DBENGINE'"
			
			PGSQL_HEADER="sudo -u postgres"
			ret=(`$PGSQL_HEADER $PSQL -d $dbname -c "\q" 2>/dev/null`)
			if [ $? -eq 0 ] ; then
				$PGSQL_HEADER $PSQL -c "DROP DATABASE $dbname;"
			fi
			ret=(`$PGSQL_HEADER $PSQL -t -A -c "SELECT COUNT(*) FROM pg_user WHERE usename = '$dbuser';"`)
			if [ $ret -eq 1 ] ; then
				$PGSQL_HEADER $PSQL -c "DROP USER $dbuser;"
			fi
			;;
		*)
			echo
			echo "LMS::Sentry::Error::Invalid dbengine type: '$TARGET_LMS_SENTRY_DBENGINE'"
			return
			;;
	esac
			
	case $TARGET_LMS_SENTRY_HTTPD in
		apache)
			if [ -f /etc/apache2/sites-available/$TARGET_LMS_SENTRY_SITE ] ; then
				sudo rm /etc/apache2/sites-available/$TARGET_LMS_SENTRY_SITE
			fi
			if [ -L /etc/apache2/sites-enabled/$TARGET_LMS_SENTRY_SITE ] ; then
				sudo rm /etc/apache2/sites-enabled/$TARGET_LMS_SENTRY_SITE
			fi
			;;
		*)
			echo
			echo "LMS::Sentry::Error::Invalid httpd type: '$TARGET_LMS_SENTRY_HTTPD'"
			return
			;;
	esac
	
	if [ `id -u sentry 2>/dev/null` ] ; then
		sudo deluser sentry
	fi
	if [ -d /home/sentry ] ; then
		sudo rm -rf /home/sentry
	fi
}

lms_sentry()
{
	if [ -z "$TARGET_LMS" ] ; then
		echo 
		echo "LMS::Sentry::Error::TARGET_LMS not set yet"
		return
	fi
	
	local goal
	for goal in ${TARGET_SITE_GOALS[@]}
	do
		case $goal in
			clean)
				lms_sentry_clean
				;;
			preinstall)
				lms_sentry_preinstall
				;;
			configure)
				lms_sentry_configure
				;;
			install)
				lms_sentry_install
				;;
			postconfig)
				lms_sentry_postconfig
				;;
			custom)
				lms_sentry_custom
				;;
			backup)
				lms_sentry_backup
				;;
			upgrade)
				lms_sentry_upgrade
				;;
			lite)
				lms_sentry_clean
				lms_sentry_preinstall
				lms_sentry_configure
				lms_sentry_install
				;;
			all)
				lms_sentry_clean
				lms_sentry_preinstall
				lms_sentry_configure
				lms_sentry_install
				lms_sentry_postconfig
				lms_sentry_custom
				;;
			*)
				echo
				echo "LMS::Sentry::Error::Invalid target site goal: '$goal'"
				return
				;;
		esac
	done
}
