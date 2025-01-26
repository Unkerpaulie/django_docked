FROM python:3.9-alpine3.13

LABEL maintainer="sablos@hotmail.com"

ENV PYTHONUNBUFFERED=1

COPY ./requirements.txt /requirements.txt

WORKDIR /app
EXPOSE 8000

RUN python -m venv /venv && \
    /venv/bin/pip install --upgrade pp && \
    /venv/bin/pip install -r requirements.txt && \
    adduser --disable-password --bo-create-home app

COPY ./app /app

ENV PATH="/venv/bin:$PATH"

USER app

