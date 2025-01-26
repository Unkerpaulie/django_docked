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