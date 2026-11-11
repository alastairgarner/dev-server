# Dev server

Shared local MongoDB, Redis and an SQS-compatible queue, reusable on
multiple development machines.
Requires Docker Engine and Docker Compose v2 or later.

| Service | Local endpoint | RAM limit | Internal limit |
| --- | --- | --- | --- |
| MongoDB 8.0.32 | 127.0.0.1:27017 | 2 GiB | 512 MiB WiredTiger cache |
| Redis 7.4.12 | 127.0.0.1:6379 | 512 MiB | 256 MiB, noeviction |
| ElasticMQ native 1.7.1 (SQS) | 127.0.0.1:9324 | 256 MiB | in-memory messages |

Swap is disabled for all containers. Limits include more than application
caches; monitor OOM events under heavy loads. Redis rejects memory-growing
writes at maxmemory rather than silently evicting queues or other data.

Ports bind only to localhost. Services have no authentication: this is trusted,
local development infrastructure, not a production or public deployment.

## Fresh machine

```sh
cp .env.example .env
docker volume create dev-server-mongo-data
docker volume create dev-server-mongo-config
docker volume create dev-server-redis-data
docker compose up -d --wait
docker compose exec mongo mongosh --quiet --eval \
  'rs.initiate({_id:"rs0",members:[{_id:0,host:"127.0.0.1:27017"}]})'
```

Replica-set initialization is only needed for a fresh data volume. Wait for
primary election before connecting:
```sh
docker compose exec mongo mongosh --quiet --eval 'db.hello().isWritablePrimary'
```

Connections from host applications:
- MongoDB: `mongodb://127.0.0.1:27017/?replicaSet=rs0`
- Redis: `redis://127.0.0.1:6379`
- SQS: endpoint `http://127.0.0.1:9324` (see [SQS queue](#sqs-queue))

The replica set advertises localhost: intended for host applications, not
clients inside other containers or on remote machines.

## Existing machine

The ignored `.env` maps this stack to the pre-existing MongoDB data/config
and Redis data volumes. Do not overwrite it with the example on this machine.
Save that mapping with machine recovery notes; Git does not back up database data.

The original MongoDB version and replica-set configuration are retained.
Redis retains its existing RDB snapshot policy (not AOF); it is not durable
against every crash. Back up data separately.

## SQS queue

ElasticMQ serves the SQS API for local worker testing. `elasticmq.conf`
declares the standard queue `sn-worker-local` (visibility timeout 300 s, the
sn-web worker default), so it exists on every start. Queue URL as the API
reports it:

```
http://127.0.0.1:9324/000000000000/sn-worker-local
```

Any region and dummy credentials work, e.g.
`AWS_ENDPOINT_URL_SQS=http://127.0.0.1:9324` with `AWS_ACCESS_KEY_ID=x AWS_SECRET_ACCESS_KEY=x`.

Not durable: messages live in memory and are lost when the container
restarts or is recreated. The queue itself is recreated empty. Treat
in-flight messages as disposable.

To bring up only this service, leaving MongoDB and Redis untouched:
```sh
docker compose up -d --wait sqs
```

Smoke test (send, receive, delete):
```sh
Q=http://127.0.0.1:9324/000000000000/sn-worker-local
curl -s "$Q?Action=SendMessage&MessageBody=smoke"
R=$(curl -s "$Q?Action=ReceiveMessage"); echo "$R" | grep '<Body>'
H=$(echo "$R" | sed -n 's:.*<ReceiptHandle>\(.*\)</ReceiptHandle>.*:\1:p')
curl -s "$Q?Action=DeleteMessage" --data-urlencode "ReceiptHandle=$H"
curl -s "$Q?Action=GetQueueAttributes&AttributeName.1=All" | grep -A1 'ApproximateNumberOfMessages'
```
Expect `<Body>smoke</Body>`, then both message counts `0`.

## Operations

```sh
docker compose ps
docker compose logs --tail=100
docker compose up -d --wait
docker compose stop
```

Docker's system service must be enabled at boot. All containers use
`restart: unless-stopped`, so they return after a reboot unless explicitly
stopped. Following a manual stop, run `docker compose up -d --wait`.
No additional systemd unit is needed. Health checks report health; they
do not automatically restart an unhealthy but still-running process.

External volumes survive `docker compose down -v`. Do not delete them or
run volume-pruning commands casually. Never run two MongoDB containers with
the same data volume.

## Ownership

This repository owns shared services. Application agents should connect to
them, not create replacements. Repository instructions guide agents but
are not security enforcement for agents with access to the Docker socket.
