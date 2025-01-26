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

add ```
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
