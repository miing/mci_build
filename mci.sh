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
#
#  MCI Project is the system that is used to deploy an infrastructure of  
#  development(Dev), operations(Ops) and quality assurance(QA) for 
#  communication, collaboration and integration between developers and
#  information technology professionals in organizations.
#  And, for now, Miing.org has been taking advantage of deploying such
#  infrastructure.
#
#  Note that all functions in the below are tested on Ubuntu 10.04 (LTS), 
#  but please check yourself out in the system different from the specified 
#  distribution above if errors or warnings are shown when running this 
#  script on it. Or, look at Miing.org to try to seek for help.
#  
#############################################################################

# Print help message
function hmci() 
{
cat <<EOF
Invoke ". build/mci.sh" from your shell to add the following functions to your environment:
- hmci: 	Print help message
- turnkey: 	Choose target site(s)
- launch: 	Deploy target site(s)
EOF
}

# Get the top path for the whole project
function get_mcitop() 
{
	local topfile=build/mci.sh
    if [ -n "$MCITOP" -a -f "$MCITOP/$topfile" ] ; then
        echo $MCITOP
    else
        if [ -f $topfile ] ; then
            # The following circumlocution (repeated below as well) ensures
            # that we record the true directory name and not one that is
            # faked up with symlink names.
            PWD= /bin/pwd
        else
            # We redirect cd to /dev/null in case it's aliased to
            # a command that prints something as a side-effect
            # (like pushd)
            local here=$PWD
            local top=
            while [ \( ! \( -f $topfile \) \) -a \( $PWD != "/" \) ]; do
                cd .. > /dev/null
                top=`PWD= /bin/pwd`
            done
            cd $here > /dev/null
            if [ -f "$top/$topfile" ]; then
                echo $top
            fi
        fi
    fi
}

# Switch current directory to the top of the tree
function mcitop()
{
    local top=$(get_mcitop)
    if [ "$top" ] ; then
        cd $top
    else
        echo "Couldn't locate the top of the tree.  Try setting MCITOP."
    fi
}

# Clear this variable every time running this script file. 
# And then it will be set when the vendorsetup.sh files 
# are included at the end of the file.
unset TURNKEY_MENU_CHOICES

# Collect every turnkey available
function add_turnkey_combo()
{
	local new_combo=$1
    local c
    for c in ${TURNKEY_MENU_CHOICES[@]} ; do
        if [ "$new_combo" = "$c" ] ; then
            return
        fi
    done
    TURNKEY_MENU_CHOICES=(${TURNKEY_MENU_CHOICES[@]} $new_combo)
}

# Add all default turnkeys from here
add_turnkey_combo full-lite

# List all turnkeys available 
function print_turnkey_menu()
{
	echo
    echo "TURNKEY menu... pick a combo:"

    local i=1
    local choice
    for choice in ${TURNKEY_MENU_CHOICES[@]}
    do
        echo "     $i. $choice"
        i=$(($i+1))
    done
}

# Here "lite" means executing the first four goals in the list below,
# while "all" doing every goal respectively, except for backup, upgrade,
# and lite.
GOALS_CHOICES=(\
	clean \
	preinstall \
	configure \
	install \
	postconfig \
	custom \
	backup \
	upgrade \
	lite \
	all)

# Check if the specified goals are valid
function check_goals()
{
	local target_goal default_goal
	local is_valid
	local PASSED_GOALS=(`echo "$@"`)
	for target_goal in ${PASSED_GOALS[@]}
	do
		for default_goal in ${GOALS_CHOICES[@]}
    	do
		    if [ "$target_goal" = "$default_goal" ] ; then
		        is_valid=0
		        break 1
		    else
		    	is_valid=1
		    fi
    	done
	done
    return $is_valid
}

# Here "full" means building every component selected in site speces.
LMS_CHOICES=(\
	sentry)
SSO_CHOICES=(\
	migo)
CMS_CHOICES=(\
	drupal \
	mediawiki \
	cmscustom)
ITS_CHOICES=(\
	bugzilla)
SCMR_CHOICES=(\
	gerrit \
	gitolite)
CI_CHOICES=(\
	jenkins)
COMPONENT_CHOICES=(\
	# LMS
	${LMS_CHOICES[@]} \
	# SSO
	${SSO_CHOICES[@]} \
	# CMS
	${CMS_CHOICES[@]} \
	# ITS
	${ITS_CHOICES[@]} \
	# SCMR
	${SCMR_CHOICES[@]} \
	# CI
	${CI_CHOICES[@]} \
	full)

# Check if the supplied components are valid
function check_components()
{
	local target_comp default_comp
	local is_valid
	local PASSED_COMPS=(`echo "$@"`)
	for target_comp in ${PASSED_COMPS[@]}
	do
		for default_comp in ${COMPONENT_CHOICES[@]}
    	do
		    if [ "$target_comp" = "$default_comp" ] ; then
		        is_valid=0
		        break 1
		    else
		    	is_valid=1
		    fi
    	done
	done
    return $is_valid
}

# Bring in two variables, SITE_SPECS_HEADER and SITE_SPECS_BODY, which are used
# to construct a set of site specs variables for MCI_ and TARGET_ individually.
# Let's say, $SITE_SPECS_HEADER_$SITE_SPECS_BODY.
SITE_SPECS_HEADER=(\
	MCI \
	TARGET)
SITE_SPECS_BODY=(\
	SITE_NAME \
	SITE_CONFIG \
	SITE_THEMES \
	DBENGINE_MYSQL_ROOTPW \
	DBENGINE_MYSQL_HOST \
	DBENGINE_PGSQL_ROOTPW \
	DBENGINE_PGSQL_HOST \
	WEBSERVER_APACHE2_OWNER \
	WEBSERVER_APACHE2_OWNER_HOME \
	WEBSERVER_APACHE2_OWNER_SHELL \
	LMS \
	LMS_URL \
	LMS_IPADDR \
	LMS_PORT \
	LMS_SENTRY_SITE \
	LMS_SENTRY_URL \
	LMS_SENTRY_WEBSERVER \
	LMS_SENTRY_DBENGINE \
	LMS_SENTRY_POSTGRESQL_VERSION_REQUIRED \
	LMS_SENTRY_PGSQL_DBNAME \
	LMS_SENTRY_PGSQL_DBUSER \
	LMS_SENTRY_PGSQL_DBPW \
	SSO \
	SSO_URL \
	SSO_IPADDR \
	SSO_PORT \
	SSO_MIGO_SITE \
	SSO_MIGO_URL \
	SSO_MIGO_WEBSERVER \
	SSO_MIGO_DBENGINE \
	SSO_MIGO_POSTGRESQL_VERSION_REQUIRED \
	CMS \
	CMS_URL \
	CMS_IPADDR \
	CMS_PORT \
	CMS_DRUPAL_SITE \
	CMS_DRUPAL_WEBSERVER \
	CMS_DRUPAL_DBENGINE \
	CMS_CUSTOM_SITE \
	CMS_CUSTOM_SOURCE \
	CMS_CUSTOM_WEBSERVER \
	CMS_CUSTOM_DBENGINE \
	CMS_MEDIAWIKI_SITE \
	CMS_MEDIAWIKI_WEBSERVER \
	CMS_MEDIAWIKI_DBENGINE \
	CMS_MEDIAWIKI_MYSQL_DBNAME \
	CMS_MEDIAWIKI_MYSQL_DBUSER \
	CMS_MEDIAWIKI_MYSQL_DBPW \
	CMS_MEDIAWIKI_VERSION_INSTALLED \
	CMS_MEDIAWIKI_VERSION_UPDATED \
	CMS_MEDIAWIKI_URL \
	CMS_MEDIAWIKI_AUTH \
	ITS \
	ITS_URL \
	ITS_IPADDR \
	ITS_PORT \
	ITS_BUGZILLA_SITE \
	ITS_BUGZILLA_WEBSERVER \
	ITS_BUGZILLA_DBENGINE \
	ITS_BUGZILLA_MYSQL_DBNAME \
	ITS_BUGZILLA_MYSQL_DBUSER \
	ITS_BUGZILLA_MYSQL_DBPW \
	ITS_BUGZILLA_VERSION_INSTALLED \
	ITS_BUGZILLA_VERSION_UPDATED \
	ITS_BUGZILLA_AUTH \
	SCMR \
	SCMR_URL \
	SCMR_IPADDR \
	SCMR_PORT \
	SCMR_GERRIT_SITE \
	SCMR_GERRIT_WEBSERVER \
	SCMR_GERRIT_DBENGINE \
	SCMR_GERRIT_MYSQL_DBNAME \
	SCMR_GERRIT_MYSQL_DBUSER \
	SCMR_GERRIT_MYSQL_DBPW \
	SCMR_GERRIT_VERSION_INSTALLED \
	SCMR_GERRIT_VERSION_UPDATED \
	SCMR_GERRIT_AUTH \
	SCMR_GERRIT_OPENIDSSO_URL \
	SCMR_GERRIT_HTTPBASIC_ADMIN \
	SCMR_GERRIT_WEBFRONT \
	SCMR_GERRIT_SSH_CONFIG \
	SCMR_GERRIT_SSHGIT_USER \
	SCMR_GERRIT_SSHGIT_EMAIL \
	SCMR_GERRIT_GIT_EDITOR \
	SCMR_GERRIT_THEME \
	SCMR_GITOLITE_SITE \
	SCMR_GITOLITE_WEBSERVER \
	SCMR_GITOLITE_DBENGINE \
	CI \
	CI_URL \
	CI_IPADDR \
	CI_PORT \
	CI_JENKINS_SITE \
	CI_JENKINS_WEBSERVER \
	CI_JENKINS_DBENGINE)

# Clean all values in the specs
function clean_specs()
{
	local header body
	local underline=_
	
	for header in $@
	do
		for body in ${SITE_SPECS_BODY[@]}
		do
			unset $header$underline$body
		done
	done
}

# Print all values in the specs
function show_specs()
{
	local header body
	local underline=_
	
	for header in $@
	do
		for body in ${SITE_SPECS_BODY[@]}
		do
			echo $header$underline$body=$(eval "echo \${$(echo $header$underline$body)[@]}")
		done
	done
}

# Get all values from $2(MCI_) to $1(TARGET_)
function copy_specs()
{
	local target_header mci_header body
	local underline=_
	
	target_header=$1
	mci_header=$2
	if [ "$target_header" = "TARGET" -a "$mci_header" = "MCI" ] ; then
		clean_specs TARGET
		for body in ${SITE_SPECS_BODY[@]}	
		do
			eval $target_header$underline$body='$(eval "echo \${$(echo $mci_header$underline$body)[@]}")'
		done
	fi
}

# Fine tune site specs to exactly coincide with
# what is provided by turnkey although your original specs 
# most likely contains more than turnkey.
function round_specs()
{
	# First backup all values of all target components, and
	# then clear them up to obtain the specified values 
	# by means of turnkey invoked before.
	local BACKUP_LMS=${TARGET_LMS[@]}
	local BACKUP_SSO=${TARGET_SSO[@]}
	local BACKUP_CMS=${TARGET_CMS[@]}
	local BACKUP_ITS=${TARGET_ITS[@]}
	local BACKUP_SCMR=${TARGET_SCMR[@]}
	local BACKUP_CI=${TARGET_CI[@]}
	TARGET_LMS=
	TARGET_SSO=
	TARGET_CMS=
	TARGET_ITS=
	TARGET_SCMR=
	TARGET_CI=
	
	# Clear up all backup vars if any component is provided via turnkey.
	local comp
	for comp in ${TARGET_SITE_COMPONENTS[@]}
	do
		if [ "$comp" = "sentry" ] ; then
			BACKUP_LMS=
		elif [ "$comp" = "migo" ] ; then
			BACKUP_SSO=
		elif [ "$comp" = "drupal" -o "$comp" = "cmscustom" -o "$comp" = "mediawiki" ] ; then
			BACKUP_CMS=
		elif [ "$comp" = "bugzilla" ] ; then
			BACKUP_ITS=
		elif [ "$comp" = "gerrit" -o "$comp" = "gitolite" ] ; then
			BACKUP_SCMR=
		elif [ "$comp" = "jenkins" ] ; then
			BACKUP_CI=
		fi
	done
	
	# Fill in these target component vars according to turnkey, 
	# instead of from your site specs.
	for comp in ${TARGET_SITE_COMPONENTS[@]}
	do
		if [ "$comp" = "full" ] ; then
			TARGET_LMS=${BACKUP_LMS[@]}
			TARGET_SSO=${BACKUP_SSO[@]}
			TARGET_CMS=${BACKUP_CMS[@]}
			TARGET_SCMR=${BACKUP_SCMR[@]}
			TARGET_CI=${BACKUP_CI[@]}
			TARGET_ITS=${BACKUP_ITS[@]}
		elif [ "$comp" = "sentry" ] ; then
			TARGET_LMS=(${TARGET_LMS[@]} $comp)
		elif [ "$comp" = "migo" ] ; then
			TARGET_SSO=(${TARGET_SSO[@]} $comp)
		elif [ "$comp" = "drupal" -o "$comp" = "cmscustom" -o "$comp" = "mediawiki" ] ; then
			TARGET_CMS=(${TARGET_CMS[@]} $comp)
		elif [ "$comp" = "bugzilla" ] ; then
			TARGET_ITS=(${TARGET_ITS[@]} $comp)
		elif [ "$comp" = "gerrit" -o "$comp" = "gitolite" ] ; then
			TARGET_SCMR=(${TARGET_SCMR[@]} $comp)
		elif [ "$comp" = "jenkins" ] ; then
			TARGET_CI=(${TARGET_CI[@]} $comp)
		fi
	done
}

# Obtain certain value from the last specs
function get_specs_var()
{
	local header body
	
	header=$1
	body=$2
	underline=_
	
	echo $(eval "echo \${$(echo $header$underline$body)[@]}")
}

# Inherit all features from the specified specs
function inherit_specs()
{
	include_specs $1
}

# Include the specified specs with relative path into the current environment
function include_specs()
{
	. $1
}

# Check if the specified site is the one we can set up
function check_site()
{
	local toppath specs site
	local default_site=mci.org
	
	toppath=$(get_mcitop)
    if [ ! "$toppath" ]; then
        echo "Couldn't locate the top of the tree.  Try setting MCITOP." >&2
        return
    fi
	
	if [ "$1" = "full" ] ; then
		specs=(`ls build/*/$1.sh`)
		include_specs $specs
		site=$(get_specs_var MCI SITE_NAME)
		clean_specs MCI
		if [ "$site" = "$default_site" ] ; then
			return 0
		else
			return 1
		fi
	else
		specs=(`ls sites/*/*/$1.sh`)
		include_specs $specs
		site=$(get_specs_var MCI SITE_NAME)
		clean_specs MCI
		if [ "$site" = "$1" ] ; then
			return 0
		else
			return 1
		fi
	fi
}

