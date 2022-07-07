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

echo "Prefixe des URLs (dans le RSS): $BACON_BASEURL_IN_RSS"
echo "Prefixe des URLs (a utiliser pour chauffer): $BACON_BASEURL_FOR_WARM"

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
  BACON_KBART_URL=$(echo $BACON_KBART_URL |\
	            sed "s#${BACON_BASEURL_IN_RSS}#${BACON_BASEURL_FOR_WARM}#g")
  WARM_REPORT_FILE=$(echo $BACON_KBART_URL | \
    sed "s#${BACON_BASEURL_FOR_WARM}##g" | \
    sed "s#^/##g" | \
    sed "s#?.*##g")
  if [ "$WARM_REPORT_FILE" == "" ]; then
    continue
  fi
  WARM_REPORT_DIRNAME=$(dirname $WARM_REPORT_FILE)
  WARM_REPORT_FILENAME=$(basename $WARM_REPORT_FILE)

  mkdir -p /tmp/bacon-report/$WARM_REPORT_DIRNAME
  echo "URL chauffee ($WARMED_URL_COUNT sur $WARMED_URL_COUNT_MAX) : $BACON_KBART_URL" \
       > /tmp/bacon-report/$WARM_REPORT_FILE
  echo "Date du rapport: $(date)" >> /tmp/bacon-report/$WARM_REPORT_FILE
  echo "Header HTTP cURL :" >> /tmp/bacon-report/$WARM_REPORT_FILE
  KBART_DOWNLOAD_TS1=$(date +%s)
  
  # c'est ici qu'on appelle vraiment l'URL pour la chauffer !
  curl \
    -L -v -s --trace-time \
    $BACON_KBART_URL \
    1>/tmp/kbart.temp \
    2>>/tmp/bacon-report/$WARM_REPORT_FILE

  KBART_DOWNLOAD_TS2=$(date +%s)
  KBART_DOWNLOAD_TIME=$(expr $KBART_DOWNLOAD_TS2 - $KBART_DOWNLOAD_TS1)
  KBART_SIZE=$(du -h /tmp/kbart.temp | awk '{print $1}')
  KBART_NB_LINES=$(wc -l /tmp/kbart.temp | awk '{print $1}')

  echo "Taille du KBART : $KBART_SIZE" >>/tmp/bacon-report/$WARM_REPORT_FILE
  echo "Nombre de lignes dans le KBART : $KBART_NB_LINES" >>/tmp/bacon-report/$WARM_REPORT_FILE
  echo "Temps de telechargement du KBART : $KBART_DOWNLOAD_TIME" >>/tmp/bacon-report/$WARM_REPORT_FILE
  echo "URL chauffee ($WARMED_URL_COUNT sur $WARMED_URL_COUNT_MAX) : $BACON_KBART_URL [size=$KBART_SIZE, nb_lines=$KBART_NB_LINES, nb_seconds=$KBART_DOWNLOAD_TIME]"

  WARMED_URL_COUNT=$(expr $WARMED_URL_COUNT + 1)
  if [ "$WARMED_URL_COUNT" -gt "$WARMED_URL_COUNT_MAX" ]; then
    break
  fi
done

echo "Chauffage de BACON: termine"
