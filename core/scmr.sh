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


# Source all kinds of SCMR services available
. build/core/gerrit.sh
. build/core/gitolite.sh

# Setup SCMR services
scmr()
{
	# Note that TARGET_SCMR has support only for two kinds of SCMR for now, 
	# which includes Gerrit, and Gitolite
	local scmr
	for scmr in ${TARGET_SCMR[@]}
	do
		if [ $scmr = "gerrit" ] ; then
			scmr_gerrit
		elif [ $scmr = "gitolite" ] ; then
			scmr_gitolite
		else
			echo 
			echo "SCMR::Error::Invalid SCMR: '$scmr'. Must be one of '${SCMR_CHOICES[@]}'"
			return
		fi
	done
}