# Choose target site
function turnkey()
{
	local answer selection 
	local site components goals

    if [ "$1" ] ; then
        answer=$1
    else
        print_turnkey_menu
        echo -n "Which would you like? [full-lite] "
        read answer
    fi

    if [ -z "$answer" ] ; then
        selection=full-all
    elif (echo -n $answer | grep -q -e "^[0-9][0-9]*$") ; then
        if [ $answer -le ${#TURNKEY_MENU_CHOICES[@]} ] ; then
            selection=${TURNKEY_MENU_CHOICES[$(($answer-1))]}
        fi
    elif (echo -n $answer | grep -q -e "^[^\-][^\-]*-[^\-][^\-]*$") ; then
        selection=$answer
    fi

    if [ -z "$selection" ] ; then
        echo
        echo "Invalid turnkey combo: $answer"
        return 1
    fi

    site=$(echo -n $selection | sed -e "s/-.*$//" | sed -e "s/_.*$//")
    check_site $site
    if [ $? -ne 0 ] ; then
        echo
        echo "** Don't have a site spec for: '$site'"
        site=
    fi
    
    components=$(echo -n $selection | sed -e "s/-.*$//" | sed -e "s/^[^_]*_//" | sed -e "s/_/ /g")
    check_components ${components[@]}
    if [ $? -ne 0 ] ; then
    	echo
        echo "** Invalid components: '${components[@]}'"
        echo "** Must be one or two of '${COMPONENT_CHOICES[@]}'"
        components=
    fi

    goals=$(echo -n $selection | sed -e "s/^[^\-]*-//" | sed "s/_/ /g")
    check_goals ${goals[@]}
    if [ $? -ne 0 ] ; then
        echo
        echo "** Invalid goals: '${goals[@]}'"
        echo "** Must be one or two of '${GOALS_CHOICES[@]}'"
        goals=
    fi

    if [ -z "$site" -o -z "$components" -o -z "$goals" ] ; then
        echo
        return 1
    fi

    export TARGET_SITE=$site
    export TARGET_SITE_COMPONENTS=${components[@]}
    export TARGET_SITE_GOALS=${goals[@]}
}

# Upgrade CI Jenkins
function ciserver_jenkins_upgrade()
{
	if [ -z "$TARGET_CI" ] ; then
		echo 
		echo "** TARGET_CI not set yet. Check your site specs to fix it."
		return
	fi
}

# Backup CI Jenkins
function ciserver_jenkins_backup()
{
	if [ -z "$TARGET_CI" ] ; then
		echo 
		echo "** TARGET_CI not set yet. Check your site specs to fix it."
		return
	fi
}

# Customize CI Jenkins
function ciserver_jenkins_custom()
{
	if [ -z "$TARGET_CI" ] ; then
		echo 
		echo "** TARGET_CI not set yet. Check your site specs to fix it."
		return
	fi
	
	echo
	echo "Customizing for site[$TARGET_CI_JENKINS_SITE]@IPaddr[$TARGET_CI_IPADDR]..."
}

# Postconfig CI Jenkins
function ciserver_jenkins_postconfig()
{
	if [ -z "$TARGET_CI" ] ; then
		echo 
		echo "** TARGET_CI not set yet. Check your site specs to fix it."
		return
	fi
	
	echo 
	echo "Postconfiguring for site[$TARGET_CI_JENKINS_SITE]@IPaddr[$TARGET_CI_IPADDR]..."
}

# Install CI Jenkins
function ciserver_jenkins_install()
{
	if [ -z "$TARGET_CI" ] ; then
		echo 
		echo "** TARGET_CI not set yet. Check your site specs to fix it."
		return
	fi
	
	echo 
	echo "Installing for site[$TARGET_CI_JENKINS_SITE]@IPaddr[$TARGET_CI_IPADDR]..."
	
	if [ ! -f /home/jenkins/bin/jenkins.war ] ; then
		# Create bin dir under home for user jenkins 
		local bin_path=/home/jenkins/bin
		if [ ! -d "$bin_path" ] ; then
			sudo -H -u jenkins mkdir $bin_path
		fi
		# Set bin path to PATH
		local keys=(`grep -i '$bin_path' /home/jenkins/.bashrc 2>/dev/null`)
		if [ ! "$keys" ] ; then
			sudo -H -u jenkins /bin/bash -c "echo 'PATH=$bin_path:$PATH' >>/home/jenkins/.bashrc"
		fi

		# Pick up the up-to-date version of Jenkins 
		# from http://mirrors.jenkins-ci.org/war
		# or http://mirrors.jenkins-ci.org/war/latest
		local WGET=(`which wget`)
		local url
		local jenkins_war=jenkins.war
		if [ -z "$TARGET_CI_JENKINS_VERSION_INSTALLED" ] ; then
			url=http://mirrors.jenkins-ci.org/war/latest
		else
			url=http://mirrors.jenkins-ci.org/war/$TARGET_CI_JENKINS_VERSION_INSTALLED
		fi
		sudo -H -u jenkins $WGET -O $bin_path/$jenkins_war $url/$jenkins_war
	fi
	
	# Launch Jenkins daemon
	if [ ! -L /etc/init.d/jenkins ] ; then
		if [ ! -f //home/jenkins/bin/jenkins.sh ] ; then
			sudo -H -u jenkins cp build/configs/jenkins/jenkins.sh $bin_path/jenkins.sh
		fi
		sudo ln -snf $bin_path/jenkins.sh /etc/init.d/jenkins
		
		if [ ! -f /etc/default/jenkins ] ; then
			sudo cp build/configs/jenkins/jenkins /etc/default/jenkins
		fi
		sudo update-rc.d jenkins defaults 90 10
	fi
	keys=(`ps -ef | grep -i "^jenkins"`)
	if [ ! "$keys" ] ; then
		sudo /etc/init.d/jenkins start
	fi
}

# Configure CI Jenkins
function ciserver_jenkins_configure()
{
	if [ -z "$TARGET_CI" ] ; then
		echo 
		echo "** TARGET_CI not set yet. Check your site specs to fix it."
		return
	fi
	
	echo 
	echo "Configuring for site[$TARGET_CI_JENKINS_SITE]@IPaddr[$TARGET_CI_IPADDR]..."
	
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
	
	case $TARGET_CI_JENKINS_WEBSERVER in
		apache2)
			case $TARGET_CI_URL in
				https | HTTPS)
					sudo a2enmod ssl proxy proxy_http rewrite
					# Configure virtual host as well as port for Bugzilla 
					# on Apache server
					if [ ! -f /etc/apache2/sites-available/$TARGET_CI_JENKINS_SITE ] ; then
						# Generate a self-signed certificate for SSL
						if [ ! -d /etc/apache2/ssl ] ; then
							sudo mkdir /etc/apache2/ssl
						fi
						if [ ! -f /etc/apache2/ssl/$TARGET_CI_JENKINS_SITE.pem -o ! -f /etc/apache2/ssl/$TARGET_CI_JENKINS_SITE.key ] ; then
							local OPENSSL=(`which openssl`)
							$OPENSSL req -new -x509 -days 365 -nodes -out $TARGET_CI_JENKINS_SITE.pem -keyout $TARGET_CI_JENKINS_SITE.key
							sudo mv $TARGET_CI_JENKINS_SITE.pem /etc/apache2/ssl
							sudo mv $TARGET_CI_JENKINS_SITE.key /etc/apache2/ssl
						fi
						
						local vhconfig
						vhconfig=$TARGET_CI_JENKINS_SITE.$TARGET_CI_URL
						if [ -f $TARGET_SITE_CONFIG/jenkins/$vhconfig ] ; then
							sudo cp $TARGET_SITE_CONFIG/jenkins/$vhconfig /etc/apache2/sites-available/$TARGET_CI_JENKINS_SITE
						else
							echo
							echo "** No virtual host configuration for 'Jenkins' on $TARGET_CI_JENKINS_WEBSERVER"
							return
						fi
		
						# Enable virtualhost at port 443 for ssl
						local keys
						keys=(`grep "^[[:space:]]NameVirtualHost \*:443" /etc/apache2/ports.conf`)
						if [ ! "$keys" ] ; then
						sudo sed -i -e "/^<IfModule mod_ssl.c>.*/a\\\tNameVirtualHost \*:443" /etc/apache2/ports.conf
						fi
					fi
					
					# Match host names with IP address
					keys=(`cat /etc/hosts | grep -i -e "^[0-9\.]*[[:space:]]*$TARGET_CI_JENKINS_SITE"`)
					if [ ! "$keys" ] ; then
					sudo bash -c "cat >>/etc/hosts <<EOF
$TARGET_CI_IPADDR $TARGET_CI_JENKINS_SITE
EOF"
					fi
					
					# Make virtual host configuration to Apache take effect
					sudo a2ensite $TARGET_CI_JENKINS_SITE
					sudo a2dissite default
					sudo /etc/init.d/apache2 restart
					;;
				*)
					echo 
					echo "** HTTP not supported for 'Jenkins' yet."
					return
					;;
			esac
			;;
		*)
			echo
			echo "** Invalid webserver type for 'Jenkins': '$TARGET_CI_JENKINS_WEBSERVER'"
			return
			;;
	esac
}

# Preinstall packages required for Jenkins
function ciserver_jenkins_preinstall()
{
	if [ -z "$TARGET_CI" ] ; then
		echo 
		echo "** TARGET_CI not set yet. Check your site specs to fix it."
		return
	fi
	
	echo 
	echo "Preinstalling for site[$TARGET_CI_JENKINS_SITE]@IPaddr[$TARGET_CI_IPADDR]..."
	
	if [ -n "$TARGET_CI_JENKINS_WEBSERVER" ] ; then
		webserver $TARGET_CI_JENKINS_WEBSERVER
	fi
	if [ "$TARGET_CI_URL" = "https" -o "$TARGET_CI_URL" = "HTTPS" ] ; then
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

# Clean all settings simply around Jenkins
function ciserver_jenkins_clean()
{
	if [ -z "$TARGET_CI" ] ; then
		echo 
		echo "** TARGET_CI not set yet. Check your site specs to fix it."
		return
	fi
	
	echo
	echo "Cleaning for site[$TARGET_CI_JENKINS_SITE]@ipadd[$TARGET_CI_IPADDR]..."
	
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
			
	case $TARGET_CI_JENKINS_WEBSERVER in
		apache2)
			if [ -f /etc/apache2/sites-available/$TARGET_CI_JENKINS_SITE ] ; then
				sudo rm /etc/apache2/sites-available/$TARGET_CI_JENKINS_SITE
			fi
			if [ -L /etc/apache2/sites-enabled/$TARGET_CI_JENKINS_SITE ] ; then
				sudo rm /etc/apache2/sites-enabled/$TARGET_CI_JENKINS_SITE
			fi
			;;
		*)
			echo
			echo "** Invalid webserver type for 'Jenkins': '$TARGET_CI_JENKINS_WEBSERVER'"
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

# Setup CI Jenkins
function ciserver_jenkins()
{
	if [ -z "$TARGET_CI" ] ; then
		echo 
		echo "** TARGET_CI not set yet. Check your site specs to fix it."
		return
	fi
	
	local goal
	for goal in ${TARGET_SITE_GOALS[@]}
	do
		case $goal in
			clean)
				ciserver_jenkins_clean
				;;
			preinstall)
				ciserver_jenkins_preinstall
				;;
			configure)
				ciserver_jenkins_configure
				;;
			install)
				ciserver_jenkins_install
				;;
			postconfig)
				ciserver_jenkins_postconfig
				;;
			custom)
				ciserver_jenkins_custom
				;;
			backup)
				ciserver_jenkins_backup
				;;
			upgrade)
				ciserver_jenkins_upgrade
				;;
			lite)
				ciserver_jenkins_clean
				ciserver_jenkins_preinstall
				ciserver_jenkins_configure
				ciserver_jenkins_install
				;;
			all)
				ciserver_jenkins_clean
				ciserver_jenkins_preinstall
				ciserver_jenkins_configure
				ciserver_jenkins_install
				ciserver_jenkins_postconfig
				ciserver_jenkins_custom
				;;
			*)
				echo
				echo "** Invalid TARGET SITE GOALS: '$goal'"
				return
				;;
		esac
	done
}

# Setup CI server
function ciserver()
{
	# Note that TARGET_CI has support only for one type of product for now, which
	# covers Jenkins.
	local ci
	for ci in ${TARGET_CI[@]}
	do
		if [ $ci = "jenkins" ] ; then
			ciserver_jenkins
		else
			echo 
			echo "** Invalid CI: '$ci'"
			echo "** Must be one of '${CI_CHOICES[@]}'"
			return
		fi
	done
}

# Upgrade SCMR Gitolite
function scmrserver_gitolite_upgrade()
{
	if [ -z "$TARGET_SCMR" ] ; then
		echo 
		echo "** TARGET_SCMR not set yet. Check your site specs to fix it."
		return
	fi
}

# Backup SCMR Gitolite
function scmrserver_gitolite_backup()
{
	if [ -z "$TARGET_SCMR" ] ; then
		echo 
		echo "** TARGET_SCMR not set yet. Check your site specs to fix it."
		return
	fi
}

# Customize SCMR Gitolite
function scmrserver_gitolite_custom()
{
	if [ -z "$TARGET_SCMR" ] ; then
		echo 
		echo "** TARGET_SCMR not set yet. Check your site specs to fix it."
		return
	fi
}

# Postconfig SCMR Gitolite
function scmrserver_gitolite_postconfig()
{
	if [ -z "$TARGET_SCMR" ] ; then
		echo 
		echo "** TARGET_SCMR not set yet. Check your site specs to fix it."
		return
	fi
}

# Install SCMR Gitolite
function scmrserver_gitolite_install() 
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
	echo "Installing site[$site]@IPaddr[$ipaddr]..."
	echo
	
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

# Configure SCMR Gitolite
function scmrserver_gitolite_configure()
{
	if [ -z "$TARGET_SCMR" ] ; then
		echo 
		echo "** TARGET_SCMR not set yet. Check your site specs to fix it."
		return
	fi
}

# Preinstall packages required for Gitolite
function scmrserver_gitolite_preinstall()
{
	if [ -z "$TARGET_SCMR" ] ; then
		echo 
		echo "** TARGET_SCMR not set yet. Check your site specs to fix it."
		return
	fi
}

# Clean all settings simply around Gitolite
function scmrserver_gitolite_clean()
{
	if [ -z "$TARGET_SCMR" ] ; then
		echo 
		echo "** TARGET_SCMR not set yet. Check your site specs to fix it."
		return
	fi
}

# Setup SCMR Gitolite
function scmrserver_gitolite()
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
				scmrserver_gitolite_clean
				;;
			preinstall)
				scmrserver_gitolite_preinstall
				;;
			configure)
				scmrserver_gitolite_configure
				;;
			install)
				scmrserver_gitolite_install
				;;
			postconfig)
				scmrserver_gitolite_postconfig
				;;
			custom)
				scmrserver_gitolite_custom
				;;
			backup)
				scmrserver_gitolite_backup
				;;
			upgrade)
				scmrserver_gitolite_upgrade
				;;
			lite)
				scmrserver_gitolite_clean
				scmrserver_gitolite_preinstall
				scmrserver_gitolite_configure
				scmrserver_gitolite_install
				;;
			all)
				scmrserver_gitolite_clean
				scmrserver_gitolite_preinstall
				scmrserver_gitolite_configure
				scmrserver_gitolite_install
				scmrserver_gitolite_postconfig
				scmrserver_gitolite_custom
				;;
			*)
				echo
				echo "** Invalid TARGET SITE GOALS: '$goal'"
				return
				;;
		esac
	done
}

# Upgrade SCMR Gerrit
function scmrserver_gerrit_upgrade()
{
	if [ -z "$TARGET_SCMR" ] ; then
		echo 
		echo "** TARGET_SCMR not set yet. Check your site specs to fix it."
		return
	fi
}

# Backup SCMR Gerrit
function scmrserver_gerrit_backup()
{
	if [ -z "$TARGET_SCMR" ] ; then
		echo 
		echo "** TARGET_SCMR not set yet. Check your site specs to fix it."
		return
	fi
	
	# Refer to http://www.ovirt.org/Gerrit_server_backup
}

