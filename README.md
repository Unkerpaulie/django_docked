# django_docked

### Prerequisites
* Docker installed
* Code Editor
* Github Account
* AWS Account
* SSH Authentication

### Create a new Github project
Set up a new repo, add readme and gitignore

### Go to the location to development the project
Copy Github repo url, In commnad line type 
`git clone [repo_url]`

### Create requirements.txt
```
django
```

### Create a Dockerfile
```
FROM python:3.9-alpine3.13

LABEL maintainer="sablos@hotmail.com"

ENV PYTHONUNBUFFERED=1

COPY ./requirements.txt /requirements.txt

WORKDIR /app
EXPOSE 8000

RUN python -m venv /venv && \
    /venv/bin/pip install --upgrade pip && \
    /venv/bin/pip install -r /requirements.txt && \
    adduser --disabled-password --no-create-home app

COPY ./app /app

ENV PATH="/venv/bin:$PATH"

USER app
```
### Create docker-compose.yml
```
version: '3.9'

services:
  app:
    build:
      context: .
    ports: 
      - 8000:8000
    volumes:
      - ./app:/app

```

### Create .dockerignore
```
# Git
.git
.gitignore

# Docker
.docker

# Python
app/__pycache__/
app/*/__pycache__/
app/*/*/__pycache__/
app/*/*/*/__pycache__/
.env
.venv
venv/

# loacal postgresql data
data/

# documentation
readme.md
```

### Buildthe image
Run command
`docker-compose build`

### Run the image and create the djano project
`docker-compose run --rm app sh -c "django-admin startproject app ."`

### Modify settings.py
add `import os`

change `SECRET_KEY = os.environ.grt("SECRET_KEY")`  

change `DEBUG = bool(int(os.environ.get("DEBUG", 0)))`

after `ALLOWED_HOSTS = [] `

add 
```
ALLOWED_HOSTS.extend(filter(None, os.environ.get("ALLOWED_HOSTS", "").splut(",")))
```

### Set the environment variables in docker compose
```
    environment:
      - SECRET_KEY=myownsecretKee
      - DEBUG=1
```

### Add the database service in docker-compose.yml
```
  db:
    image: postgres:13-alpine
    environment:
      - POSTGRES_DB=devdb
      - POSTGRES_USER=devuser
      - POSTGRES_PASSWORD=changeme
```

### Configure the django app to connect to and use the database
```
    environment:
      - SECRET_KEY=myownsecretKee
      - DEBUG=1
      - DB_HOST=db
      - DB_NAME=devdb
      - DB_USER=devuser
      - DB_PASS=changeme
    depends_on:
      - db
```

### Add Postgres driver to the application from Dockerfile
In the Dockerfile, add these to the list of RUN commands
```
    apk add --update --no-cache postgresql-client && \
    apk add --update --no-cache --virtual .temp-deps \
        build-base postgresql-dev musl-dev && \
    /venv/bin/pip install -r /requirements.txt && \
    apk del .temp-deps && \
```

### Update requirements.txt to include postgres psycopg2
add `psycopg2>=2.8.6,<2.9`

### Modify settings.py to include the database connection
```
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'HOST': os.environ.get("DB_HOST"),
        'NAME': os.environ.get("DB_NAME"),
        'USER': os.environ.get("DB_USER"),
        'PASSWORD': os.environ.get("DB_PASS"),
    }
}
```

### Rebuild the docker container to include the updates
`docker-compose build`

### Create a new core app in the project
`docker-compose run --rm app sh -c "python manage.py startapp core"`

### Create models for application

### Run makemigrations
`docker-compose run --rm app sh -c "python manage.py makemigrations"`
The following commands are necessary to make sure the db is connected, migrate changes to the db, and run the server
`docker-compose run --rm app sh -c "python manage.py wait_for_db"`
`docker-compose run --rm app sh -c "python manage.py migrate"`
`docker-compose run --rm app sh -c "python manage.py runserver 0.0.0.0:8000"`

### Set a "wait for db" directive before migrating to avoid errors 
created a django command to try the database connection and wait until it connects

### Envoke the list of commands through docker compose
```
    command: >
      sh -c "python manage.py wait_for_db &&
      python manage.py migrate && 
      python manage.py runserver 0.0.0.0:8000"
```

### Use docker-compose to restart the docker container with the new commands added
`docker-compose up`

# Handling Static and Media files

### Establish directory for static and media in Dockerfile
```
# create an app user and create vol folder for media and static files
RUN adduser --disabled-password --no-create-home app && \
    mkdir -p /vol/static && \
    mkdir -p /vol/media && \
    chown -R app:app /vol && \
    chmod -R 755 /vol
```

### Update settings.py to handle the meida and static locations
```
STATIC_URL = '/static/'
MEDIA_URL = '/media/'

STATIC_ROOT = '/vol/static'
MEDIA_ROOT = '/vol/media'
```

### Change the main urls.py file to serve the media files in development
In urls.py, at the top add
```
from django.conf.urls.static import static
from django.conf import settings
```

and at the bottom add
```
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
```

### Create a superuser account in django
`docker-compose run --rm app sh -c "python manage.py createsuperuser"`

### Restart the docker service
`docker-compose up`

### Login to Django admin and test the file upload in the backend

# Production Server Configuration

Create a folder in the project named "proxy"
```
proxy
  |
  |- uwsgi_params
  |- Dockerfile
  |- default.conf.tpl
  |- run.sh
```

### uwsgi_params
```
uwsgi_param QUERY_STRING $query_string;
uwsgi_param REQUEST_METHOD $request_method;
uwsgi_param CONTENT_TYPE $content_type;
uwsgi_param CONTENT_LENGTH $content_length;
uwsgi_param REQUEST_URI $request_uri;
uwsgi_param PATH_INFO $document_uri;
uwsgi_param DOCUMENT_ROOT $document_root;
uwsgi_param SERVER_PROTOCOL $server_protocol;
uwsgi_param REMOTE_ADDR $remote_addr;
uwsgi_param REMOTE_PORT $remote_port;
uwsgi_param SERVER_ADDR $server_addr;
uwsgi_param SERVER_PORT $server_port;
uwsgi_param SERVER_NAME $server_name;
```

### default.conf.tpl
This configures nginx configuration template with placeholder values
```
server {
    listen ${LISTEN_PORT};

    location /static {
        alias           /vol/static;
    }

    location /media {
        alias           /vol/media;
    }

    location / {
        uwsgi_pass              ${APP_HOST}:${APP_PORT};
        include                 /etc/nginx/uwsgi_params;
        client_max_body_size    10M;
    }
}
```

### run.sh
This script pulls the environment variables and substitutes them into the placeholders in the nginx configuration template above
```
#!/bin/sh

set -e

envsubst < /etc/nginx/default.conf.tpl > /etc/nginx/conf.d/default.conf

nginx -g 'daemon off;'
```

### Dockerfile
```
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
```

### Create a script in the Django project that connects it to the proxy
