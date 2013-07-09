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


cms_custom_install()
{	
	if [ -z "$TARGET_CMS" ] ; then
		echo 
		echo "CMS::Custom::Error::TARGET_CMS not set yet"
		return
	fi
	
	echo 
	echo "CMS::Custom::Info::Install for site[$TARGET_CMS_CUSTOM_SITE]"
	
	# Serve up your site
	local cmstop=/home/www-data/$TARGET_CMS_CUSTOM_SITE
	if [ ! -d $cmstop ] ; then
		sudo -u www-data mkdir $cmstop
	fi
	local cmscustom_source=$TARGET_SITE_CONFIG/cmscustom/$TARGET_CMS_CUSTOM_SITE
	if [ -d $cmscustom_source ] ; then
		sudo -u www-data cp -R $cmscustom_source/* $cmstop
	else
		echo 
		echo "CMS::Custom::Error::Target site source not existing yet"
		return
	fi
}

cms_custom_configure()
{
	if [ -z "$TARGET_CMS" ] ; then
		echo 
		echo "CMS::Custom::Error::TARGET_CMS not set yet"
		return
	fi
	
	echo
	echo "CMS::Custom::Info::Configure for site[$TARGET_CMS_CUSTOM_SITE]"
	
	case $TARGET_CMS_CUSTOM_HTTPD in
		apache)
			local vhconfig keys
			
			case $TARGET_CMS_CUSTOM_HTTPD_SCHEME in
				http)
					sudo a2enmod rewrite
					
					if [ ! -f /etc/apache2/sites-available/$TARGET_CMS_CUSTOM_SITE ] ; then
						# Configure virtualhost
						vhconfig=$TARGET_CMS_CUSTOM_SITE.$TARGET_CMS_CUSTOM_HTTPD_SCHEME
						if [ -f $TARGET_SITE_CONFIG/cmscustom/$vhconfig ] ; then
							sudo cp $TARGET_SITE_CONFIG/cmscustom/$vhconfig /etc/apache2/sites-available/$TARGET_CMS_CUSTOM_SITE
						else
							echo
							echo "CMS::Custom::Error::No virtualhost with '$TARGET_CMS_CUSTOM_HTTPD_SCHEME' on $TARGET_CMS_CUSTOM_HTTPD"
							return
						fi
						
						# Match host names with IP address
						keys=(`cat /etc/hosts | grep -i -e "^[0-9\.]*[[:space:]]*$TARGET_CMS_CUSTOM_SITE"`)
						if [ ! "$keys" ] ; then
							sudo bash -c "cat >>/etc/hosts <<EOF
$TARGET_CMS_CUSTOM_HTTPD_IPADDR $TARGET_CMS_CUSTOM_SITE
$TARGET_CMS_CUSTOM_HTTPD_IPADDR www.$TARGET_CMS_CUSTOM_SITE
EOF"
						fi
					
						# Make virtualhost take effect
						sudo a2ensite $TARGET_CMS_CUSTOM_SITE
						sudo a2dissite default
						sudo /etc/init.d/apache2 restart
					fi
					;;
				https)
					sudo a2enmod ssl rewrite
					if [ ! -f /etc/apache2/sites-available/$TARGET_CMS_CUSTOM_SITE ] ; then
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
						vhconfig=$TARGET_CMS_CUSTOM_SITE.$$TARGET_CMS_CUSTOM_HTTPD_SCHEME
						if [ -f $TARGET_SITE_CONFIG/cmscustom/$vhconfig ] ; then
							sudo cp $TARGET_SITE_CONFIG/cmscustom/$vhconfig /etc/apache2/sites-available/$TARGET_CMS_CUSTOM_SITE
						else
							echo
							echo "CMS::Custom::Error::No virtualhost with '$TARGET_CMS_CUSTOM_HTTPD_SCHEME' on $TARGET_CMS_CUSTOM_HTTPD"
							return
						fi
		
						# Enable virtualhost at port 443 for ssl
						keys=(`grep "^[[:space:]]NameVirtualHost \*:443" /etc/apache2/ports.conf`)
						if [ ! "$keys" ] ; then
							sudo sed -i -e "/^<IfModule mod_ssl.c>.*/a\\\tNameVirtualHost \*:443" /etc/apache2/ports.conf
						fi
						
						# Match host names with IP address
						keys=(`cat /etc/hosts | grep -i -e "^[0-9\.]*[[:space:]]*$TARGET_CMS_CUSTOM_SITE"`)
						if [ ! "$keys" ] ; then
							sudo bash -c "cat >>/etc/hosts <<EOF
$TARGET_CMS_CUSTOM_HTTPD_IPADDR $TARGET_CMS_CUSTOM_SITE
$TARGET_CMS_CUSTOM_HTTPD_IPADDR www.$TARGET_CMS_CUSTOM_SITE
EOF"
						fi
					
						# Make virtualhost take effect
						sudo a2ensite $TARGET_CMS_CUSTOM_SITE
						sudo a2dissite default
						sudo /etc/init.d/apache2 restart
					fi
					;;
				*)
					echo 
					echo "CMS::Custom::Error::Invalid httpd scheme: '$TARGET_CMS_CUSTOM_HTTPD_SCHEME'"
					return
					;;
			esac
			;;
		*)
			echo
			echo "CMS::Custom::Error::Invalid httpd type: '$TARGET_CMS_CUSTOM_HTTPD'"
			return
			;;
	esac
}