# Customize SCMR Gerrit
function scmrserver_gerrit_custom()
{
	if [ -z "$TARGET_SCMR" ] ; then
		echo 
		echo "** TARGET_SCMR not set yet. Check your site specs to fix it."
		return
	fi
	
	echo 
	echo "Customizing for site[$TARGET_SCMR_GERRIT_SITE]@IPaddr[$TARGET_SCMR_IPADDR]..."
	
	if [ -d "$TARGET_SITE_THEMES/gerrit/$TARGET_SCMR_GERRIT_THEME" ] ; then
		sudo -H -u gerrit cp $TARGET_SITE_THEMES/gerrit/$TARGET_SCMR_GERRIT_THEME/GerritSite* /home/gerrit/etc/
		
		sudo -H -u gerrit cp $TARGET_SITE_THEMES/gerrit/$TARGET_SCMR_GERRIT_THEME/static/* /home/gerrit/static/
	fi
}

# Postconfig SCMR Gerrit
function scmrserver_gerrit_postconfig()
{
	if [ -z "$TARGET_SCMR" ] ; then
		echo 
		echo "** TARGET_SCMR not set yet. Check your site specs to fix it."
		return
	fi
	
	echo 
	echo "Postconfiguring for site[$TARGET_SCMR_GERRIT_SITE]@IPaddr[$TARGET_SCMR_IPADDR]..."
	
	echo 
	echo "Configuring SSH for Gerrit Access..."
	if [ -n "$TARGET_SCMR_GERRIT_SSH_CONFIG" ] ; then
		if [ ! -f ~/.ssh/config ] ; then
			ssh-keygen -t rsa -C "$TARGET_SCMR_GERRIT_SSHGIT_USER $TARGET_SCMR_GERRIT_SSHGIT_EMAIL"
			cp $TARGET_SITE_CONFIG/gerrit/$TARGET_SCMR_GERRIT_SSH_CONFIG ~/.ssh/config
		fi
	fi
	
	echo 
	echo "Configuring Git for Gerrit Access..."
	local gconf=~/.gitconfig
	if [ ! -f "$gconf" ] ; then
		local user email editor
		
		touch ~/.$gconf
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
		if [ -z "$TARGET_SCMR_GERRIT_GIT_EDITOR" ] ; then
			while [ -z $editor ] ; do
				echo -n "Your core editor for Git is: " ; read editor
			done
			TARGET_SCMR_GERRIT_GIT_EDITOR=$editor
		else
			editor=$TARGET_SCMR_GERRIT_GIT_EDITOR
		fi
		git config --global user.name "$user"
		git config --global user.email "$email"
		git config --global core.editor "$editor"
		git config --global color.ui true
	fi
}

# Install SCMR Gerrit
function scmrserver_gerrit_install()
{
	if [ -z "$TARGET_SCMR" ] ; then
		echo 
		echo "** TARGET_SCMR not set yet. Check your site specs to fix it."
		return
	fi
	
	echo 
	echo "Installing for site[$TARGET_SCMR_GERRIT_SITE]@IPaddr[$TARGET_SCMR_IPADDR]..."
	
	if [ ! -f /home/gerrit/bin/gerrit.sh ] ; then
		# Set paths
		local bin_path=/home/gerrit/bin
		local keys=(`grep -i '$bin_path' /home/gerrit/.bashrc 2>/dev/null`)
		if [ ! "$keys" ] ; then
			sudo -H -u gerrit bash -c "echo 'PATH=$bin_path:$PATH' >>/home/gerrit/.bashrc"
		fi
		
		# Obtain libraries and predefined configuration files 
		# for Gerrit
		if [ ! -d /home/gerrit/etc ] ; then
			sudo -H -u gerrit mkdir /home/gerrit/etc
		fi
		if [ ! -d /home/gerrit/lib ] ; then
			sudo -H -u gerrit mkdir /home/gerrit/lib
		fi
		
		local lib=bcprov-jdk16-144.jar
		if [ ! -f /home/gerrit/lib/$lib ] ; then
			local WGET=(`which wget`)
			local OPENSSL=(`which openssl`)
			local url=http://www.bouncycastle.org/download
			local default_sha1=6327a5f7a3dc45e0fd735adb5d08c5a74c05c20c
			local local_sha1
			sudo -H -u gerrit $WGET -P /home/gerrit/lib $url/$lib
			local_sha1=(`$OPENSSL dgst -sha1 /home/gerrit/lib/$lib | sed "s/^.* //"`)
			if [ "$default_sha1" != "$local_sha1" ] ; then
				echo
				echo "** Unmatched checksum for '$lib'"	
				return
			fi
		fi
		
		local config=$TARGET_SITE_CONFIG/gerrit/gerrit.config.$TARGET_SCMR_URL.$TARGET_SCMR_GERRIT_AUTH
		if [ ! -f "/home/gerrit/etc/gerrit.config" ] ; then
			sudo -H -u gerrit cp $config /home/gerrit/etc/gerrit.config
		fi
		config=$TARGET_SITE_CONFIG/gerrit/secure.config
		if [ ! -f "/home/gerrit/etc/secure.config" ] ; then
			sudo -H -u gerrit cp $config /home/gerrit/etc/secure.config
		fi
		
		# Pick up the up-to-date version of Gerrit 
		# from http://code.google.com/p/gerrit/downloads/list
		local stable=gerrit.war
		local installed=gerrit-$TARGET_SCMR_GERRIT_VERSION_INSTALLED.war
		local url=http://gerrit.googlecode.com/files
		sudo -H -u gerrit $WGET -O /home/gerrit/$stable $url/$installed
		if [ -f "/home/gerrit/etc/gerrit.config" ] ; then
			sudo -H -u gerrit java -jar /home/gerrit/$stable init --batch --no-auto-start -d /home/gerrit
		else
			sudo -H -u gerrit java -jar /home/gerrit/$stable init --no-auto-start -d /home/gerrit
		fi
		sudo -H -u gerrit rm /home/gerrit/$stable
	
		# Do some modifications in /home/gerrit/etc/gerrit.config
		local item=canonicalWebUrl
		url=https://$TARGET_SCMR_GERRIT_SITE
		keys=(`grep "$item" /home/gerrit/etc/gerrit.config 2>/dev/null`)
		if [ ! "$keys" ] ; then
			sudo -H -u gerrit sed -i -e "/^[[:space:]]basePath.*/a\\\t$item = $url" /home/gerrit/etc/gerrit.config
		fi
		
		if [ "$TARGET_SCMR_GERRIT_AUTH" = "openidsso" -o "$TARGET_SCMR_GERRIT_AUTH" = "OPENIDSSO" ] ; then
			if [ -n "$TARGET_SCMR_GERRIT_OPENIDSSO_URL" ] ; then
				item=openIdSsoUrl
				keys=(`grep "$item" /home/gerrit/etc/gerrit.config 2>/dev/null`)
				if [ ! "$keys" ] ; then
					echo "openIdSsoUrl does not exit"
					sudo -H -u gerrit sed -i -e "/^[[:space:]]type = OPENID_SSO.*/a\\\t$item = $TARGET_SCMR_GERRIT_OPENIDSSO_URL" /home/gerrit/etc/gerrit.config
				else
					url=(`echo $TARGET_SCMR_GERRIT_OPENIDSSO_URL | sed -e 's/\//\\\\\//g'`)
					sudo -H -u gerrit sed -i -e "s/^[[:space:]]$item.*/\t$item = $url/" /home/gerrit/etc/gerrit.config
				fi
			fi
		fi
	fi
	
	# Launch Gerrit daemon
	if [ ! -L /etc/init.d/gerrit ] ; then
		sudo ln -snf /home/gerrit/bin/gerrit.sh /etc/init.d/gerrit
		
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

# Configure SCMR Gerrit
function scmrserver_gerrit_configure()
{
	if [ -z "$TARGET_SCMR" ] ; then
		echo 
		echo "** TARGET_SCMR not set yet. Check your site specs to fix it."
		return
	fi
	
	echo 
	echo "Configuring site[$TARGET_SCMR_GERRIT_SITE]@IPaddr[$TARGET_SCMR_IPADDR]..."
	
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
		mysql | MYSQL)
			# Create a new database via mysql for Gerrit use which is named 
			# by means of this variable, TARGET_SCMR_GERRIT_SITE. Let's say,
			# this name of the database would be review_mci_org if this 
			# value of the variable is review.mci.org.
			local MYSQL MYSQL_HEADER MYSQL_ROOTPW 
			local dbhost dbname dbuser dbpw
			
			if [ -z $TARGET_SCMR_GERRIT_MYSQL_DBNAME ] ; then
				dbname=(`echo -n $TARGET_SCMR_GERRIT_SITE | sed -e "s/\./_/g"`)
				TARGET_SCMR_GERRIT_MYSQL_DBNAME=$dbname
			else
				dbname=$TARGET_SCMR_GERRIT_MYSQL_DBNAME
			fi
			
			echo 
			echo "Creating database[$dbname] in '$TARGET_SCMR_GERRIT_DBENGINE' for Gerrit..."
			
			MYSQL=(`which mysql`)
			if [ -z "$TARGET_DBENGINE_MYSQL_ROOTPW" ] ; then
				read -s -p "Enter password for MySQL: " MYSQL_ROOTPW
				TARGET_DBENGINE_MYSQL_ROOTPW=$MYSQL_ROOTPW
			else
				MYSQL_ROOTPW=$TARGET_DBENGINE_MYSQL_ROOTPW
			fi
			MYSQL_HEADER="$MYSQL --user=root --password=$MYSQL_ROOTPW --batch --skip-column-names -e"
			if [ ! `$MYSQL_HEADER "SHOW DATABASES LIKE '$dbname';"` ] ; then
				if [ -z "$TARGET_SCMR_GERRIT_MYSQL_DBPW" ] ; then
					read -s -p "Enter password for $TARGET_SCMR database: " dbpw
				else
					dbpw=$TARGET_SCMR_GERRIT_MYSQL_DBPW
				fi
				if [ -z "$TARGET_SCMR_GERRIT_MYSQL_DBUSER" ] ; then
					dbuser=gerrit
					TARGET_SCMR_GERRIT_MYSQL_DBUSER=$dbuser
				else
					dbuser=$TARGET_SCMR_GERRIT_MYSQL_DBUSER
				fi
				if [ -z "$TARGET_DBENGINE_MYSQL_HOST" ] ; then
					dbhost=localhost
					TARGET_DBENGINE_MYSQL_HOST=$dbhost
				else
					dbhost=$TARGET_DBENGINE_MYSQL_HOST
				fi
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
			echo "** Invalid dbengine type for Gerrit: '$TARGET_SCMR_GERRIT_DBENGINE'"
			return
			;;
	esac
	
	case $TARGET_SCMR_GERRIT_WEBSERVER in
		apache2)
			case $TARGET_SCMR_URL in
				https | HTTPS)
					sudo a2enmod ssl proxy proxy_http rewrite
					# Configure virtual host as well as port for Gerrit 
					# on Apache server
					if [ ! -f /etc/apache2/sites-available/$TARGET_SCMR_GERRIT_SITE ] ; then
						# Generate a self-signed certificate for SSL
						if [ ! -d /etc/apache2/ssl ] ; then
							sudo mkdir /etc/apache2/ssl
						fi
						if [ ! -f /etc/apache2/ssl/$TARGET_SCMR_GERRIT_SITE.pem -o ! -f /etc/apache2/ssl/$TARGET_SCMR_GERRIT_SITE.key ] ; then
							local OPENSSL=(`which openssl`)
							$OPENSSL req -new -x509 -days 365 -nodes -out $TARGET_SCMR_GERRIT_SITE.pem -keyout $TARGET_SCMR_GERRIT_SITE.key
							sudo mv $TARGET_SCMR_GERRIT_SITE.pem /etc/apache2/ssl
							sudo mv $TARGET_SCMR_GERRIT_SITE.key /etc/apache2/ssl
						fi
						
						local vhconfig
						if [ $TARGET_SCMR_GERRIT_AUTH = "httpbasic" ] ; then
							# For the sake of http authentication, instead of
							# OpenID, have to set up auth passwords for admin
							# and users of Gerrit
							local admin=$TARGET_SCMR_GERRIT_HTTPBASIC_ADMIN
							if [ -z "$admin" ] ; then
								echo
								echo "** No Admin for Gerrit"
								return
							fi
							sudo -H -u gerrit touch /home/gerrit/etc/passwords
							sudo -H -u gerrit /bin/bash -c "/usr/bin/htpasswd /home/gerrit/etc/passwords $admin"
							vhconfig=$TARGET_SCMR_GERRIT_SITE.$TARGET_SCMR_URL.$TARGET_SCMR_GERRIT_AUTH
						else
							vhconfig=$TARGET_SCMR_GERRIT_SITE.$TARGET_SCMR_URL
						fi
								
						if [ -f $TARGET_SITE_CONFIG/gerrit/$vhconfig ] ; then
							sudo cp $TARGET_SITE_CONFIG/gerrit/$vhconfig /etc/apache2/sites-available/$TARGET_SCMR_GERRIT_SITE
						else
							echo
							echo "** No virtual host configuration for 'Gerrit' on $TARGET_SCMR_GERRIT_WEBSERVER"
							return
						fi 
		
						# Enable virtualhost at port 443 for ssl
						local keys
						keys=(`grep "^[[:space:]]NameVirtualHost \*:443" /etc/apache2/ports.conf 2>/dev/null`)
						if [ ! "$keys" ] ; then
							sudo sed -i -e "/^<IfModule mod_ssl.c>.*/a\\\tNameVirtualHost \*:443" /etc/apache2/ports.conf
						fi
					fi
					
					# Match host names with IP address
					keys=(`cat /etc/hosts | grep -i -e "^[0-9\.]*[[:space:]]*$TARGET_SCMR_GERRIT_SITE"`)
					if [ ! "$keys" ] ; then
					sudo bash -c "cat >>/etc/hosts <<EOF
$TARGET_SCMR_IPADDR $TARGET_SCMR_GERRIT_SITE
EOF"
					fi
					
					# Make virtual host configuration to Apache take effect
					sudo a2ensite $TARGET_SCMR_GERRIT_SITE
					sudo a2dissite default
					sudo /etc/init.d/apache2 restart
					;;
				*)
					echo 
					echo "** HTTP not supported for 'Gerrit' yet."
					return
					;;
			esac
			;;
		*)
			echo
			echo "** Invalid webserver type for Gerrit: '$TARGET_SCMR_GERRIT_WEBSERVER'"
			return
			;;
	esac
}

# Preinstall packages required for Gerrit
function scmrserver_gerrit_preinstall()
{
	if [ -z "$TARGET_SCMR" ] ; then
		echo 
		echo "** TARGET_SCMR not set yet. Check your site specs to fix it."
		return
	fi
	
	echo 
	echo "Preinstalling for site[$TARGET_SCMR_GERRIT_SITE]@IPaddr[$TARGET_SCMR_IPADDR]..."
	
	if [ -n "$TARGET_SCMR_GERRIT_WEBSERVER" ] ; then
		webserver $TARGET_SCMR_GERRIT_WEBSERVER
	fi
	if [ -n "$TARGET_SCMR_GERRIT_DBENGINE" ] ; then
		dbengine $TARGET_SCMR_GERRIT_DBENGINE
	fi
	if [ "$TARGET_SCMR_URL" = "https" -o "$TARGET_SCMR_URL" = "HTTPS" ] ; then
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
		sudo apt-get -y install git-core git-doc
	fi
	case $TARGET_SCMR_GERRIT_WEBFRONT in
		gitweb | GITWEB)
			if [ ! -f /etc/gitweb.conf ] ; then
				sudo apt-get install gitweb highlight
			fi
			;;
		cgit | CGIT)
			echo
			echo "Stay tuned for cGit"
			;;
		*)
			echo
			echo "** Invalid Webfront for Gerrit: '$TARGET_SCMR_GERRIT_WEBFRONT'"
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

# Clean all settings simply around Gerrit
function scmrserver_gerrit_clean()
{
	if [ -z "$TARGET_SCMR" ] ; then
		echo 
		echo "** TARGET_SCMR not set yet. Check your site specs to fix it."
		return
	fi
	
	echo
	echo "Cleaning for site[$TARGET_SCMR_GERRIT_SITE]@ipadd[$TARGET_SCMR_IPADDR]..."
	
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
		mysql | MYSQL)
			local MYSQL MYSQL_HEADER_COMPLEX MYSQL_HEADER_SIMPLE MYSQL_ROOTPW 
			local dbhost dbname dbuser
			MYSQL=(`which mysql`)
			if [ -z $TARGET_SCMR_GERRIT_MYSQL_DBNAME ] ; then
				dbname=(`echo -n $TARGET_SCMR_GERRIT_SITE | sed -e "s/\./_/g"`)
				TARGET_SCMR_GERRIT_MYSQL_DBNAME=$dbname
			else
				dbname=$TARGET_SCMR_GERRIT_MYSQL_DBNAME
			fi
			if [ -z "$TARGET_DBENGINE_MYSQL_ROOTPW" ] ; then
				read -s -p "Enter password for MySQL: " MYSQL_ROOTPW
				TARGET_DBENGINE_MYSQL_ROOTPW=$MYSQL_ROOTPW
			else
				MYSQL_ROOTPW=$TARGET_DBENGINE_MYSQL_ROOTPW
			fi
			if [ -z "$TARGET_SCMR_GERRIT_MYSQL_DBUSER" ] ; then
				dbuser=gerrit
				TARGET_SCMR_GERRIT_MYSQL_DBUSER=$dbuser
			else
				dbuser=$TARGET_SCMR_GERRIT_MYSQL_DBUSER
			fi
			if [ -z "$TARGET_DBENGINE_MYSQL_HOST" ] ; then
				dbhost=localhost
				TARGET_DBENGINE_MYSQL_HOST=$dbhost
			else
				dbhost=$TARGET_DBENGINE_MYSQL_HOST
			fi
			
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
			echo "** Invalid dbengine type for Gerrit: '$TARGET_SCMR_GERRIT_DBENGINE'"
			return
			;;
	esac
			
	case $TARGET_SCMR_GERRIT_WEBSERVER in
		apache2)
			if [ -f /etc/apache2/sites-available/$TARGET_SCMR_GERRIT_SITE ] ; then
				sudo rm /etc/apache2/sites-available/$TARGET_SCMR_GERRIT_SITE
			fi
			if [ -L /etc/apache2/sites-enabled/$TARGET_SCMR_GERRIT_SITE ] ; then
				sudo rm /etc/apache2/sites-enabled/$TARGET_SCMR_GERRIT_SITE
			fi
			;;
		*)
			echo
			echo "** Invalid webserver type for Gerrit: '$TARGET_SCMR_GERRIT_WEBSERVER'"
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

# Setup SCMR Gerrit
function scmrserver_gerrit()
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
				scmrserver_gerrit_clean
				;;
			preinstall)
				scmrserver_gerrit_preinstall
				;;
			configure)
				scmrserver_gerrit_configure
				;;
			install)
				scmrserver_gerrit_install
				;;
			postconfig)
				scmrserver_gerrit_postconfig
				;;
			custom)
				scmrserver_gerrit_custom
				;;
			backup)
				scmrserver_gerrit_backup
				;;
			upgrade)
				scmrserver_gerrit_upgrade
				;;
			lite)
				scmrserver_gerrit_clean
				scmrserver_gerrit_preinstall
				scmrserver_gerrit_configure
				scmrserver_gerrit_install
				;;
			all)
				scmrserver_gerrit_clean
				scmrserver_gerrit_preinstall
				scmrserver_gerrit_configure
				scmrserver_gerrit_install
				scmrserver_gerrit_postconfig
				scmrserver_gerrit_custom
				;;
			*)
				echo
				echo "** Invalid TARGET SITE GOALS: '$goal'"
				return
				;;
		esac
	done
}

# Setup SCMR Server
function scmrserver()
{
	# Note that TARGET_SCMR has support only for two kinds of SCMR for now, 
	# which includes Gerrit, and Gitolite
	local scmr
	for scmr in ${TARGET_SCMR[@]}
	do
		if [ $scmr = "gerrit" ] ; then
			scmrserver_gerrit
		elif [ $scmr = "gitolite" ] ; then
			scmrserver_gitolite
		else
			echo 
			echo "** Invalid SCMR: '$scmr'"
			echo "** Must be one of '${SCMR_CHOICES[@]}'"
			return
		fi
	done
}

# Upgrade ITS Bugzilla
function itsserver_bugzilla_upgrade()
{
	if [ -z "$TARGET_ITS" ] ; then
		echo 
		echo "** TARGET_ITS not set yet. Check your site specs to fix it."
		return
	fi
}

# Backup ITS Bugzilla
function itsserver_bugzilla_backup()
{
	if [ -z "$TARGET_ITS" ] ; then
		echo 
		echo "** TARGET_ITS not set yet. Check your site specs to fix it."
		return
	fi
}

# Customize ITS Bugzilla
function itsserver_bugzilla_custom()
{
	if [ -z "$TARGET_ITS" ] ; then
		echo 
		echo "** TARGET_ITS not set yet. Check your site specs to fix it."
		return
	fi
}

# Postconfig ITS Bugzilla
function itsserver_bugzilla_postconfig()
{
	if [ -z "$TARGET_ITS" ] ; then
		echo 
		echo "** TARGET_ITS not set yet. Check your site specs to fix it."
		return
	fi
	
	# Enable SMTP server for Bugzilla sending emails
}

