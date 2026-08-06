# Deploying this Campfire fork

This deployment builds the current checkout on the server and runs it with
Docker Compose. Compose replaces the old sequence of manually building,
stopping, and starting a container.

## One-time setup on the server

Install Docker Engine and the Docker Compose plugin, then confirm both are
available:

```console
$ docker version
$ docker compose version
```

Create the production storage volume. This command is idempotent, so it also
safely finds the volume named `campfire` from the previous `docker run` setup:

```console
$ docker volume create campfire
```

Create the server-only environment file and fill in its real values:

```console
$ cd once-campfire
$ cp .env.example .env
$ chmod 600 .env
$ $EDITOR .env
```

The `.env` file is intentionally ignored by Git. Keep it on the server and back
it up securely; in particular, changing `SECRET_KEY_BASE` later invalidates
existing sessions and signed data.

Start Campfire:

```console
$ docker compose up --detach --build
```

`--build` rebuilds the image from the current checkout. `--detach` leaves the
containers running in the background. The database and uploaded files live in
the external `campfire` volume and survive container replacement.

## Deploying an update

```console
$ cd once-campfire
$ git pull
$ docker compose up --detach --build
```

Compose builds the new image and replaces the running container. Campfire runs
pending database migrations during startup.

Useful operational commands:

```console
$ docker compose ps
$ docker compose logs --follow campfire
$ docker compose exec campfire bin/rails console
$ docker compose restart campfire
$ docker compose down
```

`docker compose down` removes the container and network, but not the external
`campfire` storage volume. Start it again with `docker compose up --detach`.
