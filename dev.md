# Developer notes on peanutbook-docs

Internal guide for maintaining the public docs repo. End users should read the published site, not this file.

## Published sites (same Markdown, two hosts)

| Host | URL |
|------|-----|
| Custom domain | https://peanutbook.com/ |
| Read the Docs | https://peanutbook.readthedocs.io/en/latest/ |

Both are built from this repository (`docs/`, `mkdocs.yml`).

## `site_url` (automatic per target)

`mkdocs.yml` uses:

```yaml
site_url: !ENV [READTHEDOCS_CANONICAL_URL, 'https://peanutbook.com/']
```

- **Read the Docs** sets `READTHEDOCS_CANONICAL_URL` on every build, so links and metadata use `readthedocs.io`.
- **Local `./build-site.sh`** leaves that unset; default is `https://peanutbook.com/`.

No separate config file for each host.

## Update peanutbook.com (server)

On the machine that serves `peanutbook.com`:

```bash
cd ~/peanutbook-docs
./build-site.sh          # or: ./build-site.sh deploy
```

This runs `mkdocs build` and rsyncs to `~/peanutbook.com/` (nginx Docker volume).

Preview RTD-style output locally (not deployed):

```bash
./build-site.sh rtd      # writes site-rtd/
./build-site.sh both     # deploy peanutbook.com + build RTD preview
```

## Update readthedocs.io

Project: https://app.readthedocs.org/projects/peanutbook/  
Repo: https://github.com/xuanxinjushi/peanutbook-docs

**Yes, building from the RTD UI still works.** Any build on Read the Docs (UI "Build version", git webhook, or API) runs MkDocs with `READTHEDOCS_CANONICAL_URL` set. You do not need a different `mkdocs.yml` for UI vs push builds.

Typical flow:

1. Edit `docs/` (or sync from private `peanutbook` tree; see below).
2. Commit and push to GitHub.
3. RTD rebuilds `latest` automatically, **or** open [peanutbook builds](https://app.readthedocs.org/projects/peanutbook/builds/) and trigger a build manually.

Config file: `.readthedocs.yaml` (MkDocs, Python 3.12, `docs/requirements.txt`).

## Sync from private peanutbook tree

Docs are authored in the private `peanutbook` development tree, then copied here:

```bash
/path/to/peanutbook/docs/sync-public-docs.sh /path/to/peanutbook-docs
```

After sync:

1. `git push` updates Read the Docs.
2. `./build-site.sh` on the server updates peanutbook.com.

## Google Analytics

Configured in `mkdocs.yml` under `extra.analytics` (`G-NPTR4NLLEQ`). Included on every page at build time for **both** hosts unless you add RTD-specific overrides later.

## Repo rules

- Markdown docs only; no `.py` source in this repo.
- `strict: false` in `mkdocs.yml` for RTD; local `build-site.sh` uses `--strict`.
- Do not add `dev.md` to `nav` in `mkdocs.yml` (not user-facing).
