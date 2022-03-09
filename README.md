# bacon-cache-warmer-docker

(Travail en cours - 09/03/2022)

[![Docker Pulls](https://img.shields.io/docker/pulls/abesesr/bacon-cache-warmer.svg)](https://hub.docker.com/r/abesesr/bacon-cache-warmer/)
[![bacon-cache-warmer ci](https://github.com/abes-esr/bacon-cache-warmer-docker/actions/workflows/ci.yml/badge.svg)](https://github.com/abes-esr/bacon-cache-warmer-docker/actions/workflows/ci.yml)

Cette application est un batch périodique permettant de chauffer le cache de l'application [BACON](https://bacon.abes.fr). Ce batch va successivement appeler toutes les URL de tous les packages KBART de BACON. Ceci aura pour effet de mettre en cache le contenu de ces KBART dans le système de cache de BACON (qui est lui même en cours de conception) et ainsi les futurs téléchargement des KBART sera ultra rapide car chaque génération de KBART ne provoquera plus de traitement parfois intensif au niveau de la base de donnée.

Son mode de fonctionnement est le suivant : appeler les URLs de téléchargement des packages KBART de BACON (plus de 20 000 URL à la date du 8 mars 2022) en se basant sur le [fil RSS de bacon](https://bacon.abes.fr/rss) qui contient la liste de tous les packages KBART de BACON.

Remarque: cette application n'a pas vocation à être utilisée hors du SI de l'Abes. Merci de [contacter l'Abes](https://stp.abes.fr) si jamais un besoin non imaginé emergerait en consultant le code de cette application.

## Utilisation en production à l'Abes

Pour installer et démarrer l'application à l'Abes, il faut se référer au dépot git suivant https://git.abes.fr/microwebservices-docker/ qui n'est actuellement pas ouvert en opensource car le code source des MicroWebService n'est pas ouvert (pour cela il aurait besoin d'être refondu).

## Paramètres

Les variables d'environnement suivantes permettent de paramétrer l'application :

- ``BACON_RSS_URL``: l'URL du RSS de BACON, à noter que ce lien n'est pas sensé varier (valeur par défaut ``https://bacon.abes.fr/rss``)
- ``BACON_MAX_URL_TO_WARM``: le nombre max d'URL a chauffer, ce paramètre a du sens pour tester et développer ce script, en production il faut TOUT chauffer (valeur par défaut ``5``)

## Développement

Pour faire évoluer cette application, il faut l'installer en local et la lancer en local de cette manière :
```
## Installer l'appli
git clone https://github.com/abes-esr/bacon-cache-warmer-docker
cd bacon-cache-warmer-docker/
cp .env-dist .env
# editer si besoin .env

# Lancer l'application
docker-compose up
```

Les logs qui s'affichent permettent de constater ce qui se passe.

Il est alors possible de modifier le code (Dockerfile, bacon-cache-warmer.sh etc) puis de retester en lançant cette commande:
```
# executer CTRL+C pour quitter le précédent docker-compose up
# puis lancer ceci pour reconstruire l'image avant de recréer un conteneur
cd bacon-cache-warmer-docker/
docker-compose --build up
```

### Générer une nouvelle version de l'image

```
curl https://raw.githubusercontent.com/fmahnke/shell-semver/master/increment_version.sh > increment_version.sh
chmod +x ./increment_version.sh
CURRENT_VERSION=$(git tag | tail -1)
NEXT_VERSION=$(./increment_version.sh -patch $CURRENT_VERSION) # -patch, -minor or -major
sed -i "s#bacon-cache-warmer:$CURRENT_VERSION#bacon-cache-warmer:$NEXT_VERSION#g" README.md docker-compose.yml
git commit README.md docker-compose.yml -m "Version $NEXT_VERSION" 
git tag $NEXT_VERSION
git push && git push --tags
```
