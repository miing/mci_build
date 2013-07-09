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


# Source all kinds of CI services available
. build/core/jenkins.sh

# Setup CI services
ci()
{
	# Note that TARGET_CI has support only for one type of CI for now, which
	# covers Jenkins.
	local ci
	for ci in ${TARGET_CI[@]}
	do
		if [ $ci = "jenkins" ] ; then
			ci_jenkins
		else
			echo 
			echo "CI::Error::Invalid CI: '$ci'. Must be one of '${CI_CHOICES[@]}'"
			return
		fi
	done
}