# Install ITS Bugzilla
function itsserver_bugzilla_install()
{
	if [ -z "$TARGET_ITS" ] ; then
		echo 
		echo "** TARGET_ITS not set yet. Check your site specs to fix it."
		return
	fi
	
	echo 
	echo "Installing for site[$TARGET_ITS_BUGZILLA_SITE]@IPaddr[$TARGET_ITS_IPADDR]..."
	
	if [ ! -d /home/www-data/$TARGET_ITS_BUGZILLA_SITE ] ; then
		sudo -H -u www-data mkdir /home/www-data/$TARGET_ITS_BUGZILLA_SITE
	fi
	# Pick up the latest stable version of bugzilla 
	# from http://www.bugzilla.org/download/#stable,
	# or from http://ftp.mozilla.org/pub/mozilla.org/webtools/
	local itstop=/home/www-data/$TARGET_ITS_BUGZILLA_SITE
	if [ ! -f $itstop/localconfig ] ; then
		local url=http://ftp.mozilla.org/pub/mozilla.org/webtools/
		local version=$TARGET_ITS_BUGZILLA_VERSION_INSTALLED
		local stable=bugzilla-$version.tar.gz
		sudo -H -u www-data wget -P $itstop $url/$stable
		sudo -H -u www-data tar xzvf $itstop/$stable -C $itstop
		sudo -H -u www-data mv $itstop/bugzilla-$version/* $itstop/
		sudo -H -u www-data mv $itstop/bugzilla-$version/.htaccess $itstop/
		sudo -H -u www-data rm -rf $itstop/bugzilla-$version
		sudo -H -u www-data rm $itstop/$stable
	
		##################################################################
		#																 #
		#         Ubuntu Packages for Perl Modules on Bugzilla	         #
		#																 #
		# According to different functions on perl modules for bugzilla, #
		# these counterpart packages on Ubuntu are divided into three    #
		# parts as below. Note also that these packages and modules      #
		# listed are based upon Ubuntu 10.04 and Bugzilla 4.2.4,         #
		# respectively.                                                  #
		#						                                         #
		# Primary Perl Packages includes libcgi-pm-perl(CGI.Pm|v3.51),   #
		# libdigest-sha1-perl(Digest-SHA|any), libtimedate-perl(TimeDate #
		# |v2.21), libdatetime-perl(DateTime|v0.28),                     #
		# libdatetime-timezone-perl(DateTime-TimeZone|v0.71), libdbi-perl#
		# (DBI|v.1.41), libtemplate-perl(Template-Toolkit|v2.22),        #
		# libemail-send-perl(Email-Send|v2.00), libemail-mime-perl       #
		# (Email-MIME|v1.904), liburi-perl(URI|v1.37),                   #
		# liblist-moreutils-perl(List-MoreUtils|v0.22)                   #
		# libmath-random-isaac-perl(Math-Random-ISAAC|v1.0.1).           #
		#                                                                #
		# DBD(Database interface Drivers) Perl Packages available        #
		# contains libdb-pg-perl(DBD-Pg|v1.45), libdbd-mysql-perl        #
		# (DBD-mysql|v4.001), libdbd-sqlite3-perl(DBD-SQLite|v1.29).     #
		#                                                                #
		# Optional Perl Packages covers                                  #
		# libchart-perl(GD|v1.20)(Chart|v2.1),                           #
		# libtemplate-plugin-gd-perl(Template-GD)(GDTextUtil)(GDGraph)   #
		# libmime-tools-perl(MIME-tools|v5.406), libwww-perl(libwww-perl)# 
		# libxml-twig-perl(XML-Twig), [](PatchReader|v0.9.6),            #
		# libauthen-simple-ldap-perl(perl-ldap),                         #
		# libauthen-sasl-cyrus-perl(Authen-SASL),                        #
		# libauthen-simple-radius-perl(RadiusPerl), libsoap-lite-perl    #
		# (SOAP-Lite|v0.712), libjson-rpc-perl(JSON-RPC),libjson-xs-perl #
		# (JSON-XS|v2.0), libtest-taint-perl(Test-Taint),  				 #
		# libhtml-parser-perl(HTML-Parser|v3.40), libhtml-scrubber-perl  #
		# (HTML-Scrubber), libencode-detect-perl(Encode|v.2.21)          #
		# (Encode-Detect), [](Email-MIME-Attachment-Stripper),           #
		# [](Email-Reply), libtheschwartz-perl(TheSchwartz),             #
		# libdaemon-generic-perl(Daemon-Generic), libapache-db-perl      #
		# (mod_perl|v1.999022), [](Apache-SizeLimit|v0.96).              #
		#                                                                #
		# As a side of note, this symbol, [], indicates that there is NOT#
		# a corresponding package on Ubuntu against perl modules for     #
		# Bugzilla.                                                      #
		##################################################################
		
		cd $itstop
		PERL=(`which perl`)
		PERL_HEADER="sudo -H -u www-data $PERL"
		$PERL_HEADER $itstop/checksetup.pl --check-modules
		# Install a set of perl packages necessary for bugzilla use
		sudo apt-get -y install libcgi-pm-perl libdigest-sha1-perl libtimedate-perl libdatetime-perl libdatetime-timezone-perl libdbi-perl libemail-send-perl liburi-perl liblist-moreutils-perl libmath-random-isaac-perl libmath-random-isaac-xs-perl
		 
		# Install DBD perl packages available for bugzilla accessing database
		sudo apt-get -y install libdbd-pg-perl libdbd-mysql-perl libdbd-sqlite3-perl
	
		# Install a set of perl packages optional for bugzilla enhancement of performance
		sudo apt-get -y install libchart-perl libtemplate-plugin-gd-perl libmime-tools-perl libwww-perl libxml-twig-perl libauthen-simple-ldap-perl libauthen-sasl-cyrus-perl libauthen-simple-radius-perl libjson-rpc-perl libjson-xs-perl libtest-taint-perl libhtml-scrubber-perl libhtml-parser-perl libencode-detect-perl libtheschwartz-perl libdaemon-generic-perl libapache-db-perl
	
		local LSBR=(`which lsb_release`)
		local current_version=(`$LSBR -sr`)
		local default_version=10.04
		if (( $(echo "$current_version > $default_version" | bc -l) )) ; then
			# Primary perl packages for bugzilla
			sudo apt-get -y install libtemplate-perl libemail-mime-perl
		
			# Optional perl packages for bugzilla
			sudo apt-get -y install libsoap-lite-perl
		else
			# Primary perl packages for bugzilla
			$PERL_HEADER $itstop/install-module.pl Template
			$PERL_HEADER $itstop/install-module.pl Email::MIME
		
			# Optional perl packages for bugzilla
			$PERL_HEADER $itstop/install-module.pl SOAP::Lite
		fi
		# Optional perl packages for bugzilla
		$PERL_HEADER $itstop/install-module.pl PatchReader
		$PERL_HEADER $itstop/install-module.pl Email::MIME::Attachment::Stripper
		$PERL_HEADER $itstop/install-module.pl Email::Reply
		$PERL_HEADER $itstop/install-module.pl Daemon::Generic
		$PERL_HEADER $itstop/install-module.pl Apache2::SizeLimit
		
		# Enable OpenID for bugzilla
		if [ "$TARGET_ITS_BUGZILLA_AUTH" = "openid" ] ; then
			sudo apt-get -y install libgmp3-dev libcrypt-dh-perl 
			$PERL_HEADER $bztop/install-module.pl Net::OpenID::Consumer
			$PERL_HEADER $bztop/install-module.pl Crypt::DH::GMP
			$PERL_HEADER $bztop/install-module.pl Cache::File
			$PERL_HEADER $bztop/install-module.pl LWPx::ParanoidAgent
		fi
	
		# Generate localconfig file in the $itstop
		$PERL_HEADER $itstop/checksetup.pl
	fi
	
	# Modify localconfig file located in the $topdir to fit your needs
	local SED_HEADER="sudo -H -u www-data sed -i -e"
	$SED_HEADER "s/\(^\$webservergroup = \).*/\1\'www-data\'\;/" $itstop/localconfig
	$SED_HEADER "s/\(^\$db_driver = \).*/\1\'$TARGET_ITS_BUGZILLA_DBENGINE\'\;/" $itstop/localconfig
	$SED_HEADER "s/\(^\$db_host = \).*/\1\'$TARGET_DBENGINE_MYSQL_HOST\'\;/" $itstop/localconfig
	$SED_HEADER "s/\(^\$db_name = \).*/\1\'$TARGET_ITS_BUGZILLA_MYSQL_DBNAME\'\;/" $itstop/localconfig
	$SED_HEADER "s/\(^\$db_user = \).*/\1\'$TARGET_ITS_BUGZILLA_MYSQL_DBUSER\'\;/" $itstop/localconfig
	$SED_HEADER "s/\(^\$db_pass = \).*/\1\'$TARGET_ITS_BUGZILLA_MYSQL_DBPW\'\;/" $itstop/localconfig
	
	# Create a bunch of tables in database specified and
	# prompt you for admin email/name/password
	$PERL_HEADER $itstop/checksetup.pl
	
	# After installing Bugzilla, we would prefer to go back to
	# the top of the whole project in order to make the subsequent parts of 
	# installation straightforward.
	mcitop
}

# Configure ITS Bugzilla
function itsserver_bugzilla_configure()
{
	if [ -z "$TARGET_ITS" ] ; then
		echo 
		echo "** TARGET_ITS not set yet. Check your site specs to fix it."
		return
	fi
	
	case $TARGET_ITS_BUGZILLA_DBENGINE in
		mysql | MYSQL)
			# Create a new database via mysql for Bugzilla use which is named 
			# after by means of this variable,TARGET_ITS_BUGZILLA_SITE. Let's say,
			# this name of the database would be bugs_xbmlabs_org if this value of
			# the variable is bugs.xbmlabs.org.
			local MYSQL MYSQL_HEADER MYSQL_ROOTPW 
			local dbhost dbname dbuser dbpw
			
			MYSQL=(`which mysql`)
			if [ -z $TARGET_ITS_BUGZILLA_MYSQL_DBNAME ] ; then
				dbname=(`echo -n $TARGET_ITS_BUGZILLA_SITE | sed -e "s/\./_/g"`)
				TARGET_ITS_BUGZILLA_MYSQL_DBNAME=$dbname
			else
				dbname=$TARGET_ITS_BUGZILLA_MYSQL_DBNAME
			fi
			
			echo 
			echo "Creating database[$dbname] in '$TARGET_ITS_BUGZILLA_DBENGINE' for Bugzilla..."
			
			if [ -z "$TARGET_DBENGINE_MYSQL_ROOTPW" ] ; then
				read -s -p "Enter password for MySQL: " MYSQL_ROOTPW
				TARGET_DBENGINE_MYSQL_ROOTPW=$MYSQL_ROOTPW
			else
				MYSQL_ROOTPW=$TARGET_DBENGINE_MYSQL_ROOTPW
			fi
			MYSQL_HEADER="$MYSQL --user=root --password=$MYSQL_ROOTPW --batch --skip-column-names -e"
			if [ ! `$MYSQL_HEADER "SHOW DATABASES LIKE '$dbname';"` ] ; then
				if [ -z "$TARGET_ITS_BUGZILLA_MYSQL_DBPW" ] ; then
					read -s -p "Enter password for $TARGET_ITS database: " dbpw
				else
					dbpw=$TARGET_ITS_BUGZILLA_MYSQL_DBPW
				fi
				if [ -z "$TARGET_ITS_BUGZILLA_MYSQL_DBUSER" ] ; then
					dbuser=bugzilla
					TARGET_ITS_BUGZILLA_MYSQL_DBUSER=$dbuser
				else
					dbuser=$TARGET_ITS_BUGZILLA_MYSQL_DBUSER
				fi
				if [ -z "$TARGET_DBENGINE_MYSQL_HOST" ] ; then
					dbhost=localhost
					TARGET_DBENGINE_MYSQL_HOST=$dbhost
				else
					dbhost=$TARGET_DBENGINE_MYSQL_HOST
				fi
				
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
			echo "** Invalid dbengine type for Bugzilla: '$TARGET_ITS_BUGZILLA_DBENGINE'"
			return
			;;
	esac
	
	case $TARGET_ITS_BUGZILLA_WEBSERVER in
		apache2)
			case $TARGET_ITS_URL in
				https | HTTPS)
					sudo a2enmod ssl rewrite
					# Configure virtual host as well as port for Bugzilla 
					# on Apache server
					if [ ! -f /etc/apache2/sites-available/$TARGET_ITS_BUGZILLA_SITE ] ; then
						# Generate a self-signed certificate for SSL
						if [ ! -d /etc/apache2/ssl ] ; then
							sudo mkdir /etc/apache2/ssl
						fi
						if [ ! -f /etc/apache2/ssl/$TARGET_SITE.pem -o ! -f /etc/apache2/ssl/$TARGET_SITE.key ] ; then
							local OPENSSL=(`which openssl`)
							$OPENSSL req -new -x509 -days 365 -nodes -out $TARGET_SITE.pem -keyout $TARGET_SITE.key
							sudo mv $TARGET_SITE.pem /etc/apache2/ssl
							sudo mv $TARGET_SITE.key /etc/apache2/ssl
						fi
		
						local vhconfig=$TARGET_SITE.$TARGET_ITS_URL.$TARGET_ITS_BUGZILLA_AUTH
						sudo cp site/*/$TARGET_SITE/$vhconfig /etc/apache2/sites-available/$TARGET_ITS_BUGZILLA_SITE
		
						# Enable virtualhost at port 443 for ssl
						local keys
						keys=(`grep "^[[:space:]]NameVirtualHost \*:443" /etc/apache2/ports.conf`)
						if [ ! "$keys" ] ; then
						sudo sed -i -e "/^<IfModule mod_ssl.c>.*/a\\\tNameVirtualHost \*:443" /etc/apache2/ports.conf
						fi
					fi
					
					# Match host names with IP address
					keys=(`cat /etc/hosts | grep -i -e "^[0-9\.]*[[:space:]]*$TARGET_ITS_BUGZILLA_SITE"`)
					if [ ! "$keys" ] ; then
					sudo bash -c "cat >>/etc/hosts <<EOF
$TARGET_ITS_IPADDR $TARGET_ITS_BUGZILLA_SITE
EOF"
					fi
					
					# Make virtual host configuration to Apache take effect
					sudo a2ensite $TARGET_ITS_BUGZILLA_SITE
					sudo a2dissite default
					sudo /etc/init.d/apache2 restart
					;;
				*)
					echo 
					echo "** HTTP not supported for 'Bugzilla' yet."
					return
					;;
			esac
			;;
		*)
			echo
			echo "** Invalid webserver type for Bugzilla: '$TARGET_ITS_BUGZILLA_WEBSERVER'"
			return
			;;
	esac
}

# Preinstall packages required for Bugzilla
function itsserver_bugzilla_preinstall()
{
	if [ -z "$TARGET_ITS" ] ; then
		echo 
		echo "** TARGET_ITS not set yet. Check your site specs to fix it."
		return
	fi
	
	if [ -n "$TARGET_ITS_BUGZILLA_WEBSERVER" ] ; then
		webserver $TARGET_ITS_BUGZILLA_WEBSERVER
	fi
	if [ -n "$TARGET_ITS_BUGZILLA_DBENGINE" ] ; then
		dbengine $TARGET_ITS_BUGZILLA_DBENGINE
	fi
	if [ "$TARGET_ITS_URL" = "https" -o "$TARGET_ITS_URL" = "HTTPS" ] ; then
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

# Clean all settings simply around Bugzilla
function itsserver_bugzilla_clean()
{
	if [ -z "$TARGET_ITS" ] ; then
		echo 
		echo "** TARGET_ITS not set yet. Check your site specs to fix it."
		return
	fi
	
	echo
	echo "Cleaning for site[$TARGET_ITS_BUGZILLA_SITE]@ipadd[$TARGET_ITS_IPADDR]..."
	
	case $TARGET_ITS_BUGZILLA_DBENGINE in
		mysql | MYSQL)
			local MYSQL MYSQL_HEADER_COMPLEX MYSQL_HEADER_SIMPLE MYSQL_ROOTPW 
			local dbhost dbuser dbname
			MYSQL=(`which mysql`)
			if [ -z $TARGET_ITS_BUGZILLA_MYSQL_DBNAME ] ; then
				dbname=(`echo -n $TARGET_ITS_BUGZILLA_SITE | sed -e "s/\./_/g"`)
				export TARGET_ITS_BUGZILLA_MYSQL_DBNAME=$dbname
			else
				dbname=$TARGET_ITS_BUGZILLA_MYSQL_DBNAME
			fi
			if [ -z "$TARGET_DBENGINE_MYSQL_ROOTPW" ] ; then
				read -s -p "Enter password for MySQL: " MYSQL_ROOTPW
				export TARGET_DBENGINE_MYSQL_ROOTPW=$MYSQL_ROOTPW
			else
				MYSQL_ROOTPW=$TARGET_DBENGINE_MYSQL_ROOTPW
			fi
			if [ -z "$TARGET_ITS_BUGZILLA_MYSQL_DBUSER" ] ; then
				dbuser=bugzilla
				export TARGET_ITS_BUGZILLA_MYSQL_DBUSER=$dbuser
			else
				dbuser=$TARGET_ITS_BUGZILLA_MYSQL_DBUSER
			fi
			if [ -z "$TARGET_DBENGINE_MYSQL_HOST" ] ; then
				dbhost=localhost
				TARGET_DBENGINE_MYSQL_HOST=$dbhost
			else
				dbhost=$TARGET_DBENGINE_MYSQL_HOST
			fi
			
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
			echo "** Invalid dbengine type for Bugzilla: '$TARGET_ITS_BUGZILLA_DBENGINE'"
			return
			;;
	esac
			
	case $TARGET_ITS_BUGZILLA_WEBSERVER in
		apache2)
			if [ -f /etc/apache2/sites-available/$TARGET_ITS_BUGZILLA_SITE ] ; then
				sudo rm /etc/apache2/sites-available/$TARGET_ITS_BUGZILLA_SITE
			fi
			if [ -L /etc/apache2/sites-enabled/$TARGET_ITS_BUGZILLA_SITE ] ; then
				sudo rm /etc/apache2/sites-enabled/$TARGET_ITS_BUGZILLA_SITE
			fi
			;;
		*)
			echo
			echo "** Invalid webserver type for $TARGET_ITS: '$TARGET_ITS_BUGZILLA_WEBSERVER'"
			return
			;;
	esac
	
	if [ -d /home/www-data/$TARGET_ITS_BUGZILLA_SITE ] ; then
		sudo rm -rf /home/www-data/$TARGET_ITS_BUGZILLA_SITE
	fi
}

# Setup ITS Bugzilla
function itsserver_bugzilla()
{
	if [ -z "$TARGET_ITS" ] ; then
		echo 
		echo "** TARGET_ITS not set yet. Check your site specs to fix it."
		return
	fi
	
	local goal
	for goal in ${TARGET_SITE_GOALS[@]}
	do
		case $goal in
			clean)
				itsserver_bugzilla_clean
				;;
			preinstall)
				itsserver_bugzilla_preinstall
				;;
			configure)
				itsserver_bugzilla_configure
				;;
			install)
				itsserver_bugzilla_install
				;;
			postconfig)
				itsserver_bugzilla_postconfig
				;;
			custom)
				itsserver_bugzilla_custom
				;;
			backup)
				itsserver_bugzilla_backup
				;;
			upgrade)
				itsserver_bugzilla_upgrade
				;;
			lite)
				itsserver_bugzilla_clean
				itsserver_bugzilla_preinstall
				itsserver_bugzilla_configure
				itsserver_bugzilla_install
				;;
			all)
				itsserver_bugzilla_clean
				itsserver_bugzilla_preinstall
				itsserver_bugzilla_configure
				itsserver_bugzilla_install
				itsserver_bugzilla_postconfig
				itsserver_bugzilla_custom
				;;
			*)
				echo
				echo "** Invalid TARGET SITE GOALS: '$goal'"
				return
				;;
		esac
	done
}

# Setup ITS server
function itsserver()
{
	# Note that TARGET_ITS has support only for one kind of ITS for now, 
	# which includes Bugzilla.
	local its
	for its in ${TARGET_ITS[@]}
	do
		if [ $its = "bugzilla" ] ; then
			itsserver_bugzilla
		else
			echo 
			echo "** Invalid ITS: '$its'"
			echo "** Must be one of '${ITS_CHOICES[@]}'"
			return
		fi
	done
}

