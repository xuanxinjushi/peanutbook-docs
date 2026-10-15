# Production server: ubuntu@2peanuts.com

Internal runbook (private `docs/`, never synced to `peanutbook-docs`). How the
production host is laid out, how to deploy each site on it, how outgoing mail
works, and where backups go. Written 2026-10-07 after the print-ordering /
PayPal Orders v2 / mail-provider changes; update it when any of this moves.

**Never put secrets in this file** -- credentials live only in each site's
`.env` on the server.

## 1. The host

- `ssh ubuntu@2peanuts.com` -- Oracle Cloud (OCI), region `us-sanjose-1`,
  aarch64, Ubuntu. One shared host for many sites (mediacms, usaaio,
  opengate, static sites, book sites, 2peanuts.com).
- `nginx-proxy` + `nginx-proxy-acme` containers own ports 80/443 and route by
  each container's `VIRTUAL_HOST` env var (TLS via Let's Encrypt,
  `LETSENCRYPT_HOST`). Proxied containers join the `mediacms-dev_default`
  docker network (declared as the external `proxy` network in compose files).
- The OCI CLI is installed and configured for the ubuntu user
  (`~/bin/oci`, `~/.oci/config`) -- used for Email Delivery (section 4).

## 2. mortgage.2peanuts.com (mmb book site)

| What | Where |
|---|---|
| Deployment dir | `~/mmb-site/` (`.env`, `docker-compose.yml`, `deploy.sh`, `data/`) |
| Container | `mmb-site-web-1`, image `peanutbook-booksite:latest`, `127.0.0.1:8002 -> 8000` |
| Book content | `~/mmb` (git checkout of henrywoo/mmb), mounted read-only at `/book` |
| Database / uploads | `data/db.sqlite3`, `data/media/` |
| Print PDFs (printorders) | `data/print_files/` -> `/app/private_print_files` (never served publicly) |
| Image source | `~/peanutbook` (`web/booksite/Dockerfile`, build context = repo root) |

The image installs `bubble` from the **prebuilt wheel** in `~/peanutbook/dist/`
(currently `peanutbook-0.1.1-cp312-cp312-linux_aarch64.whl`), not from repo
source. Changes under `web/booksite/` ship with a plain rebuild; changes to
`bubble` itself that the booksite imports need a new aarch64 wheel in `dist/`
first (see `packaging/release/`).

### Deploy

From your machine (also renders and rsyncs `book_html`, configs, covers, images):

```bash
cd ~/mmb && bubble-deploy          # web/booksite/scripts/deploy_book.sh
```

Or code-only, on the server:

```bash
cd ~/mmb-site && ./deploy.sh
```

`deploy.sh` does: `git checkout -f && git pull` in `~/mmb` (discards server-side
edits there), `git pull` in `~/peanutbook`, `docker build`, **`migrate`**
(added 2026-10-07 -- it used to skip migrations), `initialize_booksite`,
`docker compose up -d`. A changed `.env` needs
`docker compose up -d --force-recreate web` to take effect.

### Print ordering (printorders)

Deployed but **off**: `.env` has no `LULU_*` / `PAYPAL_*` keys yet, so there is
no "Order a printed copy" button and `/<lang>/print/` 404s. To turn it on
follow `docs/new-book-website.md` step 6. State as of 2026-10-07:

- Lulu API keys exist (production account -- they do not work on the Lulu
  sandbox); a credit card must be on the Lulu account before going live.
- Chinese edition files are ready: interior `~/mmb/books/book_zh_square_interior.pdf`
  (392 pages) and covers regenerated for that page count with the build's
  commit as the back-cover code (no ISBN needed for direct sales):
  `cd ~/mmb/cover/7x10 && python gen_fullcover.py --provider lulu/{paperback,hardcover} --lang zh --barcode commit:be713e6`.
- English Lulu covers in `cover/7x10/out/` are still sized for an older page
  count -- regenerate (after updating `cover_print_config.json`) before
  adding an English edition. "Validate with Lulu" refuses a mis-sized cover.
- Live Lulu prices seen for the zh edition (one copy, CA, MAIL): paperback
  $32.71 total Lulu cost, case-wrap hardcover $42.29.

## 3. 2peanuts.com (review app, Django)

Not containerized. Request path:

```
nginx-proxy --(2peanuts.com)--> ops-static-twopenuts-site-1 (nginx:alpine)
    /static/  served from ~/2peanuts.com (mounted at /usr/share/nginx/html)
    /         proxy_pass http://172.17.0.1:8000  -> host gunicorn
```

The static container's config is `~/ops/sites/2peanuts.conf`.

| What | Where |
|---|---|
| Code | `~/2peanuts.com` (git checkout of henrywoo/2peanuts.com, branch `master`) |
| Process | `gunicorn --bind 0.0.0.0:8000 --daemon config.wsgi:application` from the `usao` conda env (Python 3.10) |
| Settings | `.env` in the repo dir (django-environ); `DJANGO_SETTINGS_MODULE=config.settings.development` |
| Database | SQLite `~/2peanuts.com/db.sqlite3` |
| PayPal | **live** mode, Orders v2 (`accounts/paypal_service.py`) |

### Deploy

```bash
ssh ubuntu@2peanuts.com
cd ~/2peanuts.com
cp db.sqlite3 ~/backups/2peanuts.com/db.sqlite3.$(date +%Y%m%d-%H%M%S)
git pull --ff-only
~/miniconda3/envs/usao/bin/python manage.py migrate
kill -HUP "$(pgrep -o -f 'gunicorn --bind 0.0.0.0:8000 --daemon config.wsgi')"   # graceful reload
```

`HUP` starts fresh workers on the new code and retires the old ones without
dropping requests. If gunicorn isn't running at all (e.g. after a reboot):

```bash
cd ~/2peanuts.com && ~/miniconda3/envs/usao/bin/gunicorn --bind 0.0.0.0:8000 --daemon config.wsgi:application
```

### PayPal webhook

The live webhook (its id is `PAYPAL_WEBHOOK_ID` in `.env`) was registered for
`https://2peanuts.com/payments/paypal/webhook/`. The app serves that path and
`/billing/paypal/webhook/` with the same view; verification only uses the
webhook id, so nothing needs changing in the PayPal dashboard. An unsigned
`POST` to either path returns 401 -- that's the quick health check.

## 4. Outgoing mail: OCI Email Delivery

Both sites send through **OCI Email Delivery** as `noreply@notify.2peanuts.com`
(set up 2026-10-07). Before that, 2peanuts.com used Mailgun
(`review@mg.2peanuts.com`), which Mailgun disabled "for sending spam" -- every
2peanuts email failed with SMTP 421 from at least 2026-09-21 until the switch.

| Setting | Value |
|---|---|
| OCI email domain | `notify.2peanuts.com` (tenancy root compartment, `us-sanjose-1`) |
| Approved sender | `noreply@notify.2peanuts.com` -- the `From` address must match exactly |
| DKIM selector | `notify-sjc-20261007` (ACTIVE) |
| SMTP endpoint | `smtp.email.us-sanjose-1.oci.oraclecloud.com:587`, STARTTLS |
| SMTP login | an OCI **SMTP credential** (OCI console -> My profile -> SMTP credentials) |
| Free tier | 100 emails/day, 3,000/month |

DNS (GoDaddy, zone `2peanuts.com`) -- only the `notify` subdomain, so the main
domain's mail and SPF (`include:secureserver.net -all`) are untouched; the
apex DMARC (`p=quarantine`) also covers the subdomain and passes via SPF+DKIM:

| Type | Name | Value |
|---|---|---|
| CNAME | `notify-sjc-20261007._domainkey.notify` | `notify-sjc-20261007.notify.2peanuts.com.dkim.sjc1.oracleemaildelivery.com` |
| TXT | `notify` | `v=spf1 include:rp.oracleemaildelivery.com ~all` |

`.env` keys (same in `~/2peanuts.com/.env` and `~/mmb-site/.env`; only the
display name in `DEFAULT_FROM_EMAIL` differs):

```ini
EMAIL_HOST=smtp.email.us-sanjose-1.oci.oraclecloud.com
EMAIL_PORT=587
EMAIL_USE_TLS=True
EMAIL_HOST_USER=<OCI SMTP credential username>
EMAIL_HOST_PASSWORD=<OCI SMTP credential password>
DEFAULT_FROM_EMAIL=2Peanuts Review <noreply@notify.2peanuts.com>
```

Gotcha hit on 2026-10-07: `~/2peanuts.com/.env` still had the old Mailgun
`DEFAULT_FROM_EMAIL` line above the new one, and django-environ keeps the
**first** occurrence -- every send would have been rejected by OCI as an
unapproved sender. Keep exactly one line per key.

### Test

Prints the result only, never the credential values:

```bash
# 2peanuts.com
cd ~/2peanuts.com && ~/miniconda3/envs/usao/bin/python manage.py shell -c \
  "from django.core.mail import send_mail; print(send_mail('2peanuts mail test', 'test', None, ['wufuheng@gmail.com']))"
# mortgage.2peanuts.com
cd ~/mmb-site && docker compose exec -T web python manage.py shell -c \
  "from django.core.mail import send_mail; print(send_mail('mmb mail test', 'test', None, ['wufuheng@gmail.com']))"
```

`1` means OCI accepted it. In Gmail, "Show original" should show SPF, DKIM
and DMARC all `PASS`.

### Rotating the SMTP credential

1. OCI console -> My profile -> SMTP credentials -> generate a new one (the
   password is shown once).
2. Replace `EMAIL_HOST_USER` / `EMAIL_HOST_PASSWORD` in both `.env` files.
3. Reload: `kill -HUP` the 2peanuts gunicorn master (section 3) and
   `cd ~/mmb-site && docker compose up -d --force-recreate web`.
4. Run the test above, then delete the old credential in the console.

Check DNS / DKIM state from the server:

```bash
dig +short CNAME notify-sjc-20261007._domainkey.notify.2peanuts.com
dig +short TXT notify.2peanuts.com
T=$(grep -E '^tenancy=' ~/.oci/config | cut -d= -f2)
D=$(~/bin/oci email domain list --compartment-id "$T" --name notify.2peanuts.com --query 'data.items[0].id' --raw-output)
~/bin/oci email dkim list --email-domain-id "$D" --query 'data.items[].{name:name,state:"lifecycle-state"}'
```

## 5. Backups

Taken before every schema or config change; nothing prunes them.

| Path | What |
|---|---|
| `~/backups/2peanuts.com/db.sqlite3.<ts>` | 2peanuts DB before a migration |
| `~/backups/2peanuts.com/env.<ts>` | 2peanuts `.env` before an edit (mode 600 -- contains secrets) |
| `~/backups/mmb-site/{db.sqlite3,docker-compose.yml,deploy.sh}.<ts>` | mmb-site before a deploy-config change |

## 6. Open items (2026-10-07)

- **Rotate the OCI SMTP credential** -- the current one was printed in a
  session transcript during setup. Follow section 4's rotation steps.
- Mailgun leftovers: the `mg.2peanuts.com` DNS records (SPF
  `include:mailgun.org`, DKIM, MX) are unused and can be removed.
- Enable print ordering on mortgage.2peanuts.com (section 2).
- 2peanuts.com runs `config.settings.development` with SQLite in production.
- `cover/7x10/constant_text.py` in mmb prints the English ISBN
  (979-8-9951523-7-8) as `_ZH_BACK_ISBN`; `book_zh.md` says the Chinese
  edition is 979-8-9951523-1-6. Only matters with `--barcode isbn`
  (KDP/Ingram covers) -- confirm which is right.
