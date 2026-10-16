# AssassíCirera — Docs

Project documentation for **Assassí de la Cirera**.

**Repo:** https://github.com/AssassiCirera/docs  
**Wiki (target):** https://github.com/AssassiCirera/docs/wiki

## Browse on `main`

| Doc | File |
|-----|------|
| Project context | [project-context.md](./project-context.md) |
| Requirements | [requirements.md](./requirements.md) |
| MVP | [mvp.md](./mvp.md) |
| Repositories | [repositories.md](./repositories.md) |

## GitHub Wiki

Wiki page sources live in [`wiki/`](./wiki/) (Home, Project-Context, Requirements, MVP, Repositories).

### Status / bootstrap

The org is on **GitHub Free**. Private-repo wikis are not available on Free, so this `docs` repo is **public** (product code repos stay private).

GitHub does not create the `.wiki.git` remote until the **first page** is saved in the web UI:

1. Sign in as an AssassiCirera admin.
2. Open https://github.com/AssassiCirera/docs/wiki  
3. Click **Create the first page**, save (title `Home` is fine).
4. From this repo: `./scripts/publish-wiki.sh`

That script clones `docs.wiki.git`, copies `wiki/*.md`, and pushes.