# Upgrade CMS Mediawiki
function cmsserver_mediawiki_upgrade()
{
	if [ -z "$TARGET_CMS" ] ; then
		echo 
		echo "** TARGET_CMS not set yet. Check your site specs to fix it."
		return
	fi
}

# Backup CMS Mediawiki
function cmsserver_mediawiki_backup()
{
	if [ -z "$TARGET_CMS" ] ; then
		echo 
		echo "** TARGET_CMS not set yet. Check your site specs to fix it."
		return
	fi
}

# Customize CMS Mediawiki
function cmsserver_mediawiki_custom()
{
	if [ -z "$TARGET_CMS" ] ; then
		echo 
		echo "** TARGET_CMS not set yet. Check your site specs to fix it."
		return
	fi
}

# Postconfig CMS Mediawiki
function cmsserver_mediawiki_postconfig()
{
	if [ -z "$TARGET_CMS" ] ; then
		echo 
		echo "** TARGET_CMS not set yet. Check your site specs to fix it."
		return
	fi
	
	# Install Math extensions
	wget https://nodeload.github.com/wikimedia/mediawiki-extensions-Math/legacy.tar.gz/REL1_20
	tar -xzf wikimedia-mediawiki-extensions-Math-a998a49.tar.gz -C /var/www/mediawiki/extensions
	
	sudo apt-get -y install imagemagick
	sudo apt-get -y install ocaml make texlive cjk-latex
}

# Install CMS Mediawiki
function cmsserver_mediawiki_install()
{
	if [ -z "$TARGET_CMS" ] ; then
		echo 
		echo "** TARGET_CMS not set yet. Check your site specs to fix it."
		return
	fi
	
	# Install Mediawiki
	echo 
	echo "Installing site[$TARGET_CMS_MEDIAWIKI_SITE]@IPaddr[$TARGET_CMS_IPADDR]..."
	echo
	
	if [ ! -d /home/www-data/$TARGET_CMS_MEDIAWIKI_SITE ] ; then
		sudo -H -u www-data mkdir /home/www-data/$TARGET_CMS_MEDIAWIKI_SITE
	fi
	# Pick up the latest stable version of Mediawiki 
	# from http://www.mediawiki.org/wiki/Download,
	# or from http://download.wikimedia.org/mediawiki/
	local cmstop=/home/www-data/$TARGET_CMS_MEDIAWIKI_SITE
	if [ ! -f $cmstop/LocalSettings.php ] ; then
		local download_url=http://download.wikimedia.org/mediawiki
		local full_version=$TARGET_CMS_MEDIAWIKI_VERSION_INSTALLED
		local main_version=(`echo -n $full_version | sed -e "s/\(^[0-9]*\.[0-9]*\).*/\1/"`)
		local stable=mediawiki-$full_version.tar.gz
		sudo -H -u www-data wget -P $cmstop $download_url/$main_version/$stable
		sudo -H -u www-data tar xzvf $cmstop/$stable -C $mwtop
		sudo -H -u www-data mv $cmstop/mediawiki-$full_version/* $cmstop/
		sudo -H -u www-data rm -rf $cmstop/mediawiki-$full_version
		sudo -H -u www-data rm $cmstop/$stable
	fi
}

# Configure CMS Mediawiki
function cmsserver_mediawiki_configure()
{
	if [ -z "$TARGET_CMS" ] ; then
		echo 
		echo "** TARGET_CMS not set yet. Check your site specs to fix it."
		return
	fi
	
	case $TARGET_CMS_MEDIAWIKI_DBENGINE in
		mysql | MYSQL)
			local MYSQL MYSQL_HEADER MYSQL_ROOTPW
			local dbhost dbname dbuser dbpw
			
			# Create a new database via mysql for Mediawiki use which is named 
			# after by means of this variable,TARGET_CMS_MEDIAWIKI_SITE. Let's say,
			# this name of the database would be wiki_xbmlabs_org if this value of
			# the variable is wiki.xbmlabs.org.
			MYSQL=(`which mysql`)
			if [ -z $TARGET_CMS_MEDIAWIKI_MYSQL_DBNAME ] ; then
				dbname=(`echo -n $TARGET_CMS_MEDIAWIKI_SITE | sed -e "s/\./_/g"`)
				export TARGET_CMS_MEDIAWIKI_MYSQL_DBNAME=$dbname
			else
				dbname=$TARGET_CMS_MEDIAWIKI_MYSQL_DBNAME
			fi
			echo 
			echo "Creating database[$dbname] in MySQL for Mediawiki..."
			echo
			if [ -z "$TARGET_DBENGINE_MYSQL_ROOTPW" ] ; then
				read -s -p "Enter password for MySQL: " MYSQL_ROOTPW
				export TARGET_DBENGINE_MYSQL_ROOTPW=$MYSQL_ROOTPW
			else
				MYSQL_ROOTPW=$TARGET_DBENGINE_MYSQL_ROOTPW
			fi
			MYSQL_HEADER="$MYSQL -u root -p'$MYSQL_ROOTPW' --batch --skip-column-names -e"
			if [ ! `$MYSQL_HEADER "SHOW DATABASES LIKE '$dbname';"` ] ; then
				if [ -z "$TARGET_CMS_MEDIAWIKI_MYSQL_DBPW" ] ; then
					read -s -p "Enter password for $TARGET_CMS_WIKI database: " dbpw
				else
					dbpw=$TARGET_CMS_MEDIAWIKI_MYSQL_DBPW
				fi
				if [ -z "$TARGET_CMS_MEDIAWIKI_MYSQL_DBUSER" ] ; then
					dbuser=mediawiki
					export TARGET_CMS_MEDIAWIKI_MYSQL_DBUSER=$dbuser
				else
					dbuser=$TARGET_CMS_MEDIAWIKI_MYSQL_DBUSER
				fi
				if [ -z "$TARGET_DBENGINE_MYSQL_HOST" ] ; then
					dbhost=localhost
					export TARGET_DBENGINE_MYSQL_HOST=$dbhost
				else
					dbhost=$TARGET_DBENGINE_MYSQL_HOST
				fi
				MYSQL_HEADER="$MYSQL -u root -p'$MYSQL_ROOTPW' -e"
				$MYSQL_HEADER "CREATE DATABASE $dbname;"
				$MYSQL_HEADER "CREATE USER '$dbuser'@'$dbhost' IDENTIFIED BY '$dbpw';"
				$MYSQL_HEADER "GRANT ALL ON $dbname.* TO '$dbuser'@'$dbhost';"
				$MYSQL_HEADER "FLUSH PRIVILEGES;"
				$MYSQL_HEADER "QUIT"
			fi
			;;
		*)
			echo
			echo "** Invalid dbengine type for $TARGET_CMS_WIKI: '$TARGET_CMS_MEDIAWIKI_DBENGINE'"
			return
			;;
	esac
	
	# Adjust parameters in php.ini to fit your needs when running Mediawiki
	local phpconfig=/etc/php5/apache2/php.ini
	if [ -f $phpconfig ] ; then
		local threshold=32 #32M used as the minimum for size of file upload
		local defsize=(`grep -e "^upload_max_filesize" | sed -e "s/[^0-9]//g"`)
		if [ $defsize < $threhold ] ; then
			sudo sed -i -e "s/\(^upload_max_filesize = \).*/\132M/" $phpconfig
		fi
		
		defsize=(`grep -e "^memory_limit" | sed -e "s/[^0-9]//g"`)
		if [ $defsize < $threhold ] ; then
			sudo sed -i -e "s/\(^memory_limit = \).*/\132M/" $phpconfig
		fi
		
		case $TARGET_CMS_MEDIAWIKI_DBENGINE in
			mysql | MYSQL)
				local keys=(`grep -e "^extension=mysql.so" $phpconfig`)
				if [ ! "$keys" ] ; then
					local line=(`cat $phpconfig | grep -n "^\; Dynamic Extensions \;" | grep -o "^[0-9]*"`)
					line=$((line+2))
					sudo sed -i -e "$line i\extension=mysql.so" $phpconfig
				fi
				;;
			*)
				echo
				echo "** Invalid dbengine type for $TARGET_CMS_WIKI: '$TARGET_CMS_MEDIAWIKI_DBENGINE'"
				return
				;;
		esac				
	fi
	
	case $TARGET_CMS_MEDIAWIKI_WEBSERVER in
		apache2)
			local cms_url
			if [ -n $TARGET_CMS_MEDIAWIKI_URL ] ; then
				cms_url=$TARGET_CMS_MEDIAWIKI_URL
			else
				cms_url=$TARGET_CMS_URL
			fi
			
			case $cms_url in
				https | HTTPS)
					sudo a2enmod ssl rewrite
					# Configure virtual host as well as port for Bugzilla 
					# on Apache server
					if [ ! -f /etc/apache2/sites-available/$TARGET_CMS_MEDIAWIKI_SITE ] ; then
						# Generate a self-signed certificate for SSL
						if [ ! -d /etc/apache2/ssl ] ; then
							sudo mkdir /etc/apache2/ssl
						fi
						if [ ! -f /etc/apache2/ssl/$TARGET_SITE.pem -o ! -f /etc/apache2/ssl/$TARGET_SITE.key ] ; then
							local OPENSSL=(`which openssl`)
							$OPENSSL req -new -x509 -days 365 -nodes -out $TARGET_SITE.pem -keyout $TARGET_SITE.key
							sudo mv $TARGET_SITE.pem /etc/apache2/ssl
							sudo mv $TARGET_SITE.key /etc/apache2/ssl
						fi
		
						local vhconfig=$TARGET_SITE.$cmsmw_url
						sudo cp site/*/$TARGET_SITE/$vhconfig /etc/apache2/sites-available/$TARGET_CMS_MEDIAWIKI_SITE
		
						# Enable virtualhost at port 443 for ssl
						local keys
						keys=(`grep "^[[:space:]]NameVirtualHost \*:443" /etc/apache2/ports.conf`)
						if [ ! "$keys" ] ; then
						sudo sed -i -e "/^<IfModule mod_ssl.c>.*/a\\\tNameVirtualHost \*:443" /etc/apache2/ports.conf
						fi
					fi
					
					# Match host names with IP address
					keys=(`cat /etc/hosts | grep -i -e "^[0-9\.]*[[:space:]]*$TARGET_CMS_MEDIAWIKI_SITE"`)
					if [ ! "$keys" ] ; then
					sudo bash -c "cat >>/etc/hosts <<EOF
$TARGET_CMS_IPADDR $TARGET_CMS_MEDIAWIKI_SITE
EOF"
					fi
					
					# Make virtual host configuration to Apache take effect
					sudo a2ensite $TARGET_CMS_MEDIAWIKI_SITE
					sudo a2dissite default
					sudo /etc/init.d/apache2 restart
					;;
				*)
					echo 
					echo "** HTTP not supported for '$TARGET_CMS_WIKI' yet."
					return
					;;
			esac
			;;
		*)
			echo
			echo "** Invalid webserver type for $TARGET_CMS_WIKI: '$TARGET_CMS_MEDIAWIKI_WEBSERVER'"
			return
			;;
	esac
}

# Preinstall packages required for Mediawiki
function cmsserver_mediawiki_preinstall()
{
	if [ -z "$TARGET_CMS" ] ; then
		echo 
		echo "** TARGET_CMS not set yet. Check your site specs to fix it."
		return
	fi
	
	if [ -n "$TARGET_CMS_MEDIAWIKI_WEBSERVER" ] ; then
		webserver $TARGET_CMS_MEDIAWIKI_WEBSERVER
	fi
	if [ -n "$TARGET_CMS_MEDIAWIKI_DBENGINE" ] ; then
		dbengine $TARGET_CMS_MEDIAWIKI_DBENGINE
	fi
	local cms_url
	if [ -n $TARGET_CMS_MEDIAWIKI_URL ] ; then
		cms_url=$TARGET_CMS_MEDIAWIKI_URL
	else
		cms_url=$TARGET_CMS_URL
	fi
	if [ "$cms_url" = "https" -o "$cms_url" = "HTTPS" ] ; then
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
	case $TARGET_CMS_MEDIAWIKI_WEBSERVER in
		apache2)
			sudo apt-get -y install libapache2-mod-php5
			sudo a2enmod php5
			;;
		*)
			echo
			echo "** Invalid webserver type for $TARGET_CMS: '$TARGET_CMS_MEDIAWIKI_WEBSERVER'"
			return
			;;
	esac
	case $TARGET_CMS_MEDIAWIKI_DBENGINE in
		mysql | MYSQL)
			sudo apt-get -y install php5-mysql
			;;
		*)
			echo
			echo "** Invalid dbengine type for $TARGET_CMS_WIKI: '$TARGET_CMS_MEDIAWIKI_DBENGINE'"
			return
			;;
	esac
	sudo apt-get -y install php-pear php5-cli php5-intl
}

# Clean all settings simply around Media6wiki
function cmsserver_mediawiki_clean()
{
	if [ -z "$TARGET_CMS_WIKI" ] ; then
		echo 
		echo "** TARGET_CMS_WIKI not set yet. Check your site specs to fix it."
		return
	fi
	
	echo
	echo "Cleaning up settings for site[$TARGET_CMS_MEDIAWIKI_SITE]@ipadd[$TARGET_CMS_IPADDR]..."
	
	case $TARGET_CMS_MEDIAWIKI_DBENGINE in
		mysql | MYSQL)
			local MYSQL MYSQL_HEADER_COMPLEX MYSQL_HEADER_SIMPLE MYSQL_ROOTPW 
			local dbname
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
				dbuser=wiki
				export TARGET_CMS_MEDIAWIKI_MYSQL_DBUSER=$dbuser
			else
				dbuser=$TARGET_CMS_MEDIAWIKI_MYSQL_DBUSER
			fi
			MYSQL_HEADER_COMPLEX="$MYSQL -u root -p'$MYSQL_ROOTPW' --batch --skip-column-names -e"
			MYSQL_HEADER_SIMPLE="$MYSQL -u root -p'$MYSQL_ROOTPW' -e"
			if [ `$MYSQL_HEADER_COMPLEX "SHOW DATABASES LIKE '$dbname';"` ] ; then
				$MYSQL_HEADER_SIMPLE "DROP DATABASE $dbname;"
			fi
			if [ `$MYSQL_HEADER_COMPLEX "SELECT USER FROM mysql.user WHERE user='$dbuser';"` ] ; then
				$MYSQL_HEADER_SIMPLE "DROP USER $dbuser;"
			fi
			;;
		*)
			echo
			echo "** Invalid dbengine type for $TARGET_CMS_WIKI: '$TARGET_CMS_MEDIAWIKI_DBENGINE'"
			return
			;;
	esac
			
	case $TARGET_CMS_MEDIAWIKI_WEBSERVER in
		apache2)
			if [ -f /etc/apache2/sites-available/$TARGET_CMS_MEDIAWIKI_SITE ] ; then
				sudo rm /etc/apache2/sites-available/$TARGET_CMS_MEDIAWIKI_SITE
			fi
			if [ -L /etc/apache2/sites-enabled/$TARGET_CMS_MEDIAWIKI_SITE ] ; then
				sudo rm /etc/apache2/sites-enabled/$TARGET_CMS_MEDIAWIKI_SITE
			fi
			;;
		*)
			echo
			echo "** Invalid webserver type for $TARGET_CMS_WIKI: '$TARGET_CMS_MEDIAWIKI_WEBSERVER'"
			return
			;;
	esac
	
	if [ -d /home/www-data/$TARGET_CMS_MEDIAWIKI_SITE ] ; then
		sudo rm -rf /home/www-data/$TARGET_CMS_MEDIAWIKI_SITE
	fi
}

# Setup CMS Mediawiki
function cmsserver_mediawiki()
{
	if [ -z "$TARGET_CMS_WIKI" ] ; then
		echo 
		echo "** TARGET_CMS_WIKI not set yet. Check your site specs to fix it."
		return
	fi
	
	local goal
	for goal in ${TARGET_SITE_GOALS[@]}
	do
		case $goal in
			clean)
				cmsserver_mediawiki_clean
				;;
			preinstall)
				cmsserver_mediawiki_preinstall
				;;
			configure)
				cmsserver_mediawiki_configure
				;;
			install)
				cmsserver_mediawiki_install
				;;
			postconfig)
				cmsserver_mediawiki_postconfig
				;;
			custom)
				cmsserver_mediawiki_custom
				;;
			backup)
				cmsserver_mediawiki_backup
				;;
			upgrade)
				cmsserver_mediawiki_upgrade
				;;
			lite)
				cmsserver_mediawiki_clean
				cmsserver_mediawiki_preinstall
				cmsserver_mediawiki_configure
				cmsserver_mediawiki_install
				;;
			all)
				cmsserver_mediawiki_clean
				cmsserver_mediawiki_preinstall
				cmsserver_mediawiki_configure
				cmsserver_mediawiki_install
				cmsserver_mediawiki_postconfig
				cmsserver_mediawiki_custom
				;;
			*)
				echo
				echo "** Invalid TARGET SITE GOALS: '$goal'"
				return
				;;
		esac
	done
}

