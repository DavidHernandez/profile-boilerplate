#!/bin/bash
set -e

#
# Usage: scripts/deploy.sh [-y] from the boilerplate main directory.
#

# Definning variables & constants
ASK=true
CAT=$(which cat)
CHMOD=$(which chmod)
CP=$(which cp)
DATE=$(which date)
DATETIME=$($DATE '+%Y%m%d%H%M')
DESTINATION="./releases/$DATETIME"
DRUSH=$(which drush)
ECHO=$(which echo)
CLEAN=false
LN=$(which ln)
LS=$(which ls)
MKDIR=$(which mkdir)
MKTEMP=$(which mktemp)
MV=$(which mv)
RM=$(which rm)
RMDIR=$(which rmdir)
SUDO=$(which sudo)
SSL="http://"
TEMP_BUILD=$($MKTEMP -d)

# Colors
GREEN='\033[01;32m'
NC='\033[00m'
RED='\033[01;31m'

usage() {
  $ECHO "Usage: deploy.sh [-y] [-c] [-s]" >&2
  $ECHO "Use -s to install your Drupal under ssl at first time." >&2
  $ECHO "Use -y to skip deletion confirmation." >&2
  $ECHO "Use -c to perform a clean installation and the first time installation." >&2
  cd - > /dev/null
  exit 1
}

# Positioning the script at the base of the structure
OLDDIR=$(pwd)

# Check the options
while getopts ye:csp: opt; do
  case $opt in
    y) ASK=false ;;
    c) CLEAN=true ;;
    s) SSL="https://" ;;
    \?)
    echo "Invalid option: -$OPTARG" >&2
    usage
    ;;
  esac
done

PROJECT=`ls profile | sed -rn 's/([a-zA-Z0-9\_]+)\.info/\1/p'`

if [ ! -f profile/drupal-org.make ]; then
  $ECHO "[error] Run this script expecting ./profile/ directory."
  exit 1
fi

# Drush make expects destination to be empty
$RMDIR $TEMP_BUILD

# Build the profile.
$ECHO -e "${GREEN}Building the profile...${NC}"

$DRUSH make --no-core profile/$PROJECT.make tmp

# Build the distribution and copy the profile in place.
$ECHO -e "${GREEN}Building the distribution...${NC}"
$DRUSH make profile/drupal-org-core.make $TEMP_BUILD
$ECHO -e "${GREEN}Moving to destination...${NC}"
$MKDIR -p $TEMP_BUILD/profiles/$PROJECT
echo "${TEMP_BUILD}"
$CP -r tmp/profiles/$PROJECT/* $TEMP_BUILD/profiles/$PROJECT
$RM -rf tmp
$DRUSH make --no-core --contrib-destination="." profile/drupal-org.make tmp
$CP -r tmp/modules/contrib $TEMP_BUILD/profiles/$PROJECT/modules
$RM -rf tmp
$MV $TEMP_BUILD $DESTINATION

# Create symblic links
$ECHO -e "${GREEN}Creating symbolic links...${NC}"
if [ -h ./active ]; then
  $RM ./active
fi
$LN -s releases/$DATETIME active
$LN -s ../../../../files/public ./releases/$DATETIME/sites/default/files

# Uncomment the next line (and modify it if required), if your project uses private files.
# $LN -s ../../../../files/private ./releases/$DATETIME/sites/default/files/private

# Positioning inside Drupal dir to make drush work properly
cd active

# Update database & clean
if $CLEAN; then
  $ECHO -e "${GREEN}Update database & cleaning...${NC}"
  read -r -p "Give me the complete DOMAIN (ex: www.example.org): " DOMAIN
  read -r -p "Give me the SITE NAME: " SITENAME
  read -r -p "Give me the SITE MAIL: " SITEMAIL
  read -s -r -p "Give me ROOT database password: " PASSWD
  echo

  $ECHO -e "${RED}You are about to DROP all the '$PROJECT' database.${NC}"
  $DRUSH si --db-url=mysql://$PROJECT:$PROJECT@localhost/$PROJECT --db-su=root --db-su-pw=$PASSWD --site-mail="$SITEMAIL" --account-mail="$SITEMAIL" --uri="${SSL}$DOMAIN" $PROJECT

  $CHMOD u+w sites/default/settings.php
  $ECHO "\$base_url='${SSL}$DOMAIN';" >> sites/default/settings.php

  $CP ./sites/default/settings.php $OLDDIR/config/
else
  $CP $OLDDIR/config/settings.php sites/default/
fi

$DRUSH cc all
$DRUSH updatedb -y
$DRUSH cc drush
$DRUSH features-revert-all -y
$DRUSH cc all

# Returning where script was executed
cd $OLDDIR

# Leaving only last 4 releases
$LS -dt releases/* | sed '1,4d' | xargs -I % sh -c 'chmod -R u+w %; rm -rf %;'

$ECHO -e "${GREEN}...DONE...${NC}"

