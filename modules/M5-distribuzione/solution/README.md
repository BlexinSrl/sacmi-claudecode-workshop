# M5 solution - Repo marketplace di riferimento

Questo albero rappresenta il **repo marketplace separato** che crei e pubblichi in M5 (Step 3-5), **non** il workspace del workshop.

Contiene solo gli artefatti distribuibili:

- `plugins/workshop-dev-kit/` - il plugin
- `.claude-plugin/marketplace.json` - l'indice del marketplace

Le customizations **sorgente** (skill, subagent, hook, schema DB) da cui il plugin è stato copiato vivono nel workspace; riferimento: `modules/M3-governance/solution/.claude/`.

> Nota: la copia sorgente => plugin è l'atto di *publish* (come pubblicare un pacchetto npm), non una duplicazione da evitare: plugin e sorgente vivono in repository diversi.

Verifica che sia valido:

```bash
claude plugin validate modules/M5-distribuzione/solution
```
