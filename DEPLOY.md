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

### GIF picker

Create an account and a Web API app at <https://developers.giphy.com/dashboard/>.
Add `GIPHY_API_KEY=your_key` to the server's `.env`, then recreate the container
with `docker compose up --detach --build`. Set the key before using GIF search.
Chat users do not need GIPHY accounts. This is a browser API key: Campfire exposes
it to signed-in users so their browsers can call GIPHY directly.

The free beta key allows 100 API calls per hour for the whole instance. Search is
explicit (Search or Enter), and visible GIFs in history are looked up in batches.
Opening the picker loads trending GIFs; searching, loading more results, and
resolving GIFs in messages each use API calls. A quota error leaves a link to the
GIF available. Higher quotas require GIPHY's paid production approval.

Messages store the GIPHY ID/page link and title, not media files or media URLs.
Images load directly from GIPHY; removing the key leaves links in old messages.
Deleted GIFs may no longer display. The picker includes GIPHY's attribution and
uses a PG-13 content filter. Reduced-motion preferences use still previews.
The attribution images are unmodified assets from
<https://media.giphy.com/giphy-attribution-marks.zip>.

### Updating the container

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
