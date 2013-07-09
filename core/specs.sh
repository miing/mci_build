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
	DBENGINE_MYSQL_HOST \
	DBENGINE_MYSQL_PORT \
	DBENGINE_MYSQL_ROOTPW \
	DBENGINE_PGSQL_HOST \
	DBENGINE_PGSQL_PORT \
	DBENGINE_PGSQL_ROOTPW \
	HTTPD_APACHE_OWNER \
	HTTPD_APACHE_OWNER_HOME \
	HTTPD_APACHE_OWNER_SHELL \
	LMS \
	LMS_SENTRY_SITE \
	LMS_SENTRY_HTTPD \
	LMS_SENTRY_HTTPD_SCHEME \
	LMS_SENTRY_HTTPD_IPADDR \
	LMS_SENTRY_HTTPD_PORT \
	LMS_SENTRY_DBENGINE \
	LMS_SENTRY_DBENGINE_VERSION_REQUIRED \
	LMS_SENTRY_DBENGINE_DBNAME \
	LMS_SENTRY_DBENGINE_DBUSER \
	LMS_SENTRY_DBENGINE_DBPW \
	SSO \
	SSO_MIGO_SITE \
	SSO_MIGO_HTTPD \
	SSO_MIGO_HTTPD_SCHEME \
	SSO_MIGO_HTTPD_IPADDR \
	SSO_MIGO_HTTPD_PORT \
	SSO_MIGO_DBENGINE \
	SSO_MIGO_DBENGINE_VERSION_REQUIRED \
	SSO_MIGO_DBENGINE_DBNAME \
	SSO_MIGO_DBENGINE_DBUSER \
	SSO_MIGO_DBENGINE_DBPW \
	CMS \
	CMS_DRUPAL_SITE \
	CMS_DRUPAL_HTTPD \
	CMS_DRUPAL_HTTPD_SCHEME \
	CMS_DRUPAL_HTTPD_IPADDR \
	CMS_DRUPAL_HTTPD_PORT \
	CMS_DRUPAL_DBENGINE \
	CMS_DRUPAL_DBENGINE_DBNAME \
	CMS_DRUPAL_DBENGINE_DBUSER \
	CMS_DRUPAL_DBENGINE_DBPW \
	CMS_DRUPAL_VERSION_INSTALLED \
	CMS_DRUPAL_VERSION_UPDATED \
	CMS_DRUPAL_SITE_AUTH \
	CMS_CUSTOM_SITE \
	CMS_CUSTOM_HTTPD \
	CMS_CUSTOM_HTTPD_SCHEME \
	CMS_CUSTOM_HTTPD_IPADDR \
	CMS_CUSTOM_HTTPD_PORT \
	CMS_CUSTOM_DBENGINE \
	CMS_CUSTOM_DBENGINE_DBNAME \
	CMS_CUSTOM_DBENGINE_DBUSER \
	CMS_CUSTOM_DBENGINE_DBPW \
	CMS_MEDIAWIKI_SITE \
	CMS_MEDIAWIKI_HTTPD \
	CMS_MEDIAWIKI_HTTPD_SCHEME \
	CMS_MEDIAWIKI_HTTPD_IPADDR \
	CMS_MEDIAWIKI_HTTPD_PORT \
	CMS_MEDIAWIKI_DBENGINE \
	CMS_MEDIAWIKI_DBENGINE_DBNAME \
	CMS_MEDIAWIKI_DBENGINE_DBUSER \
	CMS_MEDIAWIKI_DBENGINE_DBPW \
	CMS_MEDIAWIKI_VERSION_INSTALLED \
	CMS_MEDIAWIKI_VERSION_UPDATED \
	CMS_MEDIAWIKI_SITE_AUTH \
	CMS_MEDIAWIKI_SITE_NAME \
	CMS_MEDIAWIKI_SITE_ADMIN \
	CMS_MEDIAWIKI_SITE_ADMIN_PASSWORD \
	CMS_MEDIAWIKI_SITE_LOGO \
	CMS_MEDIAWIKI_SITE_FAVICON \
	ITS \
	ITS_BUGZILLA_SITE \
	ITS_BUGZILLA_HTTPD \
	ITS_BUGZILLA_HTTPD_SCHEME \
	ITS_BUGZILLA_HTTPD_IPADDR \
	ITS_BUGZILLA_HTTPD_PORT \
	ITS_BUGZILLA_DBENGINE \
	ITS_BUGZILLA_DBENGINE_DBNAME \
	ITS_BUGZILLA_DBENGINE_DBUSER \
	ITS_BUGZILLA_DBENGINE_DBPW \
	ITS_BUGZILLA_VERSION_INSTALLED \
	ITS_BUGZILLA_VERSION_UPDATED \
	ITS_BUGZILLA_SITE_AUTH \
	ITS_BUGZILLA_SITE_ADMIN_EMAIL \
	ITS_BUGZILLA_SITE_ADMIN_PASSWORD \
	ITS_BUGZILLA_SITE_ADMIN_REALNAME \
	ITS_BUGZILLA_SITE_SMTP_SERVER \
	ITS_BUGZILLA_SITE_NO_PAUSE \
	SCMR \
	SCMR_GERRIT_SITE \
	SCMR_GERRIT_HTTPD \
	SCMR_GERRIT_HTTPD_SCHEME \
	SCMR_GERRIT_HTTPD_IPADDR \
	SCMR_GERRIT_HTTPD_PORT \
	SCMR_GERRIT_DBENGINE \
	SCMR_GERRIT_DBENGINE_DBNAME \
	SCMR_GERRIT_DBENGINE_DBUSER \
	SCMR_GERRIT_DBENGINE_DBPW \
	SCMR_GERRIT_VERSION_INSTALLED \
	SCMR_GERRIT_VERSION_UPDATED \
	SCMR_GERRIT_SITE_AUTH \
	SCMR_GERRIT_SITE_OPENIDSSO_URL \
	SCMR_GERRIT_SITE_HTTPBASIC_ADMIN \
	SCMR_GERRIT_SITE_WEBFRONT \
	SCMR_GERRIT_SSHGIT_CONFIG \
	SCMR_GERRIT_SSHGIT_USER \
	SCMR_GERRIT_SSHGIT_EMAIL \
	SCMR_GERRIT_SSHGIT_EDITOR \
	SCMR_GERRIT_SITE_THEME \
	SCMR_GITOLITE_SITE \
	SCMR_GITOLITE_HTTPD \
	SCMR_GITOLITE_HTTPD_SCHEME \
	SCMR_GITOLITE_HTTPD_IPADDR \
	SCMR_GITOLITE_HTTPD_PORT \
	SCMR_GITOLITE_DBENGINE \
	SCMR_GITOLITE_DBENGINE_DBNAME \
	SCMR_GITOLITE_DBENGINE_DBUSER \
	SCMR_GITOLITE_DBENGINE_DBPW \
	CI \
	CI_JENKINS_SITE \
	CI_JENKINS_HTTPD \
	CI_JENKINS_HTTPD_SCHEME \
	CI_JENKINS_HTTPD_IPADDR \
	CI_JENKINS_HTTPD_PORT \
	CI_JENKINS_DBENGINE \
	CI_JENKINS_DBENGINE_DBNAME \
	CI_JENKINS_DBENGINE_DBUSER \
	CI_JENKINS_DBENGINE_DBPW \
	CI_JENKINS_SITE_AUTH \
	CI_JENKINS_SITE_ADMIN_USER \
	CI_JENKINS_SITE_ADMIN_PASSWORD)

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
	# First backup all values of all target applications, and
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
	
	# Clear up all backup variables if any service is provided via turnkey.
	local srv
	for srv in ${TARGET_SITE_SERVICES[@]}
	do
		if [ "$srv" = "sentry" ] ; then
			BACKUP_LMS=
		elif [ "$srv" = "migo" ] ; then
			BACKUP_SSO=
		elif [ "$srv" = "drupal" -o "$srv" = "cmscustom" -o "$srv" = "mediawiki" ] ; then
			BACKUP_CMS=
		elif [ "$srv" = "bugzilla" ] ; then
			BACKUP_ITS=
		elif [ "$srv" = "gerrit" -o "$srv" = "gitolite" ] ; then
			BACKUP_SCMR=
		elif [ "$srv" = "jenkins" ] ; then
			BACKUP_CI=
		fi
	done
	
	# Fill in these target service variabls according to turnkey, 
	# instead of from your site specs.
	for srv in ${TARGET_SITE_SERVICES[@]}
	do
		if [ "$srv" = "full" ] ; then
			TARGET_LMS=${BACKUP_LMS[@]}
			TARGET_SSO=${BACKUP_SSO[@]}
			TARGET_CMS=${BACKUP_CMS[@]}
			TARGET_SCMR=${BACKUP_SCMR[@]}
			TARGET_CI=${BACKUP_CI[@]}
			TARGET_ITS=${BACKUP_ITS[@]}
		elif [ "$srv" = "sentry" ] ; then
			TARGET_LMS=(${TARGET_LMS[@]} $srv)
		elif [ "$srv" = "migo" ] ; then
			TARGET_SSO=(${TARGET_SSO[@]} $srv)
		elif [ "$srv" = "drupal" -o "$srv" = "cmscustom" -o "$srv" = "mediawiki" ] ; then
			TARGET_CMS=(${TARGET_CMS[@]} $srv)
		elif [ "$srv" = "bugzilla" ] ; then
			TARGET_ITS=(${TARGET_ITS[@]} $srv)
		elif [ "$srv" = "gerrit" -o "$srv" = "gitolite" ] ; then
			TARGET_SCMR=(${TARGET_SCMR[@]} $srv)
		elif [ "$srv" = "jenkins" ] ; then
			TARGET_CI=(${TARGET_CI[@]} $srv)
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
