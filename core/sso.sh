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


# Source all kinds of SSO services available
. build/core/migo.sh

# Setup SSO services
sso()
{
	# Note that TARGET_SSO has support only for one type of SSO for now, which
	# covers MIGO
	local sso
	for sso in ${TARGET_SSO[@]}
	do
		if [ $sso = "migo" ] ; then
			sso_migo
		else
			echo 
			echo "SSO::Error::Invalid SSO: '$sso'. Must be one of '${SSO_CHOICES[@]}'"
			return
		fi
	done
}
