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


httpd_apache()
{
	if [ -z "$TARGET_HTTPD_APACHE_OWNER" ] ; then
		echo 
		echo "HTTPD::APACHE::Error::TARGET_HTTPD_APACHE_OWNER not set yet"
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
	if [ ! `id -u $TARGET_HTTPD_APACHE_OWNER 2>/dev/null` ] ; then
		if [ ! -d $TARGET_HTTPD_APACHE_OWNER_HOME ] ; then
			sudo mkdir $TARGET_HTTPD_APACHE_OWNER_HOME
		fi
		sudo chown $TARGET_HTTPD_APACHE_OWNER:$TARGET_HTTPD_APACHE_OWNER $TARGET_HTTPD_APACHE_OWNER_HOME
		sudo usermod -d $TARGET_HTTPD_APACHE_OWNER_HOME $TARGET_HTTPD_APACHE_OWNER
		sudo usermod -s $TARGET_HTTPD_APACHE_OWNER_SHELL $TARGET_HTTPD_APACHE_OWNER
	fi
}
