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


dbengine_postgresql()
{
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
}
