# VuFind Docker

Docker package for running VuFind with MariaDB and an external Solr
instance. 

## Requirements

- Docker Engine
- Docker Compose plugin v2
- Git
- To run Solr in a container: PHP and Composer

## Configuration

```bash
cp .env.example .env
```

Edit `.env`. If you are using an external Solr, configure at least:

```env
SOLR_EXTERNAL_URL=http://your-solr:8983/solr
```
Otherwise, Solr is started in a container.

When `VUFIND_SITE_URL` is empty, `vufind.sh` derives
`http://localhost:${VUFIND_WEB_PORT}`. Set this variable only when publishing
VuFind with a fixed external URL.

Optionally add the Oasisbr module:

```env
VUFIND_LOCAL_MODULES=Oasisbr
```

This value is passed to Apache as `SetEnv VUFIND_LOCAL_MODULES` so the module
routes and configuration are loaded by web requests.

Use `VUFIND_SESSION_NAME` to define a unique session cookie name for this
installation. This avoids conflicts with old cookies from other VuFind
installations published under the same domain or path.

## Start

```bash
./vufind.sh install
```

The script automatically clones `./vufind` when the directory does not already
contain a valid VuFind checkout. When the checkout already exists, `install`
updates the code with Git, builds the images, and starts the services.

## Import a MARC file

```bash
sudo cp ./test.xml volume/import/
docker exec vufind-web ./import-marc.sh local/docker/import/test.xml
```

## Commands

| Command | Description |
| --- | --- |
| `./vufind.sh install` | Performs the initial installation by cloning or updating the configured VuFind checkout, building the images, and starting the full environment. |
| `./vufind.sh update` | Updates the VuFind code with Git, rebuilds images without cache, and recreates the environment. The command stops if local changes exist in the `./vufind` checkout. |
| `./vufind.sh rebuild` | Rebuilds the local Docker images while keeping the current code intact, then recreates the environment. |
| `./vufind.sh restart` | Restarts existing containers without removing or recreating them. |
| `./vufind.sh start` | Starts existing containers. |
| `./vufind.sh stop` | Stop the environment containers without removing volumes or data. |
| `./vufind.sh up` | Create containers if needed, and start them. |
| `./vufind.sh down` | Stop and remove containers without removing volumes or data. |
| `./vufind.sh cleanup` | Stop containers and remove containers and volumes, delete vufind - This removes all data ! |
| `./vufind.sh logs [args...]` | Shows logs. With no arguments, follows the VuFind and database logs. |
| `./vufind.sh log` | Follows VuFind's application log (`/usr/local/vufind/local/docker/logs/vufind.log`) in the web container. |
| `./vufind.sh health` | Checks the VuFind, MariaDB, and external Solr endpoints. |
| `./vufind.sh shell` | Opens a shell in the VuFind container. |
| `./vufind.sh index-alpha` | Rebuild the index for alphabetical browse. |
| `./vufind.sh help` | Shows the available commands and usage guidance. |

## Swagger UI

If the Swagger documentation UI is needed, run the installer from the VuFind
directory inside the `vufind-web` container:

```bash
./vufind.sh shell
vendor/bin/phing installswaggerui
```

## Structure

```text
.
├── docker-compose.yml
├── vufind.sh
├── docker/vufind/
│   ├── Dockerfile
│   ├── apache-vufind.conf
│   └── entrypoint.sh
├── .env.example
├── .dockerignore
└── .gitignore
```

Persistent data is stored in `volume/`, and the cloned VuFind code is stored in
`vufind/`. Both paths are listed in `.gitignore`.
