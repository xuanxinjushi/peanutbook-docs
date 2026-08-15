## This repo is the public documentation source of truth

This is the **public** documentation repo — hosted on GitHub (`xuanxinjushi/peanutbook-docs`) and built by Read the Docs / `build-site.sh` for `peanutbook.com`. Edit docs **directly here**.

The private development repo `~/peanutbook` also has a `docs/` folder, but that one is **private/internal notes only** and is not published. Do not treat it as a source to sync from — a past sync (`docs/sync-public-docs.sh` run from `~/peanutbook`, copying with `rsync --delete`) wiped this repo's homepage logo, several doc pages (`bizplan.md`, `paper.md`, `html-generation.md`, `cover-api.md`), and preview images because the private copy was stale. That script is retired; do not run it.

If `~/peanutbook`'s code changes in a way that affects these docs (new CLI flags, config keys, behavior), update the relevant page here directly — don't wait for or perform a sync.

## Building the site

```bash
bash build-site.sh          # strict mkdocs build, deploys to peanutbook.com
bash build-site.sh rtd      # strict mkdocs build, RTD-style preview
```

`mkdocs.yml` has `strict: false`, but `build-site.sh` passes `--strict`, so any broken internal link or image reference fails the build. Always run `build-site.sh` (or `mkdocs build --strict`) after editing nav or adding pages, before considering the change done.
