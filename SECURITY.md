# Security Policy

## Supported Versions

The project is developed as a learning and portfolio app. Only the current
`main` branch is supported, on a best-effort basis.

## Reporting a Vulnerability

Please report security issues privately through a GitHub Security Advisory or
by email to `security@leonwestermeir.dev`. Include a clear description, steps
to reproduce, and the affected commit or tag.

## Secrets and configuration

- Never commit private keys, API tokens, credentials, or release keystores.
- Keep Android signing configuration outside version control.
- Deploy the bundled room server behind TLS, origin checks, and rate limiting.
- Treat room codes as invitation tokens, not as user authentication.
