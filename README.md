# Peanutbook documentation

Public documentation for **Peanutbook** — a Markdown-based format for writing books.

- Format spec & guides: https://peanutbook.readthedocs.io/
- Build toolchain: `pip install peanutbook`

This repository contains **Markdown docs only** — no Python source. The toolchain source is distributed as encrypted wheels on PyPI.

## Edit workflow

Docs are authored in the private `peanutbook` development tree, then synced here:

```bash
/path/to/peanutbook/docs/sync-public-docs.sh /path/to/peanutbook-docs
```

Do not add `.py` files to this repository.
