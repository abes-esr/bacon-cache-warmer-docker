#!/bin/bash

# Initialisation des paramètres de l'application avec les valeurs par défaut
export BACON_RSS_URL=${BACON_RSS_URL:='https://bacon.abes.fr/rss'}
export BACON_MAX_URL_TO_WARM=${BACON_MAX_URL_TO_WARM:='5'}
export BACON_BASEURL_IN_RSS=${BACON_BASEURL_IN_RSS:='http://bacon.abes.fr'}
export BACON_BASEURL_FOR_WARM=${BACON_BASEURL_FOR_WARM:='https://bacon.abes.fr'}



# Réglage de /etc/environment pour que les crontab s'exécutent avec les bonnes variables d'env
echo "$(env)
LANG=en_US.UTF-8" > /etc/environment

# Lance au démarrage le cache-warmer
/usr/local/bin/bacon-cache-warmer.sh >/proc/1/fd/1 2>/proc/1/fd/2

# execute CMD (crond)
exec "$@"
