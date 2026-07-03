# M5 solution — Repo marketplace di riferimento

Questo albero rappresenta il **repo marketplace separato** che pubblichi in M5 (Step 3–4), **non** il tuo workspace.

Contiene solo gli artefatti distribuibili:

- `plugins/claude-dev-kit/` — il bundle plugin
- `.claude-plugin/marketplace.json` — indice marketplace per Claude Code

Le customization **sorgente** (skill, agent, hook, schema DB del contesto) da cui questo bundle è stato copiato vivono nel workspace; riferimento: `modules/M3-governance/solution/.claude/`.

> Nota: la copia sorgente→plugin è l'atto di *publish* (come pubblicare un pacchetto npm), non un errore. Qui non co-esiste col sorgente: questo è un repo diverso.
