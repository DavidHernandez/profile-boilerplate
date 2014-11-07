#!/bin/bash

CATEGORIES=( taxonomy menu_custom filter field_base field_instance node commerce_customer commerce_product_type profile2_type flag views_view user_role user_permission rules_config elysia_cron feeds_importer)
echo $1 | grep -i 'help' > /dev/null

if [ $? == 0 ]
then
  echo "This scripts exports the configuration to features using a layered approach."
  echo "It will export features in a specific order and will enable them."
  echo "Usage:"
  echo "From the profile root page: ./scripts/create_features.sh"
  exit 1
fi

PACKAGE=`ls | sed -rn 's/([a-zA-Z0-9\_]+)\.info/\1/p'`

for i in ${CATEGORIES[@]}
do
  feature_name=${PACKAGE}_$i
  if [ -f "modules/feature/${feature_name}/${feature_name}.info" ]
  then
    echo "Feature ${feature_name} already exists, we will increment the version number"
    drush fe $feature_name "$i:" --destination=profiles/${PACKAGE}/modules/feature --version-increment -y
  else
    echo "We will create the feature ${feature_name}"
    drush fe $feature_name "$i:" --destination=profiles/${PACKAGE}/modules/feature --version-set="7.x-1.0" -y
    sed -i "s/package = Features/package = Features ${PACKAGE}/" modules/feature/${feature_name}/${feature_name}.info
    drush en $feature_name -y
  fi
done

drush cc all
