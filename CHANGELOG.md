# Changelog

Todas as mudanças notáveis neste projeto serão documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
e este projeto adere ao [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- VERSION file para centralizar versionamento
- CHANGELOG.md para documentar histórico de mudanças
- Enhanced .gitignore com proteções de segurança adicionais

### Changed
- Melhorias na documentação do projeto

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
