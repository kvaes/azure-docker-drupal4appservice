#!/bin/bash
set -e

# Functions
setup_drupal(){
  # Setup default settings based on env variables
  cp ${HOME_SITE_VOLATILE}/sites/default/default.settings.php ${HOME_SITE_VOLATILE}/sites/default/settings.php
  # Tweak directories for the Linux App Service
  echo "Drupal Persist is enabled, so moving www to wwwroot home folder to enable the shared file system"
  if test ! -e "${HOME_SITE_PERSISTENT}"; then
      echo "Creating ${HOME_SITE_PERSISTENT}"
      mkdir -p ${HOME_SITE_PERSISTENT}
    fi
  if [ ${DRUPAL_PERSIST} = true ] ; then
    echo "Setting the original wwwroot/home folder from ${HOME_SITE_VOLATILE} to ${HOME_SITE_PERSISTENT}"
    shopt -s dotglob nullglob
    mv ${HOME_SITE_VOLATILE}/* ${HOME_SITE_PERSISTENT}
    # rm -rf ${HOME_SITE_VOLATILE}
    mv ${HOME_SITE_VOLATILE} ${HOME_SITE_VOLATILE}.original
    ln -sf ${HOME_SITE_PERSISTENT} ${HOME_SITE_VOLATILE}
  fi
  echo "Setting permisions to Home Sites"
  chown -R www-data:www-data ${HOME_SITE_VOLATILE}
  chown -R www-data:www-data ${HOME_SITE_PERSISTENT}
  # Setting up salt file
  echo "Generating salt"
  cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1 > /home/site/salt.txt 
  # Copying cert (https://docs.microsoft.com/en-us/azure/mysql/howto-configure-ssl)
  mv /var/www/BaltimoreCyberTrustRoot.crt.pem /home/site/BaltimoreCyberTrustRoot.crt.pem 
}

start_apache() {
  # Start Apache
  echo "Setting additional env vars for Apache2"
  : "${APACHE_CONFDIR:=/etc/apache2}"
  : "${APACHE_ENVVARS:=$APACHE_CONFDIR/envvars}"
  if test -f "$APACHE_ENVVARS"; then
        . "$APACHE_ENVVARS"
  fi

  ## Apache gets grumpy about PID files pre-existing
  : "${APACHE_RUN_DIR:=/var/run/apache2}"
  : "${APACHE_PID_FILE:=$APACHE_RUN_DIR/apache2.pid}"
  rm -f "$APACHE_PID_FILE"

  ## create missing directories
  ## (especially APACHE_RUN_DIR, APACHE_LOCK_DIR, and APACHE_LOG_DIR)
  for e in "${!APACHE_@}"; do
        if [[ "$e" == *_DIR ]] && [[ "${!e}" == /* ]]; then
                # handle "/var/lock" being a symlink to "/run/lock", but "/run/lock" not existing beforehand, so "/var/lock/something" fails to mkdir
                #   mkdir: cannot create directory '/var/lock': File exists
                dir="${!e}"
                while [ "$dir" != "$(dirname "$dir")" ]; do
                        dir="$(dirname "$dir")"
                        if [ -d "$dir" ]; then
                                break
                        fi
                        absDir="$(readlink -f "$dir" 2>/dev/null || :)"
                        if [ -n "$absDir" ]; then
                                mkdir -p "$absDir"
                        fi
                done

                mkdir -p "${!e}"
        fi
  done

  echo "Launching Apache2"
  exec apache2 -DFOREGROUND "$@"
}

# Main Runtime
## Setup Drupal Install for the Azure Linux App Service
if test ! -e "${HOME_SITE_VOLATILE}/sites/default/settings.php"; then
    echo "Tweaking Drupal Install for Azure Linux App Service..."
    setup_drupal
fi
echo "Starting Apache"
start_apache
