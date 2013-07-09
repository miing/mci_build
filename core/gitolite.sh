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


scmr_gitolite_upgrade()
{
	if [ -z "$TARGET_SCMR" ] ; then
		echo 
		echo "** TARGET_SCMR not set yet. Check your site specs to fix it."
		return
	fi
}

scmr_gitolite_backup()
{
	if [ -z "$TARGET_SCMR" ] ; then
		echo 
		echo "** TARGET_SCMR not set yet. Check your site specs to fix it."
		return
	fi
}

scmr_gitolite_custom()
{
	if [ -z "$TARGET_SCMR" ] ; then
		echo 
		echo "** TARGET_SCMR not set yet. Check your site specs to fix it."
		return
	fi
}

scmr_gitolite_postconfig()
{
	if [ -z "$TARGET_SCMR" ] ; then
		echo 
		echo "** TARGET_SCMR not set yet. Check your site specs to fix it."
		return
	fi
}

scmr_gitolite_install() 
{
	if [ -z "$TARGET_SCMR" ] ; then
		echo 
		echo "** TARGET_SCMR not set yet. Check your site specs to fix it."
		return
	fi
	
	##################################################################
	# Here SCM is chosen to use git and Gitolite and git-web storing #
	# and managing and manipulating and browsing source code in git  #
	# repositories.													 #
	# Notice that web server has already been installed on your      #
	# workstation before you can browse all the git repositories by  #
	# your favorite browser.                                         #
	##################################################################
	
	local site ipaddr
	local default_site=git.xbmlabs.org
	local default_ipaddr=127.0.0.1
	
	site=$1
	if [ ! "$site" ] ; then
		site=$default_site
	fi
	ipaddr=$2
	if [ ! "$ipaddr" ] ; then
		ipaddr=$default_ipaddr
	fi
	
	echo 
	echo "Installing for site[$site]@IPaddr[$ipaddr]..."
	
	# Install and configure git
	if [ ! `which git` ] ; then
		sudo apt-get -y install git-core git-doc
		
		local na em ed
		local gconf=~/.gitconfig
		if [[ ! -f $gconf || -z "`grep "name" $gconf 2>/dev/null`" || -z "`grep "email" $gconf 2>/dev/null`" || -z "`grep "editor" $gconf 2>/dev/null`" ]] ; then
			echo 
			echo "Configuring git..."
			na= em= ed=
			while [ -z $na ] ; do
				echo -n "Your user name is: " ; read na
			done
			while [ -z $em ] ; do
				echo -n "Your user email is: " ; read em
			done
			while [ -z $ed ] ; do
				echo -n "Your core editor is: " ; read ed
			done
		
			git config --global user.name "$na"
			git config --global user.email $em
			git config --global core.editor $ed
			git config --global color.ui true
		fi
	fi
	
	# For the sake of gitolite using ssh keys to access and manage git 
	# repositories, so have to first install ssh client and server and
	# then generate public key via ssh.
	if [[ ! `which ssh` || ! `which sshd` ]] ; then
		sudo apt-get -y install openssh-client openssh-server
		
		# After installation of ssh client/server, I would like to generate
		# new ssh public/private key pair, although the key pair may have
		# been already there for some reason.
		ssh-keygen -t rsa
		ssh-add
	fi
	
	# Add a git user
	if [ ! `id -u git 2>/dev/null` ] ; then
		sudo adduser \
    		--system \
    		--shell /bin/bash \
    		--gecos 'Git Source Code Management' \
    		--group \
    		--disabled-password \
    		--home /home/git \
    		git
    	
    	# Add www-data to git group so that www-data can access git repositories.
		sudo adduser www-data git
	fi
	
	# Install and configure gitolite. And, assuming that this user with the public key 
	# (id_rsa.pub) located under $HOME/.ssh/ acts as an administrator that takes the whole
	# control of gitolite. Of course, you can also specify one more user doing such jobs.
	# Note that the following method is inspired by the two links, 
	# http://www.frederikkonietzny.de/2012/08/how-to-install-gitolite-and-
	# git-web-on-ubuntu-12-04, and 
	# http://blog.countableset.ch/2012/04/29/ubuntu-12-dot-04-installing-gitolite-and-gitweb/
	if [ ! -f /home/git/bin/gitolite ] ; then
		# Construct empty files as well as directories for ssh under git home
		if [ ! -d "/home/git/.ssh" ] ; then
			sudo -H -u git mkdir /home/git/.ssh
			sudo -H -u git touch /home/git/.ssh/authorized_keys
			sudo -H -u git chmod 700 /home/git/.ssh
			sudo -H -u git chmod 600 /home/git/.ssh/authorized_keys
		fi	
		
		if [ ! -d "/home/git/bin" ] ; then
			sudo -H -u git mkdir /home/git/bin
			if [ ! "`grep "/home/git/bin" /home/git/.bashrc 2>/dev/null`" ] ; then
				sudo -H -u git /bin/bash -c "echo PATH=/home/git/bin:$PATH >>/home/git/.bashrc"
			fi
		fi
		
		local pubkey
		local default_pubkey=~/.ssh/id_rsa.pub
		sudo -H -u git git clone git://github.com/sitaramc/gitolite.git /home/git/gitolite
		sudo -H -u git /home/git/gitolite/install -to /home/git/bin
		if [ ! "$3" ] ; then
			pubkey=$default_pubkey
		else
			pubkey=$3
		fi
		scp $pubkey /tmp/so.pub
		sudo -H -u git /home/git/bin/gitolite setup -pk /tmp/so.pub
		sudo -H -u git rm -rf /home/git/gitolite
		# Change the default value of UMASK from "0077" to "0027" so that gitweb can 
		# access all these repos when browsing them via browser.
		# sudo -H -u git sed -i.bak -e "s/0077/0027/" /home/git/.gitolite.rc
	fi
	
	# Set up and configure git daemon
	# Note that the following method is inspired by the link, 
	# http://computercamp.cdwilson.us/git-gitolite-git-daemon-gitweb-setup-on-ubunt
#	if [ ! -f /etc/sv/git-daemon/run ] ; then
#		sudo apt-get install git-daemon-run
#		sudo sed -i.bak -e "s/\(-u[a-z]*\)/\1:git \\\/" -e "s/\(.*=\).*/\1\/home\/git\/repositories \/home\/git\/repositories/" /etc/sv/git-daemon/run
#		sudo sv restart git-daemon
#	fi

	# This way of git-daemon-run package provided by Ubuntu, I wouldn't really like it.
	# So, the standard init.d script way of making git-daemon running is inspired by the 
	# link, http://ao2.it/wiki/How_to_setup_a_GIT_server_with_gitosis_and_gitweb.
	if [ ! -f /etc/init.d/git-daemon ] ; then
		sudo cp $WORKSPACE_SCRIPTS_PATH/xbml/scmserver/git-daemon /etc/init.d/git-daemon
		sudo chmod a+x /etc/init.d/git-daemon
		
		if [ ! -f /etc/default/git-daemon ] ; then
			sudo cp $WORKSPACE_SCRIPTS_PATH/xbml/scmserver/git-daemon.conf \
			/etc/default/git-daemon
		fi
		sudo update-rc.d git-daemon defaults
	fi
	
	# Set up gitweb
	if [ ! -f /etc/gitweb.conf ] ; then
		sudo apt-get install gitweb highlight
#		sudo sed -i.bak -e 's/\(^\$projectroot\).*/\1 = \"\/home\/git\/repositories\"/' -e 's/\(^\$projects_list\).*/\1 = \"\/home\/git\/projects\.list\"/' /etc/gitweb.conf
	fi

	# I would prefer to set up a separate directory for putting together all those things,
	# pertaining to gitweb configuration beneath /home/git directory, so that I could leave 
	# these standard gitweb settings in /etc/gitweb.conf intact.
	if [ ! -f /home/git/gitweb/gitweb.conf ] ; then
		if [ ! -d /home/git/gitweb ] ; then
			sudo -H -u git mkdir /home/git/gitweb
		fi
		
		sudo -H -u git cp $WORKSPACE_SCRIPTS_PATH/xbml/scmserver/gitweb.conf \
		/home/git/gitweb/gitweb.conf
		
		if [ ! -f /home/git/gitweb/headertext.html ] ; then
			sudo -H -u git cp $WORKSPACE_SCRIPTS_PATH/xbml/scmserver/headertext.html \
			/home/git/gitweb/headertext.html
		fi
	fi
	
	# Configure a virtual host for git on apache server
	if [ ! -f /etc/apache2/sites-available/$site ] ; then
		sudo cp $WORKSPACE_SCRIPTS_PATH/xbml/scmserver/$site \
		/etc/apache2/sites-available/$site
	fi
	
	# Match host names with IP address
	local keys=(`cat /etc/hosts | grep -i -e "^[0-9\.]*[[:space:]]*$site"`)
	if [ ! "$keys" ] ; then
		sudo bash -c "cat >>/etc/hosts <<EOF
$ipaddr $site
EOF"
	fi
	
	# Make virtual host configuration to Apache take effect
	sudo a2enmod rewrite
	sudo a2ensite $site
	sudo a2dissite default
	sudo /etc/init.d/apache2 restart
}

