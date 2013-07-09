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


# Source all kinds of CMS services available
. build/core/drupal.sh
. build/core/cms_custom.sh
. build/core/mediawiki.sh

# Setup CMS services
cms()
{
	# Note that TARGET_CMS has support only for three forms of CMS, 
	# which covers drupal, mediawiki, custom
	local cms
	for cms in ${TARGET_CMS[@]}
	do
		if [ $cms = "drupal" ] ; then
			cms_drupal
		elif [ $cms = "cmscustom" ] ; then
			cms_custom
		elif [ $cms = "mediawiki" ] ; then
			cms_mediawiki
		else
			echo 
			echo "CMS::Error::Invalid CMS: '$cms'. Must be one of '${CMS_CHOICES[@]}'"
			return
		fi
	done
}