# Install Custom CMS
function cmsserver_custom_install()
{	
	if [ -z "$TARGET_CMS" ] ; then
		echo 
		echo "** TARGET_CMS not set yet. Check your site specs to fix it."
		return
	fi
	
	echo 
	echo "Installing for site[$TARGET_CMS_CUSTOM_SITE]@IPaddr[$TARGET_CMS_IPADDR]..."
	
	# Serve up your site
	if [ ! -d /home/www-data/$TARGET_CMS_CUSTOM_SITE ] ; then
		sudo -H -u www-data mkdir /home/www-data/$TARGET_CMS_CUSTOM_SITE
	fi
	sudo cp -R site/*/$TARGET_CMS_CUSTOM_SITE/custom/* /home/www-data/$TARGET_CMS_CUSTOM_SITE
	sudo chown -R www-data:www-data /home/www-data/$TARGET_CMS_CUSTOM_SITE
}

# Configure Custom CMS
function cmsserver_custom_configure()
{
	if [ -z "$TARGET_CMS" ] ; then
		echo 
		echo "** TARGET_CMS not set yet. Check your site specs to fix it."
		return
	fi
	
	case $TARGET_CMS_CUSTOM_WEBSERVER in
		apache2)
			# Configure virtual host for your site
			if [ ! -f /etc/apache2/sites-available/$TARGET_CMS_CUSTOM_SITE ] ; then
				sudo cp site/*/$TARGET_SITE/$TARGET_CMS_CUSTOM_SITE /etc/apache2/sites-available/$TARGET_CMS_CUSTOM_SITE
			fi
			
			# Match host names with IP address
			keys=(`cat /etc/hosts | grep -i -e "^[0-9\.]*[[:space:]]*$TARGET_CMS_CUSTOM_SITE"`)
			if [ ! "$keys" ] ; then
				sudo bash -c "cat >>/etc/hosts <<EOF
$TARGET_CMS_IPADDR $TARGET_CMS_CUSTOM_SITE
$TARGET_CMS_IPADDR www.$TARGET_CMS_CUSTOM_SITE
EOF"
			fi
	
			# Make virtual host configuration for Apache take effect
			sudo a2ensite $TARGET_CMS_CUSTOM_SITE
			sudo a2dissite default
			sudo /etc/init.d/apache2 restart
			;;
		*)
			echo
			echo "** Invalid webserver type for CMS Custom: '$TARGET_CMS_CUSTOM_WEBSERVER'"
			return
			;;
	esac
}

# Preinstall packages required for Custom CMS
function cmsserver_custom_preinstall()
{
	if [ -z "$TARGET_CMS" ] ; then
		echo 
		echo "** TARGET_CMS not set yet. Check your site specs to fix it."
		return
	fi
	
	if [ -n "$TARGET_CMS_CUSTOM_WEBSERVER" ] ; then
		webserver $TARGET_CMS_CUSTOM_WEBSERVER
	fi
	if [ -n "$TARGET_CMS_CUSTOM_DBENGINE" ] ; then
		dbengine $TARGET_CMS_CUSTOM_DBENGINE
	fi
}

# Clean Custom CMS
function cmsserver_custom_clean()
{
	if [ -z "$TARGET_CMS" ] ; then
		echo 
		echo "** TARGET_CMS not set yet. Check your site specs to fix it."
		return
	fi
	
	echo
	echo "Cleaning for site[$TARGET_CMS_CUSTOM_SITE]@ipadd[$TARGET_CMS_IPADDR]..."
	echo
			
	case $TARGET_CMS_CUSTOM_WEBSERVER in
		apache2)
			if [ -f /etc/apache2/sites-available/$TARGET_CMS_CUSTOM_SITE ] ; then
				sudo rm /etc/apache2/sites-available/$TARGET_CMS_CUSTOM_SITE
			fi
			if [ -L /etc/apache2/sites-enabled/$TARGET_CMS_CUSTOM_SITE ] ; then
				sudo rm /etc/apache2/sites-enabled/$TARGET_CMS_CUSTOM_SITE
			fi
			;;
		*)
			echo
			echo "** Invalid webserver type for CMS-Custom: '$TARGET_CMS_CUSTOM_WEBSERVER'"
			return
			;;
	esac
	
	if [ -d /home/www-data/$TARGET_CMS_CUSTOM_SITE ] ; then
		sudo rm -rf /home/www-data/$TARGET_CMS_CUSTOM_SITE
	fi
}

# Setup Custom CMS
function cmsserver_custom()
{
	if [ -z "$TARGET_CMS" ] ; then
		echo 
		echo "** TARGET_CMS not set yet. Check your site specs to fix it."
		return
	fi
	
	local goal
	for goal in ${TARGET_SITE_GOALS[@]}
	do
		case $goal in
			clean)
				cmsserver_custom_clean
				;;
			preinstall)
				cmsserver_custom_preinstall
				;;
			configure)
				cmsserver_custom_configure
				;;
			install)
				cmsserver_custom_install
				;;
			lite)
				cmsserver_custom_clean
				cmsserver_custom_preinstall
				cmsserver_custom_configure
				cmsserver_custom_install
				;;
			all)
				cmsserver_custom_clean
				cmsserver_custom_preinstall
				cmsserver_custom_configure
				cmsserver_custom_install
				;;
			*)
				echo
				echo "** Invalid TARGET SITE GOALS: '$goal'"
				return
				;;
		esac
	done
}

# Upgrade CMS Drupal
function cmsserver_drupal_upgrade()
{
	if [ -z "$TARGET_CMS" ] ; then
		echo 
		echo "** TARGET_CMS not set yet. Check your site specs to fix it."
		return
	fi
}

# Backup CMS Drupal
function cmsserver_drupal_backup()
{
	if [ -z "$TARGET_CMS" ] ; then
		echo 
		echo "** TARGET_CMS not set yet. Check your site specs to fix it."
		return
	fi
}

# Customize CMS Drupal
function cmsserver_drupal_custom()
{
	if [ -z "$TARGET_CMS" ] ; then
		echo 
		echo "** TARGET_CMS not set yet. Check your site specs to fix it."
		return
	fi
}

# Postconfig CMS Drupal
function cmsserver_drupal_postconfig()
{
	if [ -z "$TARGET_CMS" ] ; then
		echo 
		echo "** TARGET_CMS not set yet. Check your site specs to fix it."
		return
	fi
}

# Install CMS Drupal
function cmsserver_drupal_install()
{
	if [ -z "$TARGET_CMS" ] ; then
		echo 
		echo "** TARGET_CMS not set yet. Check your site specs to fix it."
		return
	fi
	
	echo 
	echo "Installing site[$TARGET_CMS_DRUPAL_SITE]@IPaddr[$TARGET_CMS_IPADDR]..."
	echo
	
	if [ ! -d /home/www-data/$TARGET_CMS_DRUPAL_SITE ] ; then
		sudo -H -u www-data mkdir /home/www-data/$TARGET_CMS_DRUPAL_SITE
	fi
	# Pick up the latest stable version of Drupal 
	# from http://drupal.org/project/drupal
	local cmstop=/home/www-data/$TARGET_CMS_DRUPAL_SITE
	if [ ! -f $cmstop/sites/default/settings.php ] ; then
		local download_url=http://ftp.drupal.org/files/projects
		local full_version=$TARGET_CMS_DRUPAL_VERSION_INSTALLED
		local stable=drupal-$full_version.tar.gz
		sudo -H -u www-data wget -P $cmstop $download_url/$stable
		sudo -H -u www-data tar xzvf $cmstop/$stable -C $cmstop
		sudo -H -u www-data mv $cmstop/drupal-$full_version/* $cmstop/
		sudo -H -u www-data mv $cmstop/drupal-$full_version/.htaccess $cmstop/
		sudo -H -u www-data rm -rf $cmstop/drupal-$full_version
		sudo -H -u www-data rm $cmstop/$stable
		
		sudo -H -u www-data cp $cmstop/sites/default/default.settings.php $cmstop/sites/default/settings.php
	fi
}

# Configure CMS Drupal
function cmsserver_drupal_configure()
{
	if [ -z "$TARGET_CMS" ] ; then
		echo 
		echo "** TARGET_CMS not set yet. Check your site specs to fix it."
		return
	fi
	
	case $TARGET_CMS_DRUPAL_DBENGINE in
		mysql | MYSQL)
			local MYSQL MYSQL_HEADER MYSQL_ROOTPW
			local dbhost dbname dbuser dbpw
			
			# Create a new database via mysql for Drupal use which is named 
			# after by means of this variable,TARGET_CMS_DRUPAL_SITE. Let's say,
			# this name of the database would be mci_org if this value of
			# the variable is mci.org.
			MYSQL=(`which mysql`)
			if [ -z $TARGET_CMS_DRUPAL_MYSQL_DBNAME ] ; then
				dbname=(`echo -n $TARGET_CMS_DRUPAL_SITE | sed -e "s/\./_/g"`)
				export TARGET_CMS_DRUPAL_MYSQL_DBNAME=$dbname
			else
				dbname=$TARGET_CMS_DRUPAL_MYSQL_DBNAME
			fi
			echo 
			echo "Creating database[$dbname] in MySQL for Drupal..."
			echo
			if [ -z "$TARGET_DBENGINE_MYSQL_ROOTPW" ] ; then
				read -s -p "Enter password for MySQL: " MYSQL_ROOTPW
				export TARGET_DBENGINE_MYSQL_ROOTPW=$MYSQL_ROOTPW
			else
				MYSQL_ROOTPW=$TARGET_DBENGINE_MYSQL_ROOTPW
			fi
			MYSQL_HEADER="$MYSQL -u root -p'$MYSQL_ROOTPW' --batch --skip-column-names -e"
			if [ ! `$MYSQL_HEADER "SHOW DATABASES LIKE '$dbname';"` ] ; then
				if [ -z "$TARGET_CMS_DRUPAL_MYSQL_DBPW" ] ; then
					read -s -p "Enter password for Drupal database: " dbpw
				else
					dbpw=$TARGET_CMS_DRUPAL_MYSQL_DBPW
				fi
				if [ -z "$TARGET_CMS_DRUPAL_MYSQL_DBUSER" ] ; then
					dbuser=drupal
					export TARGET_CMS_DRUPAL_MYSQL_DBUSER=$dbuser
				else
					dbuser=$TARGET_CMS_DRUPAL_MYSQL_DBUSER
				fi
				if [ -z "$TARGET_DBENGINE_MYSQL_HOST" ] ; then
					dbhost=localhost
					export TARGET_DBENGINE_MYSQL_HOST=$dbhost
				else
					dbhost=$TARGET_DBENGINE_MYSQL_HOST
				fi
				MYSQL_HEADER="$MYSQL -u root -p'$MYSQL_ROOTPW' -e"
				$MYSQL_HEADER "CREATE DATABASE $dbname;"
				$MYSQL_HEADER "CREATE USER '$dbuser'@'$dbhost' IDENTIFIED BY '$dbpw';"
				$MYSQL_HEADER "GRANT ALL ON $dbname.* TO '$dbuser'@'$dbhost';"
				$MYSQL_HEADER "FLUSH PRIVILEGES;"
				$MYSQL_HEADER "QUIT"
			fi
			;;
		*)
			echo
			echo "** Invalid dbengine type for Drupal: '$TARGET_CMS_DRUPAL_DBENGINE'"
			return
			;;
	esac
	
	case $TARGET_CMS_DRUPAL_WEBSERVER in
		apache2)
			# Configure virtual host for your site
			if [ ! -f /etc/apache2/sites-available/$TARGET_CMS_DRUPAL_SITE ] ; then
				sudo cp sites/*/$TARGET_SITE/$TARGET_CMS_DRUPAL_SITE /etc/apache2/sites-available/$TARGET_CMS_DRUPAL_SITE
			fi
			
			# Match host names with IP address
			keys=(`cat /etc/hosts | grep -i -e "^[0-9\.]*[[:space:]]*$TARGET_CMS_DRUPAL_SITE"`)
			if [ ! "$keys" ] ; then
				sudo bash -c "cat >>/etc/hosts <<EOF
$TARGET_CMS_IPADDR $TARGET_CMS_DRUPAL_SITE
$TARGET_CMS_IPADDR www.$TARGET_CMS_DRUPAL_SITE
EOF"
			fi
	
			# Make virtual host configuration for Apache take effect
			sudo a2ensite $TARGET_CMS_DRUPAL_SITE
			sudo a2dissite default
			sudo /etc/init.d/apache2 restart
			;;
		*)
			echo
			echo "** Invalid webserver type for CMS Custom: '$TARGET_CMS_CUSTOM_WEBSERVER'"
			return
			;;
	esac
}

# Preinstall packages required for Drupal
function cmsserver_drupal_preinstall()
{
	if [ -z "$TARGET_CMS" ] ; then
		echo 
		echo "** TARGET_CMS not set yet. Check your site specs to fix it."
		return
	fi
	
	if [ -n "$TARGET_CMS_DRUPAL_WEBSERVER" ] ; then
		webserver $TARGET_CMS_DRUPAL_WEBSERVER
	fi
	if [ -n "$TARGET_CMS_DRUPAL_DBENGINE" ] ; then
		dbengine $TARGET_CMS_DRUPAL_DBENGINE
	fi
	local cms_url
	if [ -n $TARGET_CMS_DRUPAL_URL ] ; then
		cms_url=$TARGET_CMS_DRUPAL_URL
	else
		cms_url=$TARGET_CMS_URL
	fi
	if [ "$cms_url" = "https" -o "$cms_url" = "HTTPS" ] ; then
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
	case $TARGET_CMS_DRUPAL_WEBSERVER in
		apache2)
			sudo apt-get -y install libapache2-mod-php5
			sudo a2enmod php5
			;;
		*)
			echo
			echo "** Invalid webserver type for Drupal: '$TARGET_CMS_DRUPAL_WEBSERVER'"
			return
			;;
	esac
	case $TARGET_CMS_DRUPAL_DBENGINE in
		mysql | MYSQL)
			sudo apt-get -y install php5-mysql
			;;
		*)
			echo
			echo "** Invalid dbengine type for Drupal: '$TARGET_CMS_DRUPAL_DBENGINE'"
			return
			;;
	esac
}

# Clean all settings simply around Drupal
function cmsserver_drupal_clean()
{
	if [ -z "$TARGET_CMS" ] ; then
		echo 
		echo "** TARGET_CMS not set yet. Check your site specs to fix it."
		return
	fi
	
	echo
	echo "Cleaning up settings for site[$TARGET_CMS_DRUPAL_SITE]@ipadd[$TARGET_CMS_IPADDR]..."
	echo
	
	case $TARGET_CMS_DRUPAL_DBENGINE in
		mysql | MYSQL)
			local MYSQL MYSQL_HEADER_COMPLEX MYSQL_HEADER_SIMPLE MYSQL_ROOTPW 
			local dbname
			MYSQL=(`which mysql`)
			if [ -z $TARGET_CMS_DRUPAL_MYSQL_DBNAME ] ; then
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
			MYSQL_HEADER_COMPLEX="$MYSQL -u root -p'$MYSQL_ROOTPW' --batch --skip-column-names -e"
			MYSQL_HEADER_SIMPLE="$MYSQL -u root -p'$MYSQL_ROOTPW' -e"
			if [ `$MYSQL_HEADER_COMPLEX "SHOW DATABASES LIKE '$dbname';"` ] ; then
				$MYSQL_HEADER_SIMPLE "DROP DATABASE $dbname;"
			fi
			if [ `$MYSQL_HEADER_COMPLEX "SELECT USER FROM mysql.user WHERE user='$dbuser';"` ] ; then
				$MYSQL_HEADER_SIMPLE "DROP USER $dbuser;"
			fi
			;;
		*)
			echo
			echo "** Invalid dbengine type for Drupal: '$TARGET_CMS_DRUPAL_DBENGINE'"
			return
			;;
	esac
			
	case $TARGET_CMS_DRUPAL_WEBSERVER in
		apache2)
			if [ -f /etc/apache2/sites-available/$TARGET_CMS_DRUPAL_SITE ] ; then
				sudo rm /etc/apache2/sites-available/$TARGET_CMS_DRUPAL_SITE
			fi
			if [ -L /etc/apache2/sites-enabled/$TARGET_CMS_DRUPAL_SITE ] ; then
				sudo rm /etc/apache2/sites-enabled/$TARGET_CMS_DRUPAL_SITE
			fi
			;;
		*)
			echo
			echo "** Invalid webserver type for Drupal: '$TARGET_CMS_DRUPAL_WEBSERVER'"
			return
			;;
	esac
	
	if [ -d /home/www-data/$TARGET_CMS_DRUPAL_SITE ] ; then
		sudo rm -rf /home/www-data/$TARGET_CMS_DRUPAL_SITE
	fi
}

# Setup CMS Drupal
function cmsserver_drupal()
{
	if [ -z "$TARGET_CMS" ] ; then
		echo 
		echo "** TARGET_CMS not set yet. Check your site specs to fix it."
		return
	fi
	
	local goal
	for goal in ${TARGET_SITE_GOALS[@]}
	do
		case $goal in
			clean)
				cmsserver_drupal_clean
				;;
			preinstall)
				cmsserver_drupal_preinstall
				;;
			configure)
				cmsserver_drupal_configure
				;;
			install)
				cmsserver_drupal_install
				;;
			postconfig)
				cmsserver_drupal_postconfig
				;;
			custom)
				cmsserver_drupal_custom
				;;
			backup)
				cmsserver_drupal_backup
				;;
			upgrade)
				cmsserver_drupal_upgrade
				;;
			lite)
				cmsserver_drupal_clean
				cmsserver_drupal_preinstall
				cmsserver_drupal_configure
				cmsserver_drupal_install
				;;
			all)
				cmsserver_drupal_clean
				cmsserver_drupal_preinstall
				cmsserver_drupal_configure
				cmsserver_drupal_install
				cmsserver_drupal_postconfig
				cmsserver_drupal_custom
				;;
			*)
				echo
				echo "** Invalid TARGET SITE GOALS: '$goal'"
				return
				;;
		esac
	done
}

# Setup CMS Server
function cmsserver()
{
	# Note that TARGET_CMS has support only for three forms of CMS, 
	# which covers drupal, mediawiki, custom
	local cms
	for cms in ${TARGET_CMS[@]}
	do
		if [ $cms = "drupal" ] ; then
			cmsserver_drupal
		elif [ $cms = "cmscustom" ] ; then
			cmsserver_custom
		elif [ $cms = "mediawiki" ] ; then
			cmsserver_mediawiki
		else
			echo 
			echo "** Invalid CMS: '$cms'"
			echo "** Must be one or two of '${CMS_CHOICES[@]}'"
			return
		fi
	done
}

# Upgrade SSO MIGO
function ssoserver_migo_upgrade()
{
	if [ -z "$TARGET_SSO" ] ; then
		echo 
		echo "** TARGET_SSO not set yet. Check your site specs to fix it."
		return
	fi
}

# Backup SSO MIGO
function ssoserver_migo_backup()
{
	if [ -z "$TARGET_SSO" ] ; then
		echo 
		echo "** TARGET_SSO not set yet. Check your site specs to fix it."
		return
	fi
}