scmr_gitolite_configure()
{
	if [ -z "$TARGET_SCMR" ] ; then
		echo 
		echo "** TARGET_SCMR not set yet. Check your site specs to fix it."
		return
	fi
}

scmr_gitolite_preinstall()
{
	if [ -z "$TARGET_SCMR" ] ; then
		echo 
		echo "** TARGET_SCMR not set yet. Check your site specs to fix it."
		return
	fi
}

scmr_gitolite_clean()
{
	if [ -z "$TARGET_SCMR" ] ; then
		echo 
		echo "** TARGET_SCMR not set yet. Check your site specs to fix it."
		return
	fi
}

scmr_gitolite()
{
	if [ -z "$TARGET_SCMR" ] ; then
		echo 
		echo "** TARGET_SCMR not set yet. Check your site specs to fix it."
		return
	fi
	
	local goal
	for goal in ${TARGET_SITE_GOALS[@]}
	do
		case $goal in
			clean)
				scmr_gitolite_clean
				;;
			preinstall)
				scmr_gitolite_preinstall
				;;
			configure)
				scmr_gitolite_configure
				;;
			install)
				scmr_gitolite_install
				;;
			postconfig)
				scmr_gitolite_postconfig
				;;
			custom)
				scmr_gitolite_custom
				;;
			backup)
				scmr_gitolite_backup
				;;
			upgrade)
				scmr_gitolite_upgrade
				;;
			lite)
				scmr_gitolite_clean
				scmr_gitolite_preinstall
				scmr_gitolite_configure
				scmr_gitolite_install
				;;
			all)
				scmr_gitolite_clean
				scmr_gitolite_preinstall
				scmr_gitolite_configure
				scmr_gitolite_install
				scmr_gitolite_postconfig
				scmr_gitolite_custom
				;;
			*)
				echo
				echo "** Invalid TARGET SITE GOALS: '$goal'"
				return
				;;
		esac
	done
}
