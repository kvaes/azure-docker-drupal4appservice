FROM drupal:latest
MAINTAINER Karim Vaes <dockerhub@kvaes.be>

# ENV VARIABLES
## Drupal
ENV DRUPAL_DB_USER ""
ENV DRUPAL_DB_PASS ""
ENV DRUPAL_DB_HOST ""
ENV DRUPAL_DB_NAME ""
ENV DRUPAL_DB_DRIVER "mysql"
ENV DRUPAL_DB_PORT 3306
ENV DRUPAL_DB_COLLATION "utf8mb4_general_ci"
ENV DRUPAL_DB_PREFIX ""
ENV DRUPAL_PERSIST true 
## Linux App Service
ENV HOME_SITE_PERSISTENT "/home/site/wwwroot"
ENV HOME_SITE_VOLATILE "/var/www/html"

# Finalize 
COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

COPY default.settings.php /var/www/html/sites/default
COPY BaltimoreCyberTrustRoot.crt.pem /var/www

ENTRYPOINT ["entrypoint.sh"]
