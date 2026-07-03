-- Workshop schema iniettato dal SubagentStart hook.
-- Sorgente: modules/M3-governance/solution/.claude/context/db-schema.sql
-- Marker workshop: BLEXIN-2026-M3-SCHEMA

CREATE TABLE tasks (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    title           TEXT    NOT NULL,
    description     TEXT,
    status          TEXT    NOT NULL DEFAULT 'pending',  -- pending | in_progress | done | archived
    priority        TEXT    NOT NULL DEFAULT 'normal',   -- low | normal | high | urgent
    owner_email     TEXT,
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    -- Canary: colonna inventata, usata in workshop per dimostrare l'iniezione.
    test_audit_seal TEXT
);

CREATE INDEX idx_tasks_status        ON tasks(status);
CREATE INDEX idx_tasks_owner_email   ON tasks(owner_email);
CREATE INDEX idx_tasks_priority      ON tasks(priority);
