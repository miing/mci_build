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


sso_migo_upgrade()
{
	if [ -z "$TARGET_SSO" ] ; then
		echo 
		echo "SSO::Migo::Error::TARGET_SSO not set yet"
		return
	fi
	
	echo
	echo "SSO::Migo::Info::Upgrade for site[$TARGET_SSO_MIGO_SITE]"
}

sso_migo_backup()
{
	if [ -z "$TARGET_SSO" ] ; then
		echo 
		echo "SSO::Migo::Error::TARGET_SSO not set yet"
		return
	fi
	
	echo
	echo "SSO::Migo::Info::Backup for site[$TARGET_SSO_MIGO_SITE]"
}

sso_migo_custom()
{
	if [ -z "$TARGET_SSO" ] ; then
		echo 
		echo "SSO::Migo::Error::TARGET_SSO not set yet"
		return
	fi
	
	echo
	echo "SSO::Migo::Info::Customize for site[$TARGET_SSO_MIGO_SITE]"
}

sso_migo_postconfig()
{
	if [ -z "$TARGET_SSO" ] ; then
		echo 
		echo "SSO::Migo::Error::TARGET_SSO not set yet"
		return
	fi
	
	echo 
	echo "SSO::Migo::Info::Postconfigure for site[$TARGET_SSO_MIGO_SITE]"
}

sso_migo_install()
{
	if [ -z "$TARGET_SSO" ] ; then
		echo 
		echo "SSO::Migo::Error::TARGET_SSO not set yet"
		return
	fi
	
	echo 
	echo "SSO::Migo::Info::Install for site[$TARGET_SSO_MIGO_SITE]"
	
	local ssotop=/home/www-data/$TARGET_SSO_MIGO_SITE
	local url
	if [ ! -d $ssotop/.env ] ; then
		if [ ! -d $MCITOP/migo ] ; then
			url=git://github.com/miing/mci_migo.git
			sudo -u www-data git clone $url $ssotop
		else
			sudo -u www-data cp -rf migo $ssotop
		fi
		
		local config=local.cfg
		if [ -f $TARGET_SITE_CONFIG/migo/$config ] ; then
			sudo -u www-data cp $TARGET_SITE_CONFIG/migo/$config $ssotop/dj/
			
			cd $ssotop
			# Fill in local.cfg with the correct base path
			sudo -u www-data sed -i -e "s;^basedir.*;basedir = $PWD;" $ssotop/dj/$config
		fi
		
		sudo fab bootstrap
		sudo fab drop_pgsql_database
		sudo fab setup_pgsql_database
		sudo chown -R www-data:www-data $ssotop
		mcitop
    fi
}

sso_migo_configure()
{
	if [ -z "$TARGET_SSO" ] ; then
		echo 
		echo "SSO::Migo::Error::TARGET_SSO not set yet"
		return
	fi
	
	echo 
	echo "SSO::Migo::Info::Configure for site[$TARGET_SSO_MIGO_SITE]"
	
	case $TARGET_SSO_MIGO_DBENGINE in
		postgresql)
			;;
		*)
			echo
			echo "SSO::Migo::Error::Invalid dbengine type: '$TARGET_SSO_MIGO_DBENGINE'"
			return
			;;
	esac
	
	case $TARGET_SSO_MIGO_HTTPD in
		apache)
			local vhconfig keys
			
			case $TARGET_SSO_MIGO_HTTPD_SCHEME in
				https)
					sudo a2enmod ssl rewrite wsgi
					
					if [ ! -f /etc/apache2/sites-available/$TARGET_SSO_MIGO_SITE ] ; then
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
						vhconfig=$TARGET_SSO_MIGO_SITE.$TARGET_SSO_MIGO_HTTPD_SCHEME
						if [ -f $TARGET_SITE_CONFIG/migo/$vhconfig ] ; then
							sudo cp $TARGET_SITE_CONFIG/migo/$vhconfig /etc/apache2/sites-available/$TARGET_SSO_MIGO_SITE
						else
							echo
							echo "SSO::Migo::Error::No virtualhost with '$TARGET_SSO_MIGO_HTTPD_SCHEME' on $TARGET_SSO_MIGO_HTTPD"
							return
						fi
		
						# Enable virtualhost at port 443 for ssl
						keys=(`grep "^[[:space:]]NameVirtualHost \*:443" /etc/apache2/ports.conf`)
						if [ ! "$keys" ] ; then
						sudo sed -i -e "/^<IfModule mod_ssl.c>.*/a\\\tNameVirtualHost \*:443" /etc/apache2/ports.conf
						fi
						
						# Match host names with IP address
						keys=(`cat /etc/hosts | grep -i -e "^[0-9\.]*[[:space:]]*$TARGET_SSO_MIGO_SITE"`)
						if [ ! "$keys" ] ; then
						sudo bash -c "cat >>/etc/hosts <<EOF