# Customize SSO MIGO
function ssoserver_migo_custom()
{
	if [ -z "$TARGET_SSO" ] ; then
		echo 
		echo "** TARGET_SSO not set yet. Check your site specs to fix it."
		return
	fi
}

# Postconfig SSO MIGO
function ssoserver_migo_postconfig()
{
	if [ -z "$TARGET_SSO" ] ; then
		echo 
		echo "** TARGET_SSO not set yet. Check your site specs to fix it."
		return
	fi
}

# Install SSO MIGO
function ssoserver_migo_install()
{
	if [ -z "$TARGET_SSO" ] ; then
		echo 
		echo "** TARGET_SSO not set yet. Check your site specs to fix it."
		return
	fi
	
	echo 
	echo "Installing site[$TARGET_SSO_MIGO_SITE]@IPaddr[$TARGET_SSO_IPADDR]..."
	
	local ssotop=/home/www-data/$TARGET_SSO_MIGO_SITE
#	if [ ! -d $ssotop/.env ] ; then
#		sudo -u www-data git clone git://github.com/miing/mci_migo.git $ssotop
		cd $ssotop
		sudo fab bootstrap
		sudo chown -R www-data:www-data $ssotop
		sudo -u www-data fab setup_postgresql_server
		sudo -u www-data fab createsuperuser
		mcitop
#    fi
}

# Configure SSO MIGO
function ssoserver_migo_configure()
{
	if [ -z "$TARGET_SSO" ] ; then
		echo 
		echo "** TARGET_SSO not set yet. Check your site specs to fix it."
		return
	fi
	
	echo 
	echo "Configuring site[$TARGET_SSO_MIGO_SITE]@IPaddr[$TARGET_SSO_IPADDR]..."
	
#	case $TARGET_SSO_MIGO_DBENGINE in
#		postgresql | POSTGRESQL)
#			local MYSQL MYSQL_HEADER MYSQL_ROOTPW
#			local dbhost dbname dbuser dbpw
#			
#			# Create a new database via postgresql for Migo use which is named 
#			# after by means of this variable,TARGET_SSO_MIGO_SITE. Let's say,
#			# this name of the database would be login_mci_org if this value of
#			# the variable is loing.mci.org.
#			MYSQL=(`which mysql`)
#			if [ -z $TARGET_CMS_MEDIAWIKI_MYSQL_DBNAME ] ; then
#				dbname=(`echo -n $TARGET_CMS_MEDIAWIKI_SITE | sed -e "s/\./_/g"`)
#				export TARGET_CMS_MEDIAWIKI_MYSQL_DBNAME=$dbname
#			else
#				dbname=$TARGET_CMS_MEDIAWIKI_MYSQL_DBNAME
#			fi
#			echo 
#			echo "Creating database[$dbname] in MySQL for Mediawiki..."
#			echo
#			if [ -z "$TARGET_DBENGINE_MYSQL_ROOTPW" ] ; then
#				read -s -p "Enter password for MySQL: " MYSQL_ROOTPW
#				export TARGET_DBENGINE_MYSQL_ROOTPW=$MYSQL_ROOTPW
#			else
#				MYSQL_ROOTPW=$TARGET_DBENGINE_MYSQL_ROOTPW
#			fi
#			MYSQL_HEADER="$MYSQL -u root -p'$MYSQL_ROOTPW' --batch --skip-column-names -e"
#			if [ ! `$MYSQL_HEADER "SHOW DATABASES LIKE '$dbname';"` ] ; then
#				if [ -z "$TARGET_CMS_MEDIAWIKI_MYSQL_DBPW" ] ; then
#					read -s -p "Enter password for $TARGET_CMS_WIKI database: " dbpw
#				else
#					dbpw=$TARGET_CMS_MEDIAWIKI_MYSQL_DBPW
#				fi
#				if [ -z "$TARGET_CMS_MEDIAWIKI_MYSQL_DBUSER" ] ; then
#					dbuser=mediawiki
#					export TARGET_CMS_MEDIAWIKI_MYSQL_DBUSER=$dbuser
#				else
#					dbuser=$TARGET_CMS_MEDIAWIKI_MYSQL_DBUSER
#				fi
#				if [ -z "$TARGET_DBENGINE_MYSQL_HOST" ] ; then
#					dbhost=localhost
#					export TARGET_DBENGINE_MYSQL_HOST=$dbhost
#				else
#					dbhost=$TARGET_DBENGINE_MYSQL_HOST
#				fi
#				MYSQL_HEADER="$MYSQL -u root -p'$MYSQL_ROOTPW' -e"
#				$MYSQL_HEADER "CREATE DATABASE $dbname;"
#				$MYSQL_HEADER "CREATE USER '$dbuser'@'$dbhost' IDENTIFIED BY '$dbpw';"
#				$MYSQL_HEADER "GRANT ALL ON $dbname.* TO '$dbuser'@'$dbhost';"
#				$MYSQL_HEADER "FLUSH PRIVILEGES;"
#				$MYSQL_HEADER "QUIT"
#			fi
#			;;
#		*)
#			echo
#			echo "** Invalid dbengine type for Migo: '$TARGET_SSO_MIGO_DBENGINE'"
#			return
#			;;
#	esac
	
	case $TARGET_SSO_MIGO_WEBSERVER in
		apache2)
			local ssourl
			if [ -n "$TARGET_SSO_MIGO_URL" ] ; then
				ssourl=$TARGET_SSO_MIGO_URL
			else
				ssourl=$TARGET_SSO_URL
			fi
			
			case $ssourl in
				https | HTTPS)
					sudo a2enmod ssl rewrite wsgi
					# Configure virtual host as well as port for Migo 
					# on Apache server
					if [ ! -f /etc/apache2/sites-available/$TARGET_SSO_MIGO_SITE ] ; then
						# Generate a self-signed certificate for SSL
						if [ ! -d /etc/apache2/ssl ] ; then
							sudo mkdir /etc/apache2/ssl
						fi
						if [ ! -f /etc/apache2/ssl/$TARGET_SSO_MIGO_SITE.pem -o ! -f /etc/apache2/ssl/$TARGET_SSO_MIGO_SITE.key ] ; then
							local OPENSSL=(`which openssl`)
							$OPENSSL req -new -x509 -days 365 -nodes -out $TARGET_SSO_MIGO_SITE.pem -keyout $TARGET_SSO_MIGO_SITE.key
							sudo mv $TARGET_SSO_MIGO_SITE.pem /etc/apache2/ssl
							sudo mv $TARGET_SSO_MIGO_SITE.key /etc/apache2/ssl
						fi
		
						local vhconfig=$TARGET_SSO_MIGO_SITE.$ssourl
						if [ -f $TARGET_SITE_CONFIG/migo/$vhconfig ] ; then
							sudo cp $TARGET_SITE_CONFIG/migo/$vhconfig /etc/apache2/sites-available/$TARGET_SSO_MIGO_SITE
						else
							echo
							echo "** No virtual host configuration for 'Migo' on $TARGET_SSO_MIGO_WEBSERVER"
							return
						fi
		
						# Enable virtualhost at port 443 for ssl
						local keys
						keys=(`grep "^[[:space:]]NameVirtualHost \*:443" /etc/apache2/ports.conf`)
						if [ ! "$keys" ] ; then
						sudo sed -i -e "/^<IfModule mod_ssl.c>.*/a\\\tNameVirtualHost \*:443" /etc/apache2/ports.conf
						fi
					fi
					
					# Match host names with IP address
					keys=(`cat /etc/hosts | grep -i -e "^[0-9\.]*[[:space:]]*$TARGET_SSO_MIGO_SITE"`)
					if [ ! "$keys" ] ; then
					sudo bash -c "cat >>/etc/hosts <<EOF
$TARGET_SSO_IPADDR $TARGET_SSO_MIGO_SITE
EOF"
					fi
					
					# Make virtual host configuration to Apache take effect
					sudo a2ensite $TARGET_SSO_MIGO_SITE
					sudo a2dissite default
					sudo /etc/init.d/apache2 restart
					;;
				*)
					echo 
					echo "** HTTP not supported for 'Migo' yet."
					return
					;;
			esac
			;;
		*)
			echo
			echo "** Invalid webserver type for Migo: '$TARGET_SSO_MIGO_WEBSERVER'"
			return
			;;
	esac
}

# Preinstall packages required for MIGO
function ssoserver_migo_preinstall()
{
	if [ -z "$TARGET_SSO" ] ; then
		echo 
		echo "** TARGET_SSO not set yet. Check your site specs to fix it."
		return
	fi
	
	echo 
	echo "Preinstalling for site[$TARGET_SSO_MIGO_SITE]@IPaddr[$TARGET_SSO_IPADDR]..."
	
	if [ -n "$TARGET_SSO_MIGO_WEBSERVER" ] ; then
		webserver $TARGET_SSO_MIGO_WEBSERVER
	fi
	if [ -n "$TARGET_SSO_MIGO_DBENGINE" ] ; then
		dbengine $TARGET_SSO_MIGO_DBENGINE
	fi
}

# Clean all settings simply around MIGO
function ssoserver_migo_clean()
{
	if [ -z "$TARGET_SSO" ] ; then
		echo 
		echo "** TARGET_SSO not set yet. Check your site specs to fix it."
		return
	fi
	
	echo
	echo "Cleaning for site[$TARGET_SSO_MIGO_SITE]@ipadd[$TARGET_SSO_IPADDR]..."
	
#	case $TARGET_SSO_MIGO_DBENGINE in
#		postgresql | POSTGRESQL)
#			local MYSQL MYSQL_HEADER_COMPLEX MYSQL_HEADER_SIMPLE MYSQL_ROOTPW 
#			local dbname
#			MYSQL=(`which mysql`)
#			if [ -z $TARGET_CMS_MEDIAWIKI_MYSQL_DBNAME ] ; then
#				dbname=(`echo -n $TARGET_CMS_MEDIAWIKI_SITE | sed -e "s/\./_/g"`)
#				export TARGET_CMS_MEDIAWIKI_MYSQL_DBNAME=$dbname
#			else
#				dbname=$TARGET_CMS_MEDIAWIKI_MYSQL_DBNAME
#			fi
#			if [ -z "$TARGET_DBENGINE_MYSQL_ROOTPW" ] ; then
#				read -s -p "Enter password for MySQL: " MYSQL_ROOTPW
#				export TARGET_DBENGINE_MYSQL_ROOTPW=$MYSQL_ROOTPW
#			else
#				MYSQL_ROOTPW=$TARGET_DBENGINE_MYSQL_ROOTPW
#			fi
#			if [ -z "$TARGET_CMS_MEDIAWIKI_MYSQL_DBUSER" ] ; then
#				dbuser=wiki
#				export TARGET_CMS_MEDIAWIKI_MYSQL_DBUSER=$dbuser
#			else
#				dbuser=$TARGET_CMS_MEDIAWIKI_MYSQL_DBUSER
#			fi
#			MYSQL_HEADER_COMPLEX="$MYSQL -u root -p'$MYSQL_ROOTPW' --batch --skip-column-names -e"
#			MYSQL_HEADER_SIMPLE="$MYSQL -u root -p'$MYSQL_ROOTPW' -e"
#			if [ `$MYSQL_HEADER_COMPLEX "SHOW DATABASES LIKE '$dbname';"` ] ; then
#				$MYSQL_HEADER_SIMPLE "DROP DATABASE $dbname;"
#			fi
#			if [ `$MYSQL_HEADER_COMPLEX "SELECT USER FROM mysql.user WHERE user='$dbuser';"` ] ; then
#				$MYSQL_HEADER_SIMPLE "DROP USER $dbuser;"
#			fi
#			;;
#		*)
#			echo
#			echo "** Invalid dbengine type for Migo: '$TARGET_SSO_MIGO_DBENGINE'"
#			return
#			;;
#	esac
			
	case $TARGET_SSO_MIGO_WEBSERVER in
		apache2)
			if [ -f /etc/apache2/sites-available/$TARGET_SSO_MIGO_SITE ] ; then
				sudo rm /etc/apache2/sites-available/$TARGET_SSO_MIGO_SITE
			fi
			if [ -L /etc/apache2/sites-enabled/$TARGET_SSO_MIGO_SITE ] ; then
				sudo rm /etc/apache2/sites-enabled/$TARGET_SSO_MIGO_SITE
			fi
			;;
		*)
			echo
			echo "** Invalid webserver type for Migo: '$TARGET_SSO_MIGO_WEBSERVER'"
			return
			;;
	esac
	
	if [ -d /home/www-data/$TARGET_SSO_MIGO_SITE ] ; then
		sudo rm -rf /home/www-data/$TARGET_SSO_MIGO_SITE
	fi
}

# Setup SSO MIGO
function ssoserver_migo()
{
	if [ -z "$TARGET_SSO" ] ; then
		echo 
		echo "** TARGET_SSO not set yet. Check your site specs to fix it."
		return
	fi
	
	local goal
	for goal in ${TARGET_SITE_GOALS[@]}
	do
		case $goal in
			clean)
				ssoserver_migo_clean
				;;
			preinstall)
				ssoserver_migo_preinstall
				;;
			configure)
				ssoserver_migo_configure
				;;
			install)
				ssoserver_migo_install
				;;
			postconfig)
				ssoserver_migo_postconfig
				;;
			custom)
				ssoserver_migo_custom
				;;
			backup)
				ssoserver_migo_backup
				;;
			upgrade)
				ssoserver_migo_upgrade
				;;
			lite)
				ssoserver_migo_clean
				ssoserver_migo_preinstall
				ssoserver_migo_configure
				ssoserver_migo_install
				;;
			all)
				ssoserver_migo_clean
				ssoserver_migo_preinstall
				ssoserver_migo_configure
				ssoserver_migo_install
				ssoserver_migo_postconfig
				ssoserver_migo_custom
				;;
			*)
				echo
				echo "** Invalid TARGET SITE GOALS: '$goal'"
				return
				;;
		esac
	done
}

# Setup SSO Server
function ssoserver()
{
	# Note that TARGET_SSO has support only for one type of product for now, which
	# covers MIGO
	local sso
	for sso in ${TARGET_SSO[@]}
	do
		if [ $sso = "migo" ] ; then
			ssoserver_migo
		else
			echo 
			echo "** Invalid SSO: '$sso'"
			echo "** Must be one of '${SSO_CHOICES[@]}'"
			return
		fi
	done
}

# Upgrade LMS Sentry
function lmsserver_sentry_upgrade()
{
	if [ -z "$TARGET_LMS" ] ; then
		echo 
		echo "** TARGET_LMS not set yet. Check your site specs to fix it."
		return
	fi
}

# Backup LMS Sentry
function lmsserver_sentry_backup()
{
	if [ -z "$TARGET_LMS" ] ; then
		echo 
		echo "** TARGET_LMS not set yet. Check your site specs to fix it."
		return
	fi
}

# Customize LMS Sentry
function lmsserver_sentry_custom()
{
	if [ -z "$TARGET_LMS" ] ; then
		echo 
		echo "** TARGET_LMS not set yet. Check your site specs to fix it."
		return
	fi
}

# Postconfig LMS Sentry
function lmsserver_sentry_postconfig()
{
	if [ -z "$TARGET_LMS" ] ; then
		echo 
		echo "** TARGET_LMS not set yet. Check your site specs to fix it."
		return
	fi
}

# Install LMS Sentry
function lmsserver_sentry_install() 
{
	if [ -z "$TARGET_LMS" ] ; then
		echo 
		echo "** TARGET_LMS not set yet. Check your site specs to fix it."
		return
	fi
	
	
	sudo -u sentry virtualenv /home/sentry/
	local bin_path=/home/sentry/bin
	local keys=(`grep -i '$bin_path' /home/gerrit/.bashrc 2>/dev/null`)
	if [ ! "$keys" ] ; then
		sudo -H -u sentry bash -c "echo 'PATH=$bin_path:$PATH' >>/home/sentry/.bashrc"
	fi
	sudo -H -u sentry bash -c ". /home/sentry/bin/activate && pip install sentry"
	sudo -H -u sentry bash -c ". /home/sentry/bin/activate && pip install psycopg2"
	sudo -H -u sentry bash -c ". /home/sentry/bin/activate && sentry init /home/sentry/etc/sentry.conf.py"
	sudo -H -u sentry bash -c ". /home/sentry/bin/activate && sentry --config=/home/sentry/etc/sentry.conf.py start"
}

