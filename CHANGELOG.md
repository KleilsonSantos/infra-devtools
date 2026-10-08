# Changelog

Todas as mudanças notáveis neste projeto serão documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
e este projeto adere ao [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- PR Validation Checks UI names: English, drop `Opção 3` / `Teste N` ordinals; required contexts → `Protocol gate`, `Issue link`, `Version SSOT`, `PR base policy` (#115)
- Issue-first delivery rule for agents (`.cursor/rules/issue-first-delivery.mdc`) + delivery-automation note (#117)

## [1.3.7] - 2026-10-08

### Fixed
- `e2e-staged.sh` Darwin memory gate: count inactive+purgeable pages (was aborting Colima waves with ~80MB "free") (#125)
- Prefer `.venv/bin` for stage0 pytest/bandit when present (#125)
- Port preflight `stop-foreign` also applies when our container is up but host ports are held by a foreign container; force-recreate when ports were not published (#125)
- `health-check.sh` PROJECT_ROOT path typo (extra `)`) broke final E2E health steps (#125)

## [1.3.6] - 2026-10-07

### Added
- Shared host-port preflight (`lib-port-preflight.sh` + `check-port-conflicts.sh`) and Python mirror for pytest (#122)
- Serial compose bring-up (`compose-up-serial.sh`); Makefile `check-ports` / `check-compose-ports` / `check-ports-start` (#122)
- E2E staged orchestrator + adherence evidence scripts (`e2e-staged.sh`, `e2e-adherence-evidence.sh`) (#122)

### Changed
- `make up` / `force-recreate` use serial preflight→up→verify; integration/docker test targets gate on ports (#122)
- Test SSOT is `scripts/run-tests.sh` / `make test-*`; remove deprecated `run-tests-professional.sh` (#122)

### Fixed
- Broader `__pycache__` / `*.pyc` ignore (was leaking under `src/`) (#122)
- `pytest.ini` `pythonpath = .` so `from src…` imports work in unit CI (#122)

## [1.3.5] - 2026-10-07

### Fixed
- Delivery watch no longer reddens healthy PRs (repo-wide inventory contagion / self-check loop) (#110)

### Changed
- Delivery watch: drop `pull_request` trigger; hard-fail only on schedule/dispatch for ADR-0001 base-policy; check failures report-only (#110)

## [1.3.4] - 2026-10-01

### Changed
- Delivery watch reports failing check runs; triggers on sandbox + PR Validation completion (#87)

### Fixed
- Issue-link bot bypass: quote `dependabot[bot]` (bash character-class bug); refresh labels via API (#87)
- Create repo labels `ci:no-issue-required` / `ci:allow-main-base` (#87)

## [1.3.3] - 2026-10-01

### Changed
- Pin Compose infra/admin images to immutable tags; document pin policy (#73)
- Replace stub Prometheus alert exprs with real PromQL / blackbox probes (#74)
- Switch MongoDB exporter to `percona/mongodb_exporter:0.49.0` (#73)
- Add blackbox `http_2xx` module + Keycloak probe job (#74)

### Fixed
- Infra alerts no longer always-fire (`1 == bool 1`) (#74)

## [1.3.2] - 2026-10-01

### Added
- Local preflight hooks (`.githooks` + `scripts/preflight.sh`) (#66)
- Delivery watch workflow + `scripts/delivery-watch.sh` (inventory open PRs; fail on main←non-sandbox) (#78)
- PR base policy CI job + `scripts/check-pr-base-policy.sh` (#78)
- Dependabot config targeting `sandbox` (#78)

### Changed
- Replace dead Husky path with Git-native `core.hooksPath=.githooks` (#66)
- Portainer Compose profile `tools` + pin `portainer-ce:2.21.4` (#71)
- Scheduled security workflow: Bandit fail-closed only (#70)
- SECURITY.md honesty + `.gitignore` `*.p12`/`*.pfx`/`backups/` (#72)
- Branch protection on `main`/`sandbox` (#69)

### Fixed
- `health-check.sh` no longer hardcodes MySQL root password (#75)

## [1.3.1] - 2026-10-01

### Added
- Vault local config tree (`vault/config/vault-config.hcl`), init/seed scripts, and `docs/guides/vault-local.md` (#51)

### Changed
- Pin `hashicorp/vault` to `1.18.4`; README Vault section matches committed tree

## [1.3.0] - 2026-10-01

### Added
- ADR-0001: sandbox branching strategy (`docs/adr/`)
- ADR-0002: canonical SemVer tags + GitHub Releases (`docs/guides/releases.md`)
- Guides: `docs/guides/git-workflow.md`, `docs/guides/delivery-verification.md`, `docs/guides/releases.md`
- Permanent `sandbox` integration branch; PR validation on `sandbox` and `main`
- Issue templates, PR template, fail-closed PR CI, issue-link gate (#52/#53 / PR #54)
- `scripts/check-semver-alignment.sh` (anti-drift; bootstrap-safe)
- CI job `version-ssot` (VERSION = package.json = sonar)

### Changed
- Delivery flow: Issue → sandbox → promote → main (ADR-0001)
- `VERSION` confirmed SSOT; `package.json` realigned from drift `1.4.0` → `1.2.9` then release bump to `1.3.0`
- `version.sh` does not auto-tag on bump; tag only on `main` after merge
- `check-version-alignment.sh` deprecated
- CONTRIBUTING / HELP / branch-protection docs aligned with two-stage delivery

### Fixed
- Bandit B501 nosec for local self-signed helpers in web service integration tests

## [1.2.9] - 2025-11-06

### Added
- Comprehensive testing framework com pytest
- Integration com testcontainers para testes isolados
- OWASP Dependency-Check automation script
- GitHub Actions para CI/CD automatizado
- Environment validation via custom action
- Suporte a múltiplos marcadores de teste (unit, integration, network, docker, etc.)

### Changed
- Enhanced Python quality tools configuration
- Updated CI/CD pipeline com environment validation
- Reorganização da estrutura de testes (unit/integration)
- Melhorias no Makefile com novos comandos

### Fixed
- Docker Compose service health checks
- Environment variable management no CI
- Test execution no pipeline

## [1.2.0] - 2025-10-XX

### Added
- Configuração completa de quality tools Python (Black, Flake8, Pylint, MyPy, Bandit)
- ESLint e Prettier para JavaScript/TypeScript
- SonarQube integration para análise de código
- Comprehensive Makefile (282 linhas) com comandos para todos os workflows
- npm scripts para operações Docker e quality checks

### Changed
- Estrutura de diretórios organizada por responsabilidade
- Documentação expandida no README.md (874 linhas)

## [1.1.0] - 2025-09-XX

### Added
- Prometheus para coleta de métricas
- Grafana para visualização de dashboards
- Alertmanager para gerenciamento de alertas
- Exporters para todos os bancos de dados (PostgreSQL, MongoDB, MySQL, Redis, RabbitMQ)
- Blackbox Exporter para monitoramento de endpoints
- cAdvisor para métricas de containers
- Node Exporter para métricas do sistema

### Changed
- docker-compose.yml expandido para incluir stack de monitoring completo
- Configuração de redes isoladas para segurança

## [1.0.0] - 2025-08-XX

### Added
- Infrastructure básica com Docker Compose
- PostgreSQL + pgAdmin
- MongoDB + Mongo Express
- MySQL + phpMyAdmin
- Redis + RedisInsight
- RabbitMQ com Management UI
- Vault para gerenciamento de secrets
- Keycloak para identity provider
- SonarQube para análise de qualidade
- Portainer para gerenciamento de containers
- Scripts de setup e validação
- Documentação inicial (README.md)

### Features
- 24 serviços orquestrados
- Rede isolada para comunicação interna
- Volumes persistentes para todos os serviços
- Environment variables management
- Multi-database support out-of-the-box

---

## Convenções de Commit

Este projeto segue [Conventional Commits](https://www.conventionalcommits.org/):

- **feat**: Nova funcionalidade
- **fix**: Correção de bug
- **docs**: Mudanças na documentação
- **style**: Formatação (não afeta código)
- **refactor**: Refatoração de código
- **perf**: Melhorias de performance
- **test**: Adição/modificação de testes
- **chore**: Manutenção/tarefas auxiliares
- **ci**: Mudanças no CI/CD

## Links

- [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
- [Semantic Versioning](https://semver.org/spec/v2.0.0.html)
- [Conventional Commits](https://www.conventionalcommits.org/)
