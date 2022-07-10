#!/bin/bash
#
# C'est le script appele periodiquement qui permet de chauffer le cache de BACON
#

# on le fait rien si la derniere execution de ce meme script n'est pas terminee
ps aux | grep "bacon-cache-warmer.sh" | grep -v grep >/dev/null
if [ "$?" != "0" ]; then
  echo "Chauffage de BACON: ignore (car un autre script est en cours)"
  exit 0
fi

echo "Chauffage de BACON: demarrage"

# On se base sur le RSS de bacon pour obtenir toutes les URL a appeler
echo "Telechargement du RSS de BACON (debut): $BACON_RSS_URL"
curl -s -L $BACON_RSS_URL > /tmp/bacon.rss
echo "Telechargement du RSS de BACON (fin): taille du fichier $(du -h /tmp/bacon.rss | awk '{print $1}')"

echo "SED a utiliser pour modifier les URLs du  RSS avant de chauffer : $BACON_URL_SED_BEFORE_WARM"

# extraction des URL de tous les packages BACON à l'aide de xpath
BACON_KBART_LIST=$(\
  cat /tmp/bacon.rss |\
  xmllint --xpath '//link' -\
)
# les sed suivants c'est pour avoir les URL ligne par ligne (ou separees par un espace)
BACON_KBART_NB=$(echo $BACON_KBART_LIST | sed 's#<link>#\n#g' | sed 's#</link>##g' | wc -l)
BACON_KBART_LIST=$(echo $BACON_KBART_LIST | sed 's#<link>#\n#g' | sed 's#</link>##g')

if [ "$BACON_MAX_URL_TO_WARM" -gt "$BACON_KBART_NB" ] || \
   [ "$BACON_MAX_URL_TO_WARM" -eq "0" ]; then
  WARMED_URL_COUNT_MAX=$BACON_KBART_NB
  echo "Demarrage chauffage du cache : nbr URL a chauffer = $BACON_KBART_NB"
else
  WARMED_URL_COUNT_MAX=$BACON_MAX_URL_TO_WARM
  echo "Le nombre max d'URL a chauffer est limite par ce parametre : BACON_MAX_URL_TO_WARM=$BACON_MAX_URL_TO_WARM"
  echo "Demarrage chauffage du cache : nb URL a chauffer = $BACON_MAX_URL_TO_WARM (mais $BACON_KBART_NB URL disponibles dans le RSS de BACON, cf paramètre BACON_MAX_URL_TO_WARM)"
fi

WARMED_URL_COUNT=1
for BACON_KBART_URL in $BACON_KBART_LIST
do
  # on commence par preparer l'URL a chauffer en remplacant son prefixe si demande
  # et on zap l'url de la racine de BACON
  # et on prepare des variables pour pouvoir ecrire dans des fichiers/repertoires 
  # le rapport de chauffage
  BACON_KBART_URL=$(echo $BACON_KBART_URL | sed $BACON_URL_SED_BEFORE_WARM)

  KBART_DOWNLOAD_DST_PATH='/tmp/temp.kbart'
  if [ $BACON_STORE_WARMED_TO_PATH != "" ]; then
    mkdir -p $BACON_STORE_WARMED_TO_PATH
    KBART_DOWNLOAD_DST_PATH="$BACON_STORE_WARMED_TO_PATH/$WARMED_URL_COUNT.kbart"
  fi

  # c'est ici qu'on appelle vraiment l'URL pour la chauffer !
  KBART_DOWNLOAD_TS1=$(date +%s)
  HTTP_STATUS_CODE=$(
    curl \
      -L -s \
      -o $KBART_DOWNLOAD_DST_PATH \
      -w "%{http_code}" \
      $BACON_KBART_URL
  )
  KBART_DOWNLOAD_TS2=$(date +%s)

  KBART_DOWNLOAD_TIME=$(expr $KBART_DOWNLOAD_TS2 - $KBART_DOWNLOAD_TS1)
  KBART_SIZE=$(du -h $KBART_DOWNLOAD_DST_PATH | awk '{print $1}')
  KBART_NB_LINES=$(wc -l $KBART_DOWNLOAD_DST_PATH | awk '{print $1}')
  echo "URL chauffee ($WARMED_URL_COUNT sur $WARMED_URL_COUNT_MAX) : $BACON_KBART_URL [status=$HTTP_STATUS_CODE, size=$KBART_SIZE, nb_lines=$KBART_NB_LINES, nb_seconds=$KBART_DOWNLOAD_TIME]"

  WARMED_URL_COUNT=$(expr $WARMED_URL_COUNT + 1)
  if [ "$WARMED_URL_COUNT" -gt "$WARMED_URL_COUNT_MAX" ]; then
    break
  fi

  if [ $BACON_DELAY_BETWEEN_WARM != "0" ]; then
    echo "Attente de BACON_DELAY_BETWEEN_WARM=$BACON_DELAY_BETWEEN_WARM secondes"
    sleep $BACON_DELAY_BETWEEN_WARM
  fi
done

echo "Chauffage de BACON: termine"
