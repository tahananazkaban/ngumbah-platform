# ngumbah-platform

Entry point for **Ngumbah**, a multi-tenant laundry POS SaaS built as a set of microservices.

This repository holds the bootstrap script that clones every service repository and the architecture overview.

Planning and phase specs are tracked as issues in this repository.

## Status

Phase 0 (foundation) — in progress.

## First-time setup

```sh
git clone https://github.com/tahananazkaban/ngumbah-platform
cd ngumbah-platform
make doctor        # check tools; prints install commands for anything missing
make bootstrap     # clone the other repositories next to this one
make infra-up      # start Floci, Postgres and Valkey (creates .env on first run)
make infra-check   # verify everything is healthy
```

All repositories live side by side in one plain folder:

```
ngumbah/
├── ngumbah-platform/
├── ngumbah-contracts/
├── ngumbah-tenant-svc/
└── ...
```

## Commands

Run `make help` for the full list.

| Command | What it does |
|---|---|
| `make doctor` | Checks required tools and Docker memory; never installs anything |
| `make bootstrap` | Clones repositories listed in `repos.txt`; skips existing ones and ones not on GitHub yet |
| `make pull-all` | Fast-forwards `main` in every cloned repository; skips repositories with uncommitted changes |
| `make infra-up` | Starts the `infra` profile and waits for health checks |
| `make infra-down` | Stops infrastructure, keeps data |
| `make infra-reset` | Stops infrastructure and deletes its volumes after typing `yes` (`FORCE=1` skips the prompt) |
| `make infra-status` | Shows containers, health and memory usage |
| `make infra-check` | Verifies Floci, S3, Postgres, database isolation and Valkey |
| `make clean` | Removes dangling Docker images and build cache |

## Infrastructure

| Service | Image | Host port | Notes |
|---|---|---|---|
| Floci | `floci/floci:2.3.0` | 4566 | Local AWS emulator; hybrid storage; Docker socket mounted for Lambda |
| Postgres | `postgres:17.11-alpine3.24` | 5432 | One server, one database and role per service |
| Valkey | `valkey/valkey:8.1.10-alpine3.24` | 6379 | Redis-compatible; append-only persistence |

Ports and credentials come from `.env` (copied from `.env.example` on first run). Change ports there if they clash with something already running.

### Database per service

On first start Postgres creates, for each name in `NGUMBAH_SERVICES`, a database `<name>_db` owned by a login role `<name>_svc`. `CONNECT` is revoked from `PUBLIC`, so a service role can only reach its own database. `make infra-check` proves this by connecting each role to its own database and checking that cross-database connections are refused.

The init script only runs on an empty data volume. After changing `NGUMBAH_SERVICES` or the passwords, run `make infra-reset` and `make infra-up`.

### Using the AWS CLI with Floci

```sh
set -a; . ./.env; set +a
aws --endpoint-url "$AWS_ENDPOINT_URL" s3 ls
```

## Docker Desktop resources

The project targets an 8 GB laptop. Recommended limits under **Settings → Resources**:

- **Memory:** 3–4 GB. Less starves Floci's Lambda containers; more leaves too little for the IDE and browser.
- **Disk:** 30 GB. Run `make clean` regularly.

The infra profile idles at roughly 100–150 MB; check with `make infra-status`.

## Windows (WSL2)

- Install Docker Desktop for Windows and enable WSL integration for your Ubuntu distribution.
- Clone and work **inside the WSL filesystem** (for example `~/code/ngumbah`), not under `/mnt/c`, for speed and correct file permissions.
- Line endings are forced to LF by `.gitattributes`.
- Builds follow the host architecture (x86_64 on most Windows laptops, arm64 on Apple Silicon).
