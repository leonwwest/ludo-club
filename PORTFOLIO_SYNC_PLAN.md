# Public portfolio sync plan

This public repository is intended to demonstrate the development history and current architecture of Board Magic / Ludo Club without publishing deployment secrets or private infrastructure credentials.

## Publication rules

- Keep real API keys, service-role keys, database credentials, signing keys, keystores, `.env` files, and private deployment values out of Git.
- Publish only placeholder/example configuration where useful.
- Preserve meaningful development history where it can be safely reviewed.
- Prefer code and documentation that demonstrate architecture, testing, release hardening, online multiplayer, and Flutter platform work.
- Never copy private runtime credentials merely to make the public build immediately deployable.

## Current private-to-public gaps identified

The private repository has moved beyond the current public snapshot, including the Board Magic product migration, newer Flutter/platform qualification, secure runtime configuration, account/online infrastructure, release hardening, and expanded documentation.

Before the historical migration is completed, the private history must be checked for credentials that may have existed in older commits even if they are absent from the current tree.

## Configuration boundary

Runtime values such as Supabase URLs/publishable keys, room-server endpoints, Sentry DSNs, AgentStack gateway values, database URLs, HMAC secrets, Android signing properties, and similar deployment-specific settings must be supplied through environment/build/deployment configuration rather than committed real values.