cms_custom_preinstall()
{
	if [ -z "$TARGET_CMS" ] ; then
		echo 
		echo "CMS::Custom::Error::TARGET_CMS not set yet"
		return
	fi
	
	echo
	echo "CMS::Custom::Info::Preinstall for site[$TARGET_CMS_CUSTOM_SITE]"
	
	if [ -n "$TARGET_CMS_CUSTOM_HTTPD" ] ; then
		httpd $TARGET_CMS_CUSTOM_HTTPD
	fi
	if [ -n "$TARGET_CMS_CUSTOM_DBENGINE" ] ; then
		dbengine $TARGET_CMS_CUSTOM_DBENGINE
	fi
}

cms_custom_clean()
{
	if [ -z "$TARGET_CMS" ] ; then
		echo 
		echo "CMS::Custom::Error::TARGET_CMS not set yet"
		return
	fi
	
	echo
	echo "CMS::Custom::Info::Clean for site[$TARGET_CMS_CUSTOM_SITE]"
			
	case $TARGET_CMS_CUSTOM_HTTPD in
		apache)
			if [ -f /etc/apache2/sites-available/$TARGET_CMS_CUSTOM_SITE ] ; then
				sudo rm /etc/apache2/sites-available/$TARGET_CMS_CUSTOM_SITE
			fi
			if [ -L /etc/apache2/sites-enabled/$TARGET_CMS_CUSTOM_SITE ] ; then
				sudo rm /etc/apache2/sites-enabled/$TARGET_CMS_CUSTOM_SITE
			fi
			;;
		*)
			echo
			echo "CMS::Custom::Error::Invalid httpd type: '$TARGET_CMS_CUSTOM_HTTPD'"
			return
			;;
	esac
	
	if [ -d /home/www-data/$TARGET_CMS_CUSTOM_SITE ] ; then
		sudo rm -rf /home/www-data/$TARGET_CMS_CUSTOM_SITE
	fi
}

cms_custom()
{
	if [ -z "$TARGET_CMS" ] ; then
		echo 
		echo "CMS::Custom::Error::TARGET_CMS not set yet"
		return
	fi
	
	local goal
	for goal in ${TARGET_SITE_GOALS[@]}
	do
		case $goal in
			clean)
				cms_custom_clean
				;;
			preinstall)
				cms_custom_preinstall
				;;
			configure)
				cms_custom_configure
				;;
			install)
				cms_custom_install
				;;
			lite)
				cms_custom_clean
				cms_custom_preinstall
				cms_custom_configure
				cms_custom_install
				;;
			all)
				cms_custom_clean
				cms_custom_preinstall
				cms_custom_configure
				cms_custom_install
				;;
			*)
				echo
				echo "CMS::Custom::Error::Invalid target site goal: '$goal'"
				return
				;;
		esac
	done
}