$TARGET_SSO_MIGO_HTTPD_IPADDR $TARGET_SSO_MIGO_SITE
EOF"
						fi
					
						# Make virtualhost take effect
						sudo a2ensite $TARGET_SSO_MIGO_SITE
						sudo a2dissite default
						sudo /etc/init.d/apache2 restart
					fi
					;;
				*)
					echo 
					echo "SSO::Migo::Error::Invalid httpd scheme: '$TARGET_SSO_MIGO_HTTPD_SCHEME'"
					return
					;;
			esac
			;;
		*)
			echo
			echo "SSO::Migo::Error::Invalid httpd type: '$TARGET_SSO_MIGO_HTTPD'"
			return
			;;
	esac
}

sso_migo_preinstall()
{
	if [ -z "$TARGET_SSO" ] ; then
		echo 
		echo "SSO::Migo::Error::TARGET_SSO not set yet"
		return
	fi
	
	echo 
	echo "SSO::Migo::Info::Preinstall for site[$TARGET_SSO_MIGO_SITE]"
	
	if [ -n "$TARGET_SSO_MIGO_HTTPD" ] ; then
		httpd $TARGET_SSO_MIGO_HTTPD
	fi
	if [ -n "$TARGET_SSO_MIGO_DBENGINE" ] ; then
		dbengine $TARGET_SSO_MIGO_DBENGINE
	fi
}

sso_migo_clean()
{
	if [ -z "$TARGET_SSO" ] ; then
		echo 
		echo "SSO::Migo::Error::TARGET_SSO not set yet"
		return
	fi
	
	echo
	echo "SSO::Migo::Info::Clean for site[$TARGET_SSO_MIGO_SITE]"
	
	case $TARGET_SSO_MIGO_DBENGINE in
		postgresql)
			;;
		*)
			echo
			echo "SSO::Migo::Error::Invalid dbengine type: '$TARGET_SSO_MIGO_DBENGINE'"
			return
			;;
	esac
			
	case $TARGET_SSO_MIGO_HTTPD in
		apache)
			if [ -f /etc/apache2/sites-available/$TARGET_SSO_MIGO_SITE ] ; then
				sudo rm /etc/apache2/sites-available/$TARGET_SSO_MIGO_SITE
			fi
			if [ -L /etc/apache2/sites-enabled/$TARGET_SSO_MIGO_SITE ] ; then
				sudo rm /etc/apache2/sites-enabled/$TARGET_SSO_MIGO_SITE
			fi
			;;
		*)
			echo
			echo "SSO::Migo::Error::Invalid httpd type: '$TARGET_SSO_MIGO_HTTPD'"
			return
			;;
	esac
	
	if [ -d /home/www-data/$TARGET_SSO_MIGO_SITE ] ; then
		sudo rm -rf /home/www-data/$TARGET_SSO_MIGO_SITE
	fi
}

sso_migo()
{
	if [ -z "$TARGET_SSO" ] ; then
		echo 
		echo "SSO::Migo::Error::TARGET_SSO not set yet"
		return
	fi
	
	local goal
	for goal in ${TARGET_SITE_GOALS[@]}
	do
		case $goal in
			clean)
				sso_migo_clean
				;;
			preinstall)
				sso_migo_preinstall
				;;
			configure)
				sso_migo_configure
				;;
			install)
				sso_migo_install
				;;
			postconfig)
				sso_migo_postconfig
				;;
			custom)
				sso_migo_custom
				;;
			backup)
				sso_migo_backup
				;;
			upgrade)
				sso_migo_upgrade
				;;
			lite)
				sso_migo_clean
				sso_migo_preinstall
				sso_migo_configure
				sso_migo_install
				;;
			all)
				sso_migo_clean
				sso_migo_preinstall
				sso_migo_configure
				sso_migo_install
				sso_migo_postconfig
				sso_migo_custom
				;;
			*)
				echo
				echo "SSO::Migo::Error::Invalid target site goal: '$goal'"
				return
				;;
		esac
	done
}
