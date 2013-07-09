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


# Source all kinds of ITS services available
. build/core/bugzilla.sh

# Setup ITS services
its()
{
	# Note that TARGET_ITS has support only for one kind of ITS for now, 
	# which includes Bugzilla.
	local its
	for its in ${TARGET_ITS[@]}
	do
		if [ $its = "bugzilla" ] ; then
			its_bugzilla
		else
			echo 
			echo "ITS::Error::Invalid ITS: '$its'. Must be one of '${ITS_CHOICES[@]}'"
			return
		fi
	done
}
