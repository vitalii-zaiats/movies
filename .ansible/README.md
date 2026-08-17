# .ansible

Deploying the stack to a host. Scaffold — it runs, but nothing here has met a
production server yet.

```bash
cd .ansible
cp inventory.example.yml inventory.yml
cp group_vars/all.example.yml group_vars/all.yml     # holds the db password
ansible-galaxy collection install -r requirements.yml

ansible-playbook site.yml                  # code + containers
ansible-playbook playbooks/migrate.yml     # schema
ansible-playbook playbooks/seed.yml        # data
```

Both `inventory.yml` and `group_vars/all.yml` are gitignored.

## Why three playbooks and not one

The compose template has **only long-running services** — no `migrate`, no
`vod-init`, no `seed`. A container starting is not a reason to touch a database.

- `site.yml` syncs the repo, renders `compose.yaml` and `.env`, and brings the
  stack up. Safe to run again, any time.
- `playbooks/migrate.yml` prepares schemas. Run it when they change.
- `playbooks/seed.yml` loads crawled episodes. Run it when there's new data.

Splitting them means a redeploy can't quietly migrate a database, and a
migration can't quietly restart your services.

## One wrinkle worth knowing

The catalogue schema goes through `exec`, the VOD one through `run --rm`:

```yaml
docker compose exec -T api alembic upgrade head
docker compose run --rm --no-deps --entrypoint vod-init vod
```

They differ because the two services behave differently on an unprepared
database. The API starts fine and simply has no tables yet, so there's a
container to exec into. The VOD service **refuses to start** without its schema
— that was deliberate — so on a fresh host there is nothing to exec into, and it
needs a throwaway container instead. That's also why `migrate.yml` restarts
`vod` at the end.

## The seeder

It isn't a compose service either. It's a job: built on the host and run against
the stack's network, reading a jsonl the resolver produced. The write direction
holds here too — the seeder registers streams with the VOD service and posts the
episodes to the API, which only ever reads that service.

`data/` is excluded from the sync: crawler output belongs to the host, not to a
deploy.

## Not done yet

Left out on purpose, to be added when there's a real target: installing Docker
itself, TLS and a real domain in front of nginx (the pinggy tunnel is a stand-in),
backups of `pgdata`/`voddata`, and a vault for `postgres_password`.
