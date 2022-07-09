#!/bin/bash

# Initialisation des paramètres de l'application avec les valeurs par défaut
export BACON_RSS_URL=${BACON_RSS_URL:='https://bacon.abes.fr/rss'}
export BACON_MAX_URL_TO_WARM=${BACON_MAX_URL_TO_WARM:='5'}
export BACON_URL_SED_BEFORE_WARM=${BACON_URL_SED_BEFORE_WARM:='s#http://bacon.abes.fr/\(.*\)#https://bacon.abes.fr/\1#g'}
export BACON_CACHEWARMER_JUST_ONCE=${BACON_CACHEWARMER_JUST_ONCE:='yes'}
export BACON_CACHEWARMER_CRON=${BACON_CACHEWARMER_CRON:='0 3 * * *'}
export BACON_DELAY_BETWEEN_WARM=${BACON_DELAY_BETWEEN_WARM:='0'}


# Réglage de /etc/environment pour que les crontab s'exécutent avec les bonnes variables d'env
echo "$(env)
LANG=en_US.UTF-8" > /etc/environment

# Pour faciliter le debug du conteneur,
# on affiche les paramètres et leurs valeurs dans les logs à son démarrage
env | grep BACON_

# Lance au démarrage le cache-warmer
/usr/local/bin/bacon-cache-warmer.sh >/proc/1/fd/1 2>/proc/1/fd/2

if [ $BACON_CACHEWARMER_JUST_ONCE = "yes" ]; then
    echo "BACON_CACHEWARMER_JUST_ONCE=yes so just stop this container!"
    exit 0
fi

# Configure et execute la crontab (crond)
envsubst < /etc/local/etc/cron.d/crontab-tasks.tmpl > /etc/local/etc/cron.d/crontab-tasks
echo "-> Installing crontab:"
cat /etc/local/etc/cron.d/crontab-tasks
crontab /etc/local/etc/cron.d/crontab-tasks
exec "$@"
