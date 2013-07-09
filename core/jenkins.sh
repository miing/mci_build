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


ci_jenkins_upgrade()
{
	if [ -z "$TARGET_CI" ] ; then
		echo 
		echo "CI::Jenkins::Error::TARGET_CI not set yet"
		return
	fi
	
	echo 
	echo "CI::Jenkins::Info::Upgrade for site[$TARGET_CI_JENKINS_SITE]"
}

ci_jenkins_backup()
{
	if [ -z "$TARGET_CI" ] ; then
		echo 
		echo "CI::Jenkins::Error::TARGET_CI not set yet"
		return
	fi
	
	echo 
	echo "CI::Jenkins::Info::Backup for site[$TARGET_CI_JENKINS_SITE]"
}

ci_jenkins_custom()
{
	if [ -z "$TARGET_CI" ] ; then
		echo 
		echo "CI::Jenkins::Error::TARGET_CI not set yet"
		return
	fi
	
	echo 
	echo "CI::Jenkins::Info::Customize for site[$TARGET_CI_JENKINS_SITE]"
}

ci_jenkins_postconfig()
{
	if [ -z "$TARGET_CI" ] ; then
		echo 
		echo "CI::Jenkins::Error::TARGET_CI not set yet"
		return
	fi
	
	echo 
	echo "CI::Jenkins::Info::Postconfigure for site[$TARGET_CI_JENKINS_SITE]"
	
	local citop=/home/jenkins
	local config=config.xml
	local keys updated=false
	if [ ! -f $citop/$config ] ; then
		echo 
		echo "CI::Jenkins::Warning::'$config' not existing yet under '$citop'"
		#return
	fi
	
	# Configure Admin
	if [ -f $citop/$config ] ; then
		keys=(`grep -i "<useSecurity>true" $citop/$config`)
		if [ "$keys" ] ; then
			if [ "$TARGET_CI_JENKINS_SITE_ADMIN_USER" -a "$TARGET_CI_JENKINS_SITE_ADMIN_PASSWORD" ] ; then
				local ADMIN_USER="$TARGET_CI_JENKINS_SITE_ADMIN_USER"
				local ADMIN_PASSWORD="$TARGET_CI_JENKINS_SITE_ADMIN_PASSWORD"
			
				sudo /etc/init.d/jenkins restart -u $ADMIN_USER -p $ADMIN_PASSWORD
			fi
		fi
	fi
	
	# OpenID
	local url plugin_name
	if [ "$TARGET_CI_JENKINS_SITE_AUTH" = "openid" ] ; then
		if [ ! -d $citop/plugins ] ; then
			sudo -u jenkins mkdir $citop/plugins
		fi
		
		url=http://updates.jenkins-ci.org/latest/openid.hpi
		plugin_name=openid.hpi
		sudo -u jenkins wget --no-check-certificate -O $citop/plugins/$plugin_name $url
		
		updated=true
	fi
	
	if [ $updated ] ; then
		sudo /etc/init.d/jenkins restart
	fi
}