# Configure LMS Sentry
function lmsserver_sentry_configure()
{
	if [ -z "$TARGET_LMS" ] ; then
		echo 
		echo "** TARGET_LMS not set yet. Check your site specs to fix it."
		return
	fi
	
	echo 
	echo "Configuring site[$TARGET_LMS_SENTRY_SITE]@IPaddr[$TARGET_LMS_IPADDR]..."
	
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
		postgresql | POSTGRESQL)
			# Create a new database via postgresql for Sentry use which is named 
			# by means of this variable, TARGET_LMS_SENTRY_SITE. Let's say,
			# this name of the database would be logs_mci_org if this 
			# value of the variable is logs.mci.org.
			local PGSQL_HEADER PGSQL_ROOTPW 
			local PSQL PGSQL_CREATEUSER PGSQL_CREATEDB
			local dbhost dbname dbuser dbpw ret
			
			if [ -z $TARGET_LMS_SENTRY_PGSQL_DBNAME ] ; then
				dbname=(`echo -n $TARGET_LMS_SENTRY_SITE | sed -e "s/\./_/g"`)
				TARGET_LMS_SENTRY_PGSQL_DBNAME=$dbname
			else
				dbname=$TARGET_LMS_SENTRY_PGSQL_DBNAME
			fi
			
			echo 
			echo "Creating database[$dbname] in '$TARGET_LMS_SENTRY_DBENGINE' for Sentry..."
			
			PSQL=(`which psql`) 
			PGSQL_CREATEUSER=(`which createuser`)
			PGSQL_CREATEDB=(`which createdb`)
			if [ -z "$TARGET_DBENGINE_PGSQL_ROOTPW" ] ; then
				read -s -p "Enter password for PGSQL: " PGSQL_ROOTPW
				TARGET_DBENGINE_PGSQL_ROOTPW=$PGSQL_ROOTPW
			else
				PGSQL_ROOTPW=$TARGET_DBENGINE_PGSQL_ROOTPW
			fi
			PGSQL_HEADER="sudo -u postgres"
			ret=(`$PGSQL_HEADER $PSQL -d $dbname -c "\q" 2>/dev/null`)
			if [ $? -ne 0 ] ; then
				if [ -z "$TARGET_LMS_SENTRY_PGSQL_DBPW" ] ; then
					read -s -p "Enter password for Sentry database: " dbpw
				else
					dbpw=$TARGET_LMS_SENTRY_PGSQL_DBPW
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
				$PGSQL_HEADER $PSQL -c "CREATE USER $dbuser NOSUPERUSER NOCREATEROLE NOCREATEDB ENCRYPTED PASSWORD '$dbpw'"
				$PGSQL_HEADER $PGSQL_CREATEDB -E UTF8 --owner=$dbuser $dbname
			fi
			;;
		*)
			echo
			echo "** Invalid dbengine type for Sentry: '$TARGET_LMS_SENTRY_DBENGINE'"
			return
			;;
	esac
	
	case $TARGET_LMS_SENTRY_WEBSERVER in
		apache2)
			case $TARGET_LMS_URL in
				https | HTTPS)
					sudo a2enmod ssl proxy proxy_http rewrite
					# Configure virtual host as well as port for Sentry 
					# on Apache server
					if [ ! -f /etc/apache2/sites-available/$TARGET_LMS_SENTRY_SITE ] ; then
						# Generate a self-signed certificate for SSL
						if [ ! -d /etc/apache2/ssl ] ; then
							sudo mkdir /etc/apache2/ssl
						fi
						if [ ! -f /etc/apache2/ssl/$TARGET_LMS_SENTRY_SITE.pem -o ! -f /etc/apache2/ssl/$TARGET_LMS_SENTRY_SITE.key ] ; then
							local OPENSSL=(`which openssl`)
							$OPENSSL req -new -x509 -days 365 -nodes -out $TARGET_LMS_SENTRY_SITE.pem -keyout $TARGET_LMS_SENTRY_SITE.key
							sudo mv $TARGET_LMS_SENTRY_SITE.pem /etc/apache2/ssl
							sudo mv $TARGET_LMS_SENTRY_SITE.key /etc/apache2/ssl
						fi
						
						local vhconfig
						vhconfig=$TARGET_LMS_SENTRY_SITE.$TARGET_LMS_URL
						if [ -f $TARGET_SITE_CONFIG/sentry/$vhconfig ] ; then
							sudo cp $TARGET_SITE_CONFIG/sentry/$vhconfig /etc/apache2/sites-available/$TARGET_LMS_SENTRY_SITE
						else
							echo
							echo "** No virtual host configuration for 'Sentry' on $TARGET_LMS_SENTRY_WEBSERVER"
							return
						fi 
		
						# Enable virtualhost at port 443 for ssl
						local keys
						keys=(`grep "^[[:space:]]NameVirtualHost \*:443" /etc/apache2/ports.conf 2>/dev/null`)
						if [ ! "$keys" ] ; then
							sudo sed -i -e "/^<IfModule mod_ssl.c>.*/a\\\tNameVirtualHost \*:443" /etc/apache2/ports.conf
						fi
					fi
					
					# Match host names with IP address
					keys=(`cat /etc/hosts | grep -i -e "^[0-9\.]*[[:space:]]*$TARGET_LMS_SENTRY_SITE"`)
					if [ ! "$keys" ] ; then
					sudo bash -c "cat >>/etc/hosts <<EOF
$TARGET_LMS_IPADDR $TARGET_LMS_SENTRY_SITE
EOF"
					fi
					
					# Make virtual host configuration to Apache take effect
					sudo a2ensite $TARGET_LMS_SENTRY_SITE
					sudo a2dissite default
					sudo /etc/init.d/apache2 restart
					;;
				*)
					echo 
					echo "** HTTP not supported for 'Sentry' yet."
					return
					;;
			esac
			;;
		*)
			echo
			echo "** Invalid webserver type for Sentry: '$TARGET_LMS_SENTRY_WEBSERVER'"
			return
			;;
	esac
}

# Preinstall packages required for Sentry
function lmsserver_sentry_preinstall()
{
	if [ -z "$TARGET_LMS" ] ; then
		echo 
		echo "** TARGET_LMS not set yet. Check your site specs to fix it."
		return
	fi
	
	echo 
	echo "Preinstalling for site[$TARGET_LMS_SENTRY_SITE]@IPaddr[$TARGET_LMS_IPADDR]..."
	
	if [ -n "$TARGET_LMS_SENTRY_WEBSERVER" ] ; then
		webserver $TARGET_LMS_SENTRY_WEBSERVER
	fi
	if [ -n "$TARGET_LMS_SENTRY_DBENGINE" ] ; then
		dbengine $TARGET_LMS_SENTRY_DBENGINE
	fi
	if [ "$TARGET_LMS_URL" = "https" -o "$TARGET_LMS_URL" = "HTTPS" ] ; then
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

# Clean all settings simply around Sentry
function lmsserver_sentry_clean()
{
	if [ -z "$TARGET_LMS" ] ; then
		echo 
		echo "** TARGET_LMS not set yet. Check your site specs to fix it."
		return
	fi
	
	echo
	echo "Cleaning for site[$TARGET_LMS_SENTRY_SITE]@ipadd[$TARGET_LMS_IPADDR]..."
	
	local keys
	keys=(`ps -ef | grep -i "^sentry" 2>/dev/null`)
	if [ "$keys" ] ; then
		sudo /etc/init.d/sentry stop
	fi
	if [ -L /etc/init.d/sentry ] ; then
		sudo rm /etc/init.d/sentry
		
		if [ -f /etc/default/sentry ] ; then
			sudo rm /etc/default/sentry
		fi
	fi
	
	case $TARGET_LMS_SENTRY_DBENGINE in
		postgresql | POSTGRESQL)
			local PSQL PGSQL_HEADER PGSQL_ROOTPW 
			local dbhost dbname dbuser ret
			PSQL=(`which psql`)
			if [ -z $TARGET_LMS_SENTRY_PGSQL_DBNAME ] ; then
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
			echo "** Invalid dbengine type for Sentry: '$TARGET_LMS_SENTRY_DBENGINE'"
			return
			;;
	esac
			
	case $TARGET_LMS_SENTRY_WEBSERVER in
		apache2)
			if [ -f /etc/apache2/sites-available/$TARGET_LMS_SENTRY_SITE ] ; then
				sudo rm /etc/apache2/sites-available/$TARGET_LMS_SENTRY_SITE
			fi
			if [ -L /etc/apache2/sites-enabled/$TARGET_LMS_SENTRY_SITE ] ; then
				sudo rm /etc/apache2/sites-enabled/$TARGET_LMS_SENTRY_SITE
			fi
			;;
		*)
			echo
			echo "** Invalid webserver type for Sentry: '$TARGET_LMS_SENTRY_WEBSERVER'"
			return
			;;
	esac
	
#	if [ `id -u sentry 2>/dev/null` ] ; then
#		sudo deluser sentry
#	fi
#	if [ -d /home/sentry ] ; then
#		sudo rm -rf /home/sentry
#	fi
}

# Setup LMS Sentry
function lmsserver_sentry()
{
	if [ -z "$TARGET_LMS" ] ; then
		echo 
		echo "** TARGET_LMS not set yet. Check your site specs to fix it."
		return
	fi
	
	local goal
	for goal in ${TARGET_SITE_GOALS[@]}
	do
		case $goal in
			clean)
				lmsserver_sentry_clean
				;;
			preinstall)
				lmsserver_sentry_preinstall
				;;
			configure)
				lmsserver_sentry_configure
				;;
			install)
				lmsserver_sentry_install
				;;
			postconfig)
				lmsserver_sentry_postconfig
				;;
			custom)
				lmsserver_sentry_custom
				;;
			backup)
				lmsserver_sentry_backup
				;;
			upgrade)
				lmsserver_sentry_upgrade
				;;
			lite)
				lmsserver_sentry_clean
				lmsserver_sentry_preinstall
				lmsserver_sentry_configure
				lmsserver_sentry_install
				;;
			all)
				lmsserver_sentry_clean
				lmsserver_sentry_preinstall
				lmsserver_sentry_configure
				lmsserver_sentry_install
				lmsserver_sentry_postconfig
				lmsserver_sentry_custom
				;;
			*)
				echo
				echo "** Invalid TARGET SITE GOALS: '$goal'"
				return
				;;
		esac
	done
}

# Setup LMS Server
function lmsserver()
{
	# Note that TARGET_LMS has support only for one type of product for now, which
	# covers Sentry
	local lms
	for lms in ${TARGET_LMS[@]}
	do
		if [ $lms = "sentry" ] ; then
			lmsserver_sentry
		else
			echo 
			echo "** Invalid LMS: '$lms'"
			echo "** Must be one of '${LMS_CHOICES[@]}'"
			return
		fi
	done
}

# Setup Mail Server
function mailserver()
{
	echo
	echo "mailserver"
	echo
	
	# Postfix for SMTP
	sudo apt-get -y install postfix
	
	# Dovecot for IMAP/POP3
}

function webserver_apache2_install()
{
	if [ -z "$TARGET_WEBSERVER_APACHE2_OWNER" ] ; then
		echo 
		echo "** TARGET_WEBSERVER_APACHE2_OWNER not set yet. Check your site specs to fix it."
		return
	fi
	
	# Install apache2 if not installed yet
	if [ ! `which apache2` ] ; then
		sudo apt-get -y install apache2
	fi
	
	# Get rid of this warning when restarting apache server,
	# which is "apache2: Could not reliably determine the server's 
	# fully qualified domain name".
	local keys
	local ipaddr=127.0.0.1
	keys=(`cat /etc/apache2/httpd.conf | grep -i -e "^ServerName[[:space:]]*[0-9\.]*"`)
	if [ ! "$keys" ] ; then
		sudo bash -c "cat >>/etc/apache2/httpd.conf <<EOF
ServerName $ipaddr
EOF"
	fi

	# Configure apache2 server
	if [ ! `id -u $TARGET_WEBSERVER_APACHE2_OWNER 2>/dev/null` ] ; then
		if [ ! -d $TARGET_WEBSERVER_APACHE2_OWNER_HOME ] ; then
			sudo mkdir $TARGET_WEBSERVER_APACHE2_OWNER_HOME
		fi
		sudo chown $TARGET_WEBSERVER_APACHE2_OWNER:$TARGET_WEBSERVER_APACHE2_OWNER $TARGET_WEBSERVER_APACHE2_OWNER_HOME
		sudo usermod -d $TARGET_WEBSERVER_APACHE2_OWNER_HOME $TARGET_WEBSERVER_APACHE2_OWNER
		sudo usermod -s $TARGET_WEBSERVER_APACHE2_OWNER_SHELL $TARGET_WEBSERVER_APACHE2_OWNER
	fi
}

# Setup Web Server
function webserver()
{
	case $1 in
		apache2)
			webserver_apache2_install
			;;
		*)
			echo
			echo "** Invalid webserver type: '$1'"
			return
			;;
	esac
}

function dbengine_postgresql_install()
{
	if [ "$TARGET_SSO" = "migo" -o "$TARGET_LMS" = "sentry" ] ; then
		# For the time being, there are only two types of versions of Postgresql
		# officially supported against Ubuntu distros, namely precise (12.04) and
		# lucid (10.04), according to http://www.postgresql.org/download/linux/ubuntu/.
		#
		# To install Postgresql against the Ubuntu distro you're running, we follow
		# such thumb rules below, which are that if your current version of Ubuntu
		# distro is greater or equal than 12.04 (precise), and then the source list
		# will be chosen to make use of the one against precise (12.04); if the 
		# current one greater or equal than 10.04 (lucid) but less than 12.04 (precise), 
		# and then the source list against lucid (10.04).
		#
		# And make sure that your Ubuntu distro is lucid (10.04) or later to keep 
		# Postgresql up-to-date.
		local PSQL=(`which psql`)
		local PSQL_VERSION=(`$PSQL --version 2>/dev/null | sed -n "s/[^0-9]*\([0-9]*\.[0-9]*\)[0-9\.].*/\1/p"`)
		if [[ ! "$PSQL" || "$PSQL_VERSION" != "$TARGET_SSO_MIGO_POSTGRESQL_VERSION_REQUIRED" ]] ; then
			local LSBR=(`which lsb_release`)
			local current_codename=(`$LSBR -sc`)
			if [ ! `ls /etc/apt/sources.list.d/$current_codename-pgdg.list 2>/dev/null` ] ; then
				local current_version=(`$LSBR -sr`)
				local lucid_codename=lucid
				local precise_codename=precise
				local lucid_version=10.04
				local precise_version=12.04
		
				# Try removing the source list different from current codename 
				# first if present when upgrading or downgrading to guarantee that
				# only a source list is out there which matches with current codename.
				if [ `ls /etc/apt/sources.list.d/$lucid_codename-pgdg.list 2>/dev/null` ] ; then
					sudo rm /etc/apt/sources.list.d/$lucid_codename-pgdg.list
				fi
				if [ `ls /etc/apt/sources.list.d/$precise_codename-pgdg.list 2>/dev/null` ] ; then
					sudo rm /etc/apt/sources.list.d/$precise_codename-pgdg.list
				fi
				if (( $(echo "$current_version >= $precise_version" | bc -l) )) ; then
					sudo bash -c "cat >/etc/apt/sources.list.d/$precise_codename-pgdg.list <<EOF
		deb http://apt.postgresql.org/pub/repos/apt/ $precise_codename-pgdg main
		EOF"
				elif (( $(echo "$current_version >= $lucid_version" | bc -l) )) ; then
					sudo bash -c "cat >/etc/apt/sources.list.d/$lucid_codename-pgdg.list <<EOF
		deb http://apt.postgresql.org/pub/repos/apt/ $lucid_codename-pgdg main
		EOF"
				fi
				wget --quiet -O - http://apt.postgresql.org/pub/repos/apt/ACCC4CF8.asc | sudo apt-key add -
				sudo apt-get update
			fi
	
			sudo apt-get -y install postgresql-$TARGET_SSO_MIGO_POSTGRESQL_VERSION_REQUIRED
			sudo apt-get -y install postgresql-plpython-$TARGET_SSO_MIGO_POSTGRESQL_VERSION_REQUIRED
			sudo apt-get -y install postgresql-doc-$TARGET_SSO_MIGO_POSTGRESQL_VERSION_REQUIRED
			sudo apt-get -y install pgadmin3 libpq-dev
		fi
	fi
}

function dbengine_mysql_install()
{
	# Install MySQL if not installed yet
	if [ ! `which mysql` ] ; then
		sudo apt-get -y install mysql-server
	fi
}

# Setup DB Engine
function dbengine()
{
	case $1 in
		mysql | MYSQL)
			dbengine_mysql_install
			;;
		postgresql | POSTGRESQL)
			dbengine_postgresql_install
			;;
		*)
			echo
			echo "** Invalid dbengine type: '$1'"
			return
			;;
	esac
}

# Setup Apps Server
function appsserver()
{
	if [ "$TARGET_LMS" ] ; then
		lmsserver
	fi
	if [ "$TARGET_SSO" ] ; then
		ssoserver
	fi
	if [ "$TARGET_CMS" ] ; then
		cmsserver
	fi
	if [ "$TARGET_ITS" ] ; then
		itsserver
	fi
	if [ "$TARGET_SCMR" ] ; then
		scmrserver
	fi
	if [ "$TARGET_CI" ] ; then
		ciserver
	fi
}

# Display the target site setting
function showconfig()
{
	echo
	echo "=========================="
	echo "TARGET_SITE=$TARGET_SITE"
	echo "TARGET_LMS=${TARGET_LMS[@]}"
	echo "TARGET_SSO=${TARGET_SSO[@]}"
	echo "TARGET_CMS=${TARGET_CMS[@]}"
	echo "TARGET_ITS=${TARGET_ITS[@]}"
	echo "TARGET_SCMR=${TARGET_SCMR[@]}"
	echo "TARGET_CI=${TARGET_CI[@]}"
	echo "=========================="
	echo
}

# Obtain the complete target site specs
function configure()
{
	local toppath
	toppath=$(get_mcitop)
    if [ ! "$toppath" ]; then
        echo "Couldn't locate the top of the tree.  Try setting MCITOP." >&2
        return
    fi
    
	if [ -z "$TARGET_SITE" -o -z "$TARGET_SITE_COMPONENTS" -o -z "$TARGET_SITE_GOALS" ] ; then
		echo
		echo "** Invalid site setting. Then, use 'turnkey' configuring target site."
		return
	fi
	
	local specs	
	if [ "$TARGET_SITE" = "full" -o "$TARGET_SITE" = "mci.org" ] ; then
		specs=(`ls build/*/full.sh`)
	else
		specs=(`ls sites/*/*/$TARGET_SITE.sh`)
	fi
	include_specs $specs
	copy_specs TARGET MCI
	round_specs
	clean_specs MCI
}

# Deploy target sites
function launch()
{
	###################################################################
	# MCI, short for Miing Core Infrastructure, is split into three   #
	# layers which are web, applications, and dbengine from top to    #
	# bottom. And every layer covers one component or two.            #
	# Web layer is responsible for serving up all kinds of web        #
	# contents from lower layers that fit your needs, including web   #
	# server.                                                         #
	# Applications layer offers variety of services used by the upper,#
	# containing SSO, CMS, ITS, SCMR, CI, etc.                        #
	# Database layer stores and manages all sorts of data from the    #
	# upper, consisting of database engine.                           #
	################################################################### 
	
	# Get the complete specs for the target site.
	configure
	
	# Print the target site setting
	showconfig
	
	# Launch apps server so as to provide services for the upper via
	# web server.
	appsserver
}

# Export MCITOP into the current shell environment
mci_top=(`/bin/pwd`)
if [ -f $mci_top/build/mci.sh ] ; then
	export MCITOP=$mci_top
fi
unset mci_top

# Execute the contents of any vendorsetup.sh file we can find.
for f in `/bin/ls $MCITOP/sites/*/*/vendorsetup.sh 2> /dev/null`
do
    echo "including $f"
    . $f
done
unset f
