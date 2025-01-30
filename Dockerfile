FROM python:3.9-alpine3.13

LABEL maintainer="sablos@hotmail.com"

ENV PYTHONUNBUFFERED=1

COPY ./requirements.txt /requirements.txt

WORKDIR /app
EXPOSE 8000

# install postgresql client and dependencies
RUN python -m venv /venv && \
    /venv/bin/pip install --upgrade pip && \
    apk add --update --no-cache postgresql-client && \
    apk add --update --no-cache --virtual .temp-deps \
        build-base postgresql-dev musl-dev && \
    /venv/bin/pip install -r /requirements.txt && \
    apk del .temp-deps

# create app user and create vol folder for media and static files
RUN adduser --disabled-password --no-create-home app && \
    mkdir -p /vol/static && \
    mkdir -p /vol/media && \
    chown -R app:app /vol && \
    chmod -R 755 /vol

COPY ./app /app

# append the venv executables to the system path to run
ENV PATH="/venv/bin:$PATH"

# set the user in the system to app
USER app