ci_jenkins_install()
{
	if [ -z "$TARGET_CI" ] ; then
		echo 
		echo "CI::Jenkins::Error::TARGET_CI not set yet"
		return
	fi
	
	echo 
	echo "CI::Jenkins::Info::Install for site[$TARGET_CI_JENKINS_SITE]"
	
	local citop=/home/jenkins
	local keys
	if [ ! -f $citop/bin/jenkins.war ] ; then
		# Create bin/logs dirs under home dir for user jenkins 
		if [ ! -d $citop/bin ] ; then
			sudo -u jenkins mkdir $citop/bin
		fi
		if [ ! -d $citop/logs ] ; then
			sudo -u jenkins mkdir $citop/logs
		fi
		
		# Set bin path to PATH
		keys=(`grep -i "$citop/bin" $citop/.bashrc 2>/dev/null`)
		if [ ! "$keys" ] ; then
			sudo -u jenkins /bin/bash -c "echo 'PATH=$citop/bin:$PATH' >>$citop/.bashrc"
		fi

		# Pick up the up-to-date version of Jenkins 
		# from http://mirrors.jenkins-ci.org/war
		# or http://mirrors.jenkins-ci.org/war/latest
		local url
		local jenkins_war=jenkins.war
		if [ -z "$TARGET_CI_JENKINS_VERSION_INSTALLED" ] ; then
			url=http://mirrors.jenkins-ci.org/war/latest
		else
			url=http://mirrors.jenkins-ci.org/war/$TARGET_CI_JENKINS_VERSION_INSTALLED
		fi
		sudo -u jenkins wget -O $citop/bin/$jenkins_war $url/$jenkins_war
	fi
	
	# Launch Jenkins daemon
	if [ ! -L /etc/init.d/jenkins ] ; then
		if [ ! -f $citop/bin/jenkins.sh ] ; then
			sudo -u jenkins cp $TARGET_SITE_CONFIG/jenkins/jenkins.sh $citop/bin/jenkins.sh
		fi
		sudo ln -snf $citop/bin/jenkins.sh /etc/init.d/jenkins
		
		if [ ! -f /etc/default/jenkins ] ; then
			sudo cp $TARGET_SITE_CONFIG/jenkins/jenkins /etc/default/jenkins
		fi
		sudo update-rc.d jenkins defaults 90 10
	fi
	keys=(`ps -ef | grep -i "^jenkins"`)
	if [ ! "$keys" ] ; then
		sudo /etc/init.d/jenkins start
	fi
}

ci_jenkins_configure()
{
	if [ -z "$TARGET_CI" ] ; then
		echo 
		echo "CI::Jenkins::Error::TARGET_CI not set yet"
		return
	fi
	
	echo 
	echo "CI::Jenkins::Info::Configure for site[$TARGET_CI_JENKINS_SITE]"
	
	# Add a new user on system which is named jenkins
	if [ ! `id -u jenkins 2>/dev/null` ] ; then
		sudo adduser \
			--system \
			--shell /bin/bash \
			--gecos 'Jenkins Continuous Integration' \
			--group \
			--disabled-password \
			--home /home/jenkins \
			jenkins
	fi
	
	case $TARGET_CI_JENKINS_HTTPD in
		apache)
			local vhconfig keys
			
			case $TARGET_CI_JENKINS_HTTPD_SCHEME in
				https)
					sudo a2enmod ssl proxy proxy_http rewrite
					
					if [ ! -f /etc/apache2/sites-available/$TARGET_CI_JENKINS_SITE ] ; then
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
						vhconfig=$TARGET_CI_JENKINS_SITE.$TARGET_CI_JENKINS_HTTPD_SCHEME
						if [ -f $TARGET_SITE_CONFIG/jenkins/$vhconfig ] ; then
							sudo cp $TARGET_SITE_CONFIG/jenkins/$vhconfig /etc/apache2/sites-available/$TARGET_CI_JENKINS_SITE
						else
							echo
							echo "CI::Jenkins::Error::No virtualhost with '$TARGET_CI_JENKINS_HTTPD_SCHEME' on $TARGET_CI_JENKINS_HTTPD"
							return
						fi
		
						# Enable virtualhost at port 443 for ssl
						keys=(`grep "^[[:space:]]NameVirtualHost \*:443" /etc/apache2/ports.conf`)
						if [ ! "$keys" ] ; then
						sudo sed -i -e "/^<IfModule mod_ssl.c>.*/a\\\tNameVirtualHost \*:443" /etc/apache2/ports.conf
						fi
						
						# Match host names with IP address
						keys=(`cat /etc/hosts | grep -i -e "^[0-9\.]*[[:space:]]*$TARGET_CI_JENKINS_SITE"`)
						if [ ! "$keys" ] ; then
						sudo bash -c "cat >>/etc/hosts <<EOF
$TARGET_CI_JENKINS_HTTPD_IPADDR $TARGET_CI_JENKINS_SITE
EOF"
						fi
					
						# Make virtualhost take effect
						sudo a2ensite $TARGET_CI_JENKINS_SITE
						sudo a2dissite default
						sudo /etc/init.d/apache2 restart
					fi
					;;
				*)
					echo 
					echo "CI::Jenkins::Error::Invalid httpd scheme: '$TARGET_CI_JENKINS_HTTPD_SCHEME'"
					return
					;;
			esac
			;;
		*)
			echo
			echo "CI::Jenkins::Error::Invalid httpd type: '$TARGET_CI_JENKINS_HTTPD'"
			return
			;;
	esac
}

