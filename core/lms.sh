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


# Source all kinds of LMS services available
. build/core/sentry.sh

# Setup LMS services
lms()
{
	# Note that TARGET_LMS has support only for one type of LMS for now, which
	# covers Sentry
	local lms
	for lms in ${TARGET_LMS[@]}
	do
		if [ $lms = "sentry" ] ; then
			lms_sentry
		else
			echo 
			echo "LMS::Error::Invalid LMS: '$lms'. Must be one of '${LMS_CHOICES[@]}'"
			return
		fi
	done
}
