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
make infra-up      # start the local stack (creates .env on first run)
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
| `make infra-check` | Verifies the local stack, including database isolation |
| `make core-up` | Builds and starts service containers (core profile) on top of infra, then seeds demo data |
| `make core-down` | Stops service containers; infra keeps running |
| `make core-check` | Verifies every service container reports gRPC health `SERVING` |
| `make clean` | Removes dangling Docker images and build cache |

## Docker Desktop resources

The project targets an 8 GB laptop. Recommended limits under **Settings → Resources**:

- **Memory:** 3–4 GB. Less starves the local stack; more leaves too little for the IDE and browser.
- **Disk:** 30 GB. Run `make clean` regularly.

The infra profile idles at roughly 100–150 MB; check with `make infra-status`.

## Windows (WSL2)

- Install Docker Desktop for Windows and enable WSL integration for your Ubuntu distribution.
- Clone and work **inside the WSL filesystem** (for example `~/code/ngumbah`), not under `/mnt/c`, for speed and correct file permissions.
- Line endings are forced to LF by `.gitattributes`.
- Builds follow the host architecture (x86_64 on most Windows laptops, arm64 on Apple Silicon).