ci_jenkins_preinstall()
{
	if [ -z "$TARGET_CI" ] ; then
		echo 
		echo "CI::Jenkins::Error::TARGET_CI not set yet"
		return
	fi
	
	echo 
	echo "CI::Jenkins::Info::Preinstall for site[$TARGET_CI_JENKINS_SITE]"
	
	if [ -n "$TARGET_CI_JENKINS_HTTPD" ] ; then
		httpd $TARGET_CI_JENKINS_HTTPD
	fi
	if [ "$TARGET_CI_JENKINS_HTTPD_SCHEME" = "https" ] ; then
		if [[ ! `which ssh` || ! `which sshd` ]] ; then
			sudo apt-get -y install openssh-client openssh-server
		
			# After installation of ssh client/server, I would like to generate
			# new ssh public/private key pair, although the key pair may have
			# been already there for some reason.
			# ssh-keygen -t rsa
			ssh-add
		fi
	fi
	
	# Set up JAVA runtime environment oh which Jenkins runs
	if [ ! `which java` ] ; then
		sudo apt-get -y install openjdk-6-jdk
	fi
}

ci_jenkins_clean()
{
	if [ -z "$TARGET_CI" ] ; then
		echo 
		echo "CI::Jenkins::Error::TARGET_CI not set yet"
		return
	fi
	
	echo 
	echo "CI::Jenkins::Info::Clean for site[$TARGET_CI_JENKINS_SITE]"
	
	local keys
	keys=(`ps -ef | grep -i "^jenkins"`)
	if [ "$keys" ] ; then
		sudo /etc/init.d/jenkins stop
	fi
	if [ -L /etc/init.d/jenkins ] ; then
		sudo rm /etc/init.d/jenkins
		
		if [ -f /etc/default/jenkins ] ; then
			sudo rm /etc/default/jenkins
		fi
	fi
			
	case $TARGET_CI_JENKINS_HTTPD in
		apache)
			if [ -f /etc/apache2/sites-available/$TARGET_CI_JENKINS_SITE ] ; then
				sudo rm /etc/apache2/sites-available/$TARGET_CI_JENKINS_SITE
			fi
			if [ -L /etc/apache2/sites-enabled/$TARGET_CI_JENKINS_SITE ] ; then
				sudo rm /etc/apache2/sites-enabled/$TARGET_CI_JENKINS_SITE
			fi
			;;
		*)
			echo
			echo "CI::Jenkins::Error::Invalid httpd type: '$TARGET_CI_JENKINS_HTTPD'"
			return
			;;
	esac
	
	if [ `id -u jenkins 2>/dev/null` ] ; then
		sudo deluser jenkins
	fi
	if [ -d /home/jenkins ] ; then
		sudo rm -rf /home/jenkins
	fi
}

ci_jenkins()
{
	if [ -z "$TARGET_CI" ] ; then
		echo 
		echo "CI::Jenkins::Error::TARGET_CI not set yet"
		return
	fi
	
	local goal
	for goal in ${TARGET_SITE_GOALS[@]}
	do
		case $goal in
			clean)
				ci_jenkins_clean
				;;
			preinstall)
				ci_jenkins_preinstall
				;;
			configure)
				ci_jenkins_configure
				;;
			install)
				ci_jenkins_install
				;;
			postconfig)
				ci_jenkins_postconfig
				;;
			custom)
				ci_jenkins_custom
				;;
			backup)
				ci_jenkins_backup
				;;
			upgrade)
				ci_jenkins_upgrade
				;;
			lite)
				ci_jenkins_clean
				ci_jenkins_preinstall
				ci_jenkins_configure
				ci_jenkins_install
				;;
			all)
				ci_jenkins_clean
				ci_jenkins_preinstall
				ci_jenkins_configure
				ci_jenkins_install
				ci_jenkins_postconfig
				ci_jenkins_custom
				;;
			*)
				echo
				echo "CI::Jenkins::Error::Invalid target site goal: '$goal'"
				return
				;;
		esac
	done
}
