# traefik

Basic [traefik](https://doc.traefik.io/traefik/master/) setup. Easily enable HTTPS access to services running in separate Docker containers.
- Automatically create SSL certificates using Let's Encrypt with DNS-challenge ([link](https://doc.traefik.io/traefik/master/https/acme/)). Cloudflare is used as the default provider in this repo.
- Discover Docker routes through [wollomatic/socket-proxy](https://github.com/wollomatic/socket-proxy), restricted by HTTP method and API path. Traefik does not receive the Docker socket directly.
- Works well with Tailscale.

## Setup
Preparing configs
```sh
cp .env.sample .env
cp traefik.sample.yml traefik.yml
cp dynamic.sample.yml dynamic.yml
vim .env
vim traefik.yml #Edit email address for Cloudflare account
vim dynamic.yml #Configure dynamic routes (optional)
```

Preparing Docker network
```sh
# We will use network called "traefik-nw" for traefik and other containers to communicate with each other
docker network create traefik-nw 
```

Set `DOCKER_GID` in `.env` when the Docker socket group differs from the default
GID `124`. You can find the host value with `stat -c '%g' /var/run/docker.sock`.

## DNS
- Create Cloudflare API token from the [dashboard](https://dash.cloudflare.com/profile/api-tokens).
    - The token should have a permission to edit the DNS
    - Override the value for `CLOUDFLARE_DNS_API_TOKEN` in the `.env` file
- Add `A` record for your node
    - e.g. `server001.example.com  A  100.0.0.1`
    - You can even use Tailscale IP address here. The contents will only be available when you are connected to Tailscale.
    - Traefik dashboard will be available at this FQDN.
- Add `CNAME` record(s) for your target service(s)
    - e.g. `your-service-1.example.com  CNAME  server001.example.com`

## Docker containers
Here is a sample `docker-compose.yml` configuration for the target container that you would like to connect through reverse proxy. In this example, 8080 port of the container will be available at `your-service-1.example.com`.

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
      traefik.http.routers.foobar.rule: Host(`your-service-1.example.com`) # your_service:8080 will be available at your-service-1.example.com
      traefik.http.routers.foobar.service: foobar
      traefik.http.routers.foobar.entrypoints: websecure
      traefik.http.routers.foobar.tls.certresolver: cloudflare
      traefik.http.services.foobar.loadbalancer.server.port: 8080
networks:
  traefik-nw:
    external: true
```

## Dynamic Configuration (Host Services)
If you need to expose services running on the host machine (outside Docker containers), you can use the `dynamic.yml` file. This is useful for reverse proxying to services that aren't containerized.

Example configuration in `dynamic.yml`:
```yml
http:
  routers:
    my-app:
      rule: "Host(`foobar.example.com`)"
      service: my-app-service
      entryPoints:
        - websecure
      tls:
        certResolver: cloudflare

  services:
    my-app-service:
      loadBalancer:
        servers:
          - url: "http://host.docker.internal:8031"
```

In this example, requests to `foobar.example.com` will be routed to a service running on the host machine at port 8031. The special DNS name `host.docker.internal` resolves to the host machine from within Docker containers.

**Note:** Make sure to add the appropriate DNS records in Cloudflare for any domains configured in `dynamic.yml`.
```
