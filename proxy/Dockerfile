FROM nginxinc/nginx-unpriveleged:1-alpine

LABEL maintainer="sablos@hotmail.com"

COPY ./default.conf.tpl /etc/nginx/default.conf.tpl
COPY ./uwsgi_params /etc/nginx/uwsgi_params
COPY ./run.sh /run.sh

# set default env variables
ENV LISTEN_PORT=8000
ENV APP_HOST=app
ENV APP_PORT=9000

# create the static location and set permissions for copied files
USER root

RUN mkdir -p /vol && \
    chmod 755 /vol && \
    touch /etc/nginx/conf.d/default.conf && \
    chown nginx:nginx /etc/nginx/conf.d/default.conf && \
    chmod +x /run.sh

VOLUME /vol

USER nginx

CMD [ "/run.sh" ]