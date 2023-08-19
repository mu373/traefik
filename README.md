# traefik

Basic [traefik](https://doc.traefik.io/traefik/master/) setup. Easily enable HTTPS access to services running in separate Docker containers.
- Automatically create SSL certificates using Let's Encrypt with DNS-challenge ([link](https://doc.traefik.io/traefik/master/https/acme/)). Cloudflare is used as the default provider in this repo.
- Works well with Tailscale.

## Setup
Preparing configs
```sh
cp .env.sample .env
cp traefik.sample.yml traefik.yml
vim .env
vim traefik.yml #Edit email address for Cloudflare account
```

Preparing Docker network
```sh
# We will use network called "traefik-nw" for traefik and other containers to communicate with each other
docker network create traefik-nw 
```

## DNS
- Create Cloudflare API token from the [dashboard](https://dash.cloudflare.com/profile/api-tokens).
    - The token should have a permission to edit the DNS
    - Override the value for `CLOUDFLARE_DNS_API_TOKEN` in the `.env` file
- Add `A` record for your node
    - e.g. `server001.example.com  A  100.0.0.1`
    - Traefik dashboard will be available at this FQDN.

## Docker containers
Here is a sample `docker-compose.yml` configuration for the target container that you would like to connect through reverse proxy. In this example, 8080 port of the container will be available at your-service.example.com.

```yml
services:
  <your_service>:
    ...
    expose:
      - 8080 #The target port should be exposed
    networks:
      - traefik-nw #The target container should be in same network with the traefik
    labels:
      traefik.enable: true
      traefik.docker.network: traefik-nw
      traefik.http.routers.foobar.rule: Host(`your-service.example.com`) # your_service:8080 will be available at your-service.example.com
      traefik.http.routers.foobar.service: foobar
      traefik.http.routers.foobar.entrypoints: websecure
      traefik.http.routers.foobar.tls.certresolver: cloudflare
      traefik.http.services.foobar.loadbalancer.server.port: 8080
networks:
  traefik-nw:
    external: true
```