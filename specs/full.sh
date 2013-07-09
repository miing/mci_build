# Inherits
inherit_specs build/specs/common.sh

inherit_specs build/specs/dbengine.sh
inherit_specs build/specs/httpd.sh

inherit_specs build/specs/lms.sh
inherit_specs build/specs/sso.sh
inherit_specs build/specs/cms.sh
inherit_specs build/specs/its.sh
inherit_specs build/specs/scmr.sh
inherit_specs build/specs/ci.sh

# Overrides
MCI_SITE_NAME=mci.org

MCI_LMS=sentry
MCI_LMS_SENTRY_SITE=logs.mci.org

MCI_SSO=migo
MCI_SSO_MIGO_SITE=login.mci.org

MCI_CMS=(drupal mediawiki)
MCI_CMS_DRUPAL_SITE=mci.org
MCI_CMS_MEDIAWIKI_SITE=wiki.mci.org

MCI_ITS=bugzilla
MCI_ITS_BUGZILLA_SITE=bugs.mci.org

MCI_SCMR=gerrit
MCI_SCMR_GERRIT_SITE=review.mci.org

MCI_CI=jenkins
MCI_CI_JENKINS_SITE=jenkins.mci.org
