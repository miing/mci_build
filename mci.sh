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


# Print help message
hmci() 
{
cat <<EOF
Invoke ". build/mci.sh" from your shell to add the following functions to your environment:
- hmci: 	Print help message
- turnkey: 	Choose target site(s)
- launch: 	Deploy target site(s)
EOF
}

# Get the top path for the whole project
get_mcitop() 
{
	local topfile=build/mci.sh
    if [ -n "$MCITOP" -a -f "$MCITOP/$topfile" ] ; then
        echo $MCITOP
    else
        if [ -f $topfile ] ; then
            # The following circumlocution (repeated below as well) ensures
            # that we record the true directory name and not one that is
            # faked up with symlink names.
            PWD= /bin/pwd
        else
            # We redirect cd to /dev/null in case it's aliased to
            # a command that prints something as a side-effect
            # (like pushd)
            local here=$PWD
            local top=
            while [ \( ! \( -f $topfile \) \) -a \( $PWD != "/" \) ]; do
                cd .. > /dev/null
                top=`PWD= /bin/pwd`
            done
            cd $here > /dev/null
            if [ -f "$top/$topfile" ]; then
                echo $top
            fi
        fi
    fi
}

# Switch current directory to the top of the tree
mcitop()
{
    local top=$(get_mcitop)
    if [ "$top" ] ; then
        cd $top
    else
        echo "Couldn't locate the top of the tree.  Try setting MCITOP."
    fi
}

# Clear this variable every time running this script file. 
# And then it will be set when the vendorsetup.sh files 
# are included at the end of the file.
unset TURNKEY_MENU_CHOICES

# Collect every turnkey available
add_turnkey_combo()
{
	local new_combo=$1
    local c
    for c in ${TURNKEY_MENU_CHOICES[@]} ; do
        if [ "$new_combo" = "$c" ] ; then
            return
        fi
    done
    TURNKEY_MENU_CHOICES=(${TURNKEY_MENU_CHOICES[@]} $new_combo)
}

# Add all default turnkeys from here
add_turnkey_combo full-lite

# List all turnkeys available 
print_turnkey_menu()
{
	echo
    echo "TURNKEY menu... pick a combo:"

    local i=1
    local choice
    for choice in ${TURNKEY_MENU_CHOICES[@]}
    do
        echo "     $i. $choice"
        i=$(($i+1))
    done
}

# Here "lite" means executing the first four goals in the list below,
# while "all" doing every goal respectively, except for backup, upgrade,
# and lite.
GOALS_CHOICES=(\
	clean \
	preinstall \
	configure \
	install \
	postconfig \
	custom \
	backup \
	upgrade \
	lite \
	all)

# Check if the specified goals are valid
check_goals()
{
	local target_goal default_goal
	local is_valid
	local PASSED_GOALS=(`echo "$@"`)
	for target_goal in ${PASSED_GOALS[@]}
	do
		for default_goal in ${GOALS_CHOICES[@]}
    	do
		    if [ "$target_goal" = "$default_goal" ] ; then
		        is_valid=0
		        break 1
		    else
		    	is_valid=1
		    fi
    	done
	done
    return $is_valid
}

# Here "full" means building every service selected in site specs.
LMS_CHOICES=(\
	sentry)
SSO_CHOICES=(\
	migo)
CMS_CHOICES=(\
	drupal \
	mediawiki \
	cmscustom)
ITS_CHOICES=(\
	bugzilla)
SCMR_CHOICES=(\
	gerrit \
	gitolite)
CI_CHOICES=(\
	jenkins)
SERVICES_CHOICES=(\
	# LMS
	${LMS_CHOICES[@]} \
	# SSO
	${SSO_CHOICES[@]} \
	# CMS
	${CMS_CHOICES[@]} \
	# ITS
	${ITS_CHOICES[@]} \
	# SCMR
	${SCMR_CHOICES[@]} \
	# CI
	${CI_CHOICES[@]} \
	full)

# Check if the specified services are valid
check_services()
{
	local target_srv default_srv
	local is_valid
	local PASSED_SRVS=(`echo "$@"`)
	for target_srv in ${PASSED_SRVS[@]}
	do
		for default_srv in ${SERVICES_CHOICES[@]}
    	do
		    if [ "$target_srv" = "$default_srv" ] ; then
		        is_valid=0
		        break 1
		    else
		    	is_valid=1
		    fi
    	done
	done
    return $is_valid
}

# Check if the specified site is the one we can set up
check_site()
{
	local toppath specs site
	local default_site=mci.org
	
	toppath=$(get_mcitop)
    if [ ! "$toppath" ]; then
        echo "Couldn't locate the top of the tree.  Try setting MCITOP." >&2
        return
    fi
	
	if [ "$1" = "full" ] ; then
		specs=(`ls build/*/$1.sh`)
		include_specs $specs
		site=$(get_specs_var MCI SITE_NAME)
		clean_specs MCI
		if [ "$site" = "$default_site" ] ; then
			return 0
		else
			return 1
		fi
	else
		specs=(`ls sites/*/*/$1.sh`)
		include_specs $specs
		site=$(get_specs_var MCI SITE_NAME)
		clean_specs MCI
		if [ "$site" = "$1" ] ; then
			return 0
		else
			return 1
		fi
	fi
}

# Choose target site
turnkey()
{
	local answer selection 
	local site services goals

    if [ "$1" ] ; then
        answer=$1
    else
        print_turnkey_menu
        echo -n "Which would you like? [full-lite] "
        read answer
    fi

    if [ -z "$answer" ] ; then
        selection=full-all
    elif (echo -n $answer | grep -q -e "^[0-9][0-9]*$") ; then
        if [ $answer -le ${#TURNKEY_MENU_CHOICES[@]} ] ; then
            selection=${TURNKEY_MENU_CHOICES[$(($answer-1))]}
        fi
    elif (echo -n $answer | grep -q -e "^[^\-][^\-]*-[^\-][^\-]*$") ; then
        selection=$answer
    fi

    if [ -z "$selection" ] ; then
        echo
        echo "Invalid turnkey combo: $answer"
        return 1
    fi

    site=$(echo -n $selection | sed -e "s/-.*$//" | sed -e "s/_.*$//")
    check_site $site
    if [ $? -ne 0 ] ; then
        echo
        echo "** Don't have a site spec for: '$site'"
        site=
    fi
    
    services=$(echo -n $selection | sed -e "s/-.*$//" | sed -e "s/^[^_]*_//" | sed -e "s/_/ /g")
    check_services ${services[@]}
    if [ $? -ne 0 ] ; then
    	echo
        echo "** Invalid services: '${services[@]}'"
        echo "** Must be one or two of '${SERVICES_CHOICES[@]}'"
        services=
    fi

    goals=$(echo -n $selection | sed -e "s/^[^\-]*-//" | sed "s/_/ /g")
    check_goals ${goals[@]}
    if [ $? -ne 0 ] ; then
        echo
        echo "** Invalid goals: '${goals[@]}'"
        echo "** Must be one or two of '${GOALS_CHOICES[@]}'"
        goals=
    fi

    if [ -z "$site" -o -z "$services" -o -z "$goals" ] ; then
        echo
        return 1
    fi

    export TARGET_SITE=$site
    export TARGET_SITE_SERVICES=${services[@]}
    export TARGET_SITE_GOALS=${goals[@]}
    
    # Set target version number for MCI
    export TARGET_VERSION_NUMBER=1.0
}

# Setup services
services()
{
	if [ "$TARGET_LMS" ] ; then
		lms
	fi
	if [ "$TARGET_SSO" ] ; then
		sso
	fi
	if [ "$TARGET_CMS" ] ; then
		cms
	fi
	if [ "$TARGET_ITS" ] ; then
		its
	fi
	if [ "$TARGET_SCMR" ] ; then
		scmr
	fi
	if [ "$TARGET_CI" ] ; then
		ci
	fi
}

# Display the target site setting
showconfig()
{
	echo
	echo "=========================="
	echo "TARGET_SITE=$TARGET_SITE"
	echo "TARGET_LMS=${TARGET_LMS[@]}"
	echo "TARGET_SSO=${TARGET_SSO[@]}"
	echo "TARGET_CMS=${TARGET_CMS[@]}"
	echo "TARGET_ITS=${TARGET_ITS[@]}"
	echo "TARGET_SCMR=${TARGET_SCMR[@]}"
	echo "TARGET_CI=${TARGET_CI[@]}"
	echo "=========================="
	echo
}

# Obtain the complete target site specs
configure()
{
	local toppath
	toppath=$(get_mcitop)
    if [ ! "$toppath" ]; then
        echo "Couldn't locate the top of the tree.  Try setting MCITOP." >&2
        return
    fi
    
	if [ -z "$TARGET_SITE" -o -z "$TARGET_SITE_SERVICES" -o -z "$TARGET_SITE_GOALS" ] ; then
		echo
		echo "** Invalid site setting. Then, use 'turnkey' configuring target site."
		return
	fi
	
	if [ "$TARGET_VERSION_NUMBER" != "$MCI_VERSION_NUMBER" ] ; then
		echo
		echo "** MCI Version not matched. Try to get the up-to-date code for MCI."
		return
	fi
	
	local specs	
	if [ "$TARGET_SITE" = "full" -o "$TARGET_SITE" = "mci.org" ] ; then
		specs=(`ls build/*/full.sh`)
	else
		specs=(`ls sites/*/*/$TARGET_SITE.sh`)
	fi
	if [ ! "$specs" ] ; then
		echo
		echo "** No specs for target site '$TARGET_SITE'."
		return
	fi
	include_specs $specs
	copy_specs TARGET MCI
	round_specs
	clean_specs MCI
}

# Include all applications in core
include_core()
{
	. build/core/version.sh
	
	. build/core/specs.sh
	
	. build/core/httpd.sh
	. build/core/dbengine.sh
	
	. build/core/lms.sh
	. build/core/sso.sh
	. build/core/cms.sh
	. build/core/its.sh
	. build/core/scmr.sh
	. build/core/ci.sh
}

# Deploy target sites
launch()
{
	# Get the complete specs according to target sites
	configure
	
	# Print target site settings
	showconfig
	
	# Setup services used by the upper
	services
}

# Import variables and functions
include_core

# Export MCITOP into the current shell environment
mci_top=(`/bin/pwd`)
if [ -f $mci_top/build/mci.sh ] ; then
	export MCITOP=$mci_top
fi
unset mci_top

# Execute the contents of any vendorsetup.sh file we can find.
for f in `/bin/ls $MCITOP/sites/*/*/vendorsetup.sh 2> /dev/null`
do
    echo "including $f"
    . $f
done
unset f
