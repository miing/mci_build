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


# Source all kinds of database servers available
. build/core/mysql.sh
. build/core/postgresql.sh

# Setup Database Engine
dbengine()
{
	case $1 in
		mysql)
			dbengine_mysql
			;;
		postgresql)
			dbengine_postgresql
			;;
		*)
			echo
			echo "DBENGINE::ERROR::Invalid dbengine type: '$1'"
			return
			;;
	esac
}
