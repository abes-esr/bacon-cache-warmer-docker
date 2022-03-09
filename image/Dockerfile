FROM rockylinux:8

# systeme pour les crontab
RUN yum install -y cronie vim && \
    crond -V && rm -rf /etc/cron.*/*
COPY ./crontab-tasks /etc/local/etc/cron.d/crontab-tasks
RUN crontab /etc/local/etc/cron.d/crontab-tasks

# curl: pour chauffer le cache en appelant les URL
# libxml2: pour naviguer dans le RSS et extraire les <link> de tous les KBART avec la commande xmllint
# procps: pour detecter si le script de chauffeur de cache precedent est termine ou pas (commande ps)
RUN yum install -y curl libxml2 procps

# le/les script de cache warmer
COPY ./bacon-cache-warmer.sh /usr/local/bin/bacon-cache-warmer.sh

# gestion des cron dans docker inspirée de
# https://sudonull.com/post/80071-Running-cron-inside-a-docker-container-Redmadrobots-blog
COPY ./docker-entrypoint.sh /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["crond", "-n"]
