# VuFind Docker

Docker package for running VuFind with MariaDB and an external Solr
instance. 

## Requirements

- Docker Engine
- Docker Compose plugin v2
- Git
- An existing Solr instance that is reachable from the VuFind container

## Configuration

```bash
cp .env.example .env
```

Edit `.env` and configure at least:

```env
SOLR_EXTERNAL_URL=http://your-solr:8983/solr
```

When `VUFIND_SITE_URL` is empty, `vufind.sh` derives
`http://localhost:${VUFIND_WEB_PORT}`. Set this variable only when publishing
VuFind with a fixed external URL.

The local Oasisbr module is enabled by default:

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

## Commands

| Command | Description |
| --- | --- |
| `./vufind.sh install` | Performs the initial installation by cloning or updating the configured VuFind checkout, building the images, and starting the full environment. |
| `./vufind.sh update` | Updates the VuFind code with Git, rebuilds images without cache, and recreates the environment. The command stops if local changes exist in the `./vufind` checkout. |
| `./vufind.sh rebuild` | Rebuilds the local Docker images while keeping the current code intact, then recreates the environment. |
| `./vufind.sh restart` | Restarts existing containers without removing or recreating them. |
| `./vufind.sh start` | Starts existing containers. |
| `./vufind.sh stop` | Stops the environment containers without removing volumes or data. |
| `./vufind.sh logs [args...]` | Shows logs. With no arguments, follows the VuFind and database logs. |
| `./vufind.sh health` | Checks the VuFind, MariaDB, and external Solr endpoints. |
| `./vufind.sh shell` | Opens a shell in the VuFind container. |
| `./vufind.sh help` | Shows the available commands and usage guidance. |

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
