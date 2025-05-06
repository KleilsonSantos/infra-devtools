# 🚀 Infraestrutura Padrão para Desenvolvimento

![Docker](https://img.shields.io/badge/Docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white)
![Makefile](https://img.shields.io/badge/Makefile-%23F7DF1E.svg?style=for-the-badge&logo=gnu&logoColor=black)
![SonarQube](https://img.shields.io/badge/SonarQube-%2300B4AB.svg?style=for-the-badge&logo=sonarqube&logoColor=white)
![Portainer](https://img.shields.io/badge/Portainer-%230072CE.svg?style=for-the-badge&logo=portainer&logoColor=white)
![Mongo Express](https://img.shields.io/badge/Mongo%20Express-%2347A248.svg?style=for-the-badge&logo=mongodb&logoColor=white)
![pgAdmin](https://img.shields.io/badge/pgAdmin-%23336791.svg?style=for-the-badge&logo=postgresql&logoColor=white)
![Prometheus](https://img.shields.io/badge/Prometheus-%23E6522C.svg?style=for-the-badge&logo=prometheus&logoColor=white)
![Grafana](https://img.shields.io/badge/Grafana-%23F46800.svg?style=for-the-badge&logo=grafana&logoColor=white)

> ⚠️ **Este projeto está 🚀 _(Em Desenvolvimento 🚧)_**
>  
> Algumas funcionalidades podem estar incompletas ou sujeitas a alterações. Contribuições são bem-vindas! 🛠️

Este projeto contém os principais serviços úteis para qualquer backend ou frontend, prontos para serem utilizados com Docker Compose. 🚢

---

## ✅ **Serviços incluídos**

| Serviço                | Porta       | Acesso                                         |
|------------------------|-------------|------------------------------------------------|
| 🛠 **SonarQube**        | `9000`      | [http://localhost:9000](http://localhost:9000) |
| 🐳 **Portainer**        | `9001`      | [http://localhost:9001](http://localhost:9001) |
| 🌐 **Mongo Express**    | `8081`      | [http://localhost:8081](http://localhost:8081) |
| 🖥️ **pgAdmin**          | `8088`      | [http://localhost:8088](http://localhost:8088) |
| 🧰 **phpMyAdmin**       | `8082`      | [http://localhost:8082](http://localhost:8082) |
| 🧠 **RedisInsight**     | `8083`      | [http://localhost:8083](http://localhost:8083) |
| 📈 **Prometheus**       | `9090`      | [http://localhost:9090](http://localhost:9090) |
| 📊 **Grafana**          | `3001`      | [http://localhost:3001](http://localhost:3001) |
| 🐾 **cAdvisor**         | `8080`      | [http://localhost:8080](http://localhost:8080) |
| 🐘 **PostgreSQL**       | `5432`      | *Acesso interno (via pgAdmin ou app)*         |
| 🍃 **MongoDB**          | `27017`     | *Acesso interno (via Mongo Express ou app)*   |
| 🐬 **MySQL**            | `3306`      | *Acesso interno (via phpMyAdmin ou app)*      |
| 📦 **Redis**            | `6379`      | *Acesso interno (via RedisInsight ou app)*    |

---
## 🌍 Environment Configuration

Este projeto utiliza um arquivo `.env` para armazenar variáveis de ambiente. Certifique-se de definir corretamente os valores no seu ambiente local antes de executar os comandos abaixo.

## 📦 Arquivos Importantes
- **ENV_FILE**: `.env`
- **Docker Compose** utiliza este arquivo para configurar os serviços automaticamente.

## 🚀 Comandos Principais

### 🔹 Inicializar e Gerenciar Containers
| Comando | Descrição |
|---------|-----------|
| `DOCKER_COMPOSE_UP` | Inicia os containers em segundo plano |
| `DOCKER_COMPOSE_UP_FORCE_RECREATE` | Reinicia os containers forçando a recriação |
| `DOCKER_COMPOSE_DOWN` | Para todos os containers, preservando volumes |
| `DOCKER_COMPOSE_LOGS` | Exibe os logs de execução dos serviços |
| `DOCKER_COMPOSE_BUILD` | Faz a build dos containers |

### 🔹 Execução e Debug
| Comando | Descrição |
|---------|-----------|
| `DOCKER_COMPOSE_RUN` | Executa um comando dentro de um container |
| `DOCKER_COMPOSE_EXEC` | Acessa um container em execução |
| `DOCKER_COMPOSE_PULL` | Atualiza as imagens dos containers |

## 📦 Lista de Serviços Disponíveis
Os seguintes serviços podem ser iniciados via Docker Compose:

## 🌐 Prometheus Configuration

Este projeto utiliza **Prometheus** para monitoramento e coleta de métricas. A configuração define os intervalos de coleta e os serviços que serão monitorados.

### 🔄 Configuração Global
| Configuração | Descrição |
|-------------|-----------|
| `scrape_interval: 15s` | Intervalo de coleta de métricas (a cada 15 segundos) |
| `evaluation_interval: 15s` | Intervalo para avaliação de regras |

## 📊 Alvos de Monitoramento
Os seguintes serviços estão configurados para serem **scrapeados** pelo Prometheus:

### 🔹 Serviços Configurados
| Job Name | Porta | Descrição |
|----------|-------|-----------|
| `prometheus` | `9090` | Monitoramento do próprio Prometheus |
| `node-exporter` | `9100` | Exportador de métricas do sistema operacional |
| `cadvisor` | `8080` | Monitoramento de containers Docker |
| `mongodb-exporter` | `9216` | Exportador de métricas do MongoDB |
| `postgres-exporter` | `9187` | Exportador de métricas do PostgreSQL |

## ⚙️ Exemplo de Configuração
Aqui está um exemplo do trecho YAML utilizado para definir os alvos de monitoramento:

```yaml
scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']

  - job_name: 'cadvisor'
    static_configs:
      - targets: ['cadvisor:8080']
  
  - job_name: 'mongodb-exporter'
    static_configs:
      - targets: ['mongo:9216']

  - job_name: 'postgres-exporter'
    static_configs:
      - targets: ['postgres:9187']
```
> 💡 **Nota:** Certifique-se de que os serviços listados estão rodando corretamente e acessíveis pelas portas configuradas para uma coleta eficiente de métricas.

## 🧱 **Como subir a infraestrutura**

Execute o comando abaixo para iniciar todos os serviços:

```bash
make up
```

Para derrubar os serviços:

```bash
make down
```

Para verificar os logs:

```bash
make logs
```

---
## 🔍 OWASP Dependency-Check

Este projeto inclui um **script de verificação de dependências** utilizando [OWASP Dependency-Check](https://owasp.org/www-project-dependency-check/), que identifica vulnerabilidades em bibliotecas e pacotes do projeto.

## ⚙️ Configuração

O script analisa o diretório do projeto e gera relatórios detalhados sobre possíveis vulnerabilidades.

### 📂 Estrutura de Diretórios
- **PROJECT_PATH**: Caminho do projeto analisado (padrão: diretório atual).
- **REPORT_PATH**: Caminho onde os relatórios de análise serão armazenados.



## 🔍 **Verificar dependências de segurança**

Utilize o OWASP Dependency Check para verificar vulnerabilidades nas dependências do projeto:

### 🚀 Como Executar

Para rodar a verificação de dependências, execute o seguintes comandos no terminal:

```bash
make check-deps
```

Para verificar um caminho específico:

```bash
make check-deps-path path=/seu/caminho
```

Os relatórios serão gerados na pasta `reports/`:

- 📁 **Relatório HTML:** `reports/index.html`

---

## 📂 **Estrutura do Projeto**

```plaintext
.env                 # Variáveis de ambiente para os serviços
docker-compose.yml   # Configuração do Docker Compose
Makefile             # Comandos úteis para automação
prometheus.yml       # Configuração do Prometheus
scripts/             # Scripts auxiliares
  └── run-dependency-check.sh
reports/             # Relatórios gerados pelo OWASP Dependency Check
```

---

## 🔮 **Passos futuros**

- [ ] 📦 Adicionar suporte ao Redis e RabbitMQ.
- [ ] 📊 Configurar dashboards personalizados no Grafana.
- [ ] 🔒 Implementar autenticação para os serviços expostos.
- [ ] 🧪 Criar testes automatizados para validar a infraestrutura.

---

## 🙏 **Agradecimentos**

Agradecemos por utilizar este projeto! Caso tenha sugestões, melhorias ou encontre algum problema, sinta-se à vontade para abrir uma issue ou enviar um pull request. Sua contribuição é muito bem-vinda! 💡

---

## ✍️ **Autor**

Desenvolvido com ❤️ por **Kleilson Santos**.

- 🌐 [GitHub](https://github.com/KleilsonSantos) - KleilsonSantos
- 💼 [LinkedIn](https://www.linkedin.com/in/KleilsonSantos) - KleilsonSantos

---

> 💡 Aberto a sugestões e melhorias! 🚀✨