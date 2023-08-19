# traefik

Basic [traefik](https://doc.traefik.io/traefik/master/) setup. Easily enable HTTPS access to services running in separate Docker containers.
- Automatically create SSL certificates using Let's Encrypt with DNS-challenge ([link](https://doc.traefik.io/traefik/master/https/acme/)). Cloudflare is used as the default provider in this repo.
- Works well with Tailscale.

## Setup
```sh
cp .env.sample .env
cp traefik.sample.yml traefik.yml
```

## DNS
- Create Cloudflare API token from the [dashboard](https://dash.cloudflare.com/profile/api-tokens).
    - The token should have a permission to edit the DNS
    - Override the value for `CLOUDFLARE_DNS_API_TOKEN` in the `.env` file
- Add `A` record for your node
    - e.g. `server001.example.com  A  100.0.0.1`
    - Traefik dashboard will be available at this FQDN.