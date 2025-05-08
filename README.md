# 🚀 Infraestrutura Padrão para Desenvolvimento

![Docker](https://img.shields.io/badge/Docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white)
![Makefile](https://img.shields.io/badge/Makefile-%23F7DF1E.svg?style=for-the-badge&logo=gnu&logoColor=black)
![SonarQube](https://img.shields.io/badge/SonarQube-%2300B4AB.svg?style=for-the-badge&logo=sonarqube&logoColor=white)
![Portainer](https://img.shields.io/badge/Portainer-%230072CE.svg?style=for-the-badge&logo=portainer&logoColor=white)
![Mongo Express](https://img.shields.io/badge/Mongo%20Express-%2347A248.svg?style=for-the-badge&logo=mongodb&logoColor=white)
![pgAdmin](https://img.shields.io/badge/pgAdmin-%23336791.svg?style=for-the-badge&logo=postgresql&logoColor=white)
![phpMyAdmin](https://img.shields.io/badge/phpMyAdmin-%2347A248.svg?style=for-the-badge&logo=mysql&logoColor=white)
![RedisInsight](https://img.shields.io/badge/RedisInsight-%23DC382D.svg?style=for-the-badge&logo=redis&logoColor=white)
![Prometheus](https://img.shields.io/badge/Prometheus-%23E6522C.svg?style=for-the-badge&logo=prometheus&logoColor=white)
![Grafana](https://img.shields.io/badge/Grafana-%23F46800.svg?style=for-the-badge&logo=grafana&logoColor=white)
![cAdvisor](https://img.shields.io/badge/cAdvisor-%234285F4.svg?style=for-the-badge&logo=google-cloud&logoColor=white)
![Node Exporter](https://img.shields.io/badge/Node%20Exporter-%2300BFFF.svg?style=for-the-badge&logo=linux&logoColor=white)
![MongoDB Exporter](https://img.shields.io/badge/MongoDB%20Exporter-%2347A248.svg?style=for-the-badge&logo=mongodb&logoColor=white)
![Postgres Exporter](https://img.shields.io/badge/Postgres%20Exporter-%23336791.svg?style=for-the-badge&logo=postgresql&logoColor=white)
![MySQL Exporter](https://img.shields.io/badge/MySQL%20Exporter-%2347A248.svg?style=for-the-badge&logo=mysql&logoColor=white)
![Redis Exporter](https://img.shields.io/badge/Redis%20Exporter-%23DC382D.svg?style=for-the-badge&logo=redis&logoColor=white)

> ⚠️ **Este projeto está 🚀 _(Em Desenvolvimento 🚧)_**
>  
> Algumas funcionalidades podem estar incompletas ou sujeitas a alterações. Contribuições são bem-vindas! 🛠️

## 🌟 **Por que este projeto é importante?**

Desenvolver aplicações modernas exige uma infraestrutura que seja **rápida, confiável e fácil de gerenciar**. Este projeto foi criado para resolver os desafios enfrentados por desenvolvedores ao configurar ambientes de desenvolvimento, como:

- **Redução de tempo de configuração:** Com o uso de Docker Compose, você pode iniciar todos os serviços essenciais com um único comando.
- **Padronização:** Uma infraestrutura consistente para todos os membros da equipe, eliminando problemas de "funciona na minha máquina".
- **Monitoramento e qualidade:** Ferramentas como Prometheus, Grafana e SonarQube ajudam a monitorar métricas e manter a qualidade do código.
- **Escalabilidade:** Pronto para crescer junto com o seu projeto, seja ele um MVP ou uma aplicação em produção.

Se você é um desenvolvedor que busca **otimizar seu fluxo de trabalho**, este projeto é para você! 🚀

## ✨ **Destaques do Projeto**

- **Configuração simplificada:** Todos os serviços essenciais (bancos de dados, monitoramento, análise de código) estão prontos para uso com Docker Compose.
- **Ferramentas de monitoramento:** Prometheus, Grafana e cAdvisor para métricas e dashboards.
- **Interfaces gráficas:** Portainer, pgAdmin, phpMyAdmin e RedisInsight para facilitar a administração de serviços.
- **Automação:** Um `Makefile` com comandos práticos para gerenciar containers e tarefas comuns.
- **Segurança:** Verificação de dependências com OWASP Dependency-Check.
- **Flexibilidade:** Suporte para múltiplos bancos de dados (PostgreSQL, MySQL, MongoDB) e cache distribuído com Redis.

## 💡 **Como este projeto pode ajudar você?**

1. **Economize tempo:** Não perca horas configurando serviços manualmente. Com este projeto, você pode iniciar tudo com um único comando.
2. **Aprenda boas práticas:** Explore como configurar e integrar ferramentas amplamente utilizadas no mercado.
3. **Melhore a colaboração:** Garanta que todos os membros da equipe tenham o mesmo ambiente de desenvolvimento.
4. **Monitore e otimize:** Use ferramentas de monitoramento para identificar gargalos e melhorar o desempenho da sua aplicação.

## ✅ **Concluído**

Esta seção destaca os passos que já foram implementados e estão funcionando na infraestrutura.

- ✅ **Containerização de Serviços:** Todos os serviços essenciais foram empacotados em containers Docker, garantindo isolamento e portabilidade.
- ✅ **Orquestração com Docker Compose:** A configuração e o gerenciamento dos múltiplos containers são definidos e orquestrados através do Docker Compose, simplificando a inicialização e o desligamento da infraestrutura.
- ✅ **Análise de Qualidade de Código:** Integração do SonarQube para realizar análise estática de código, auxiliando na manutenção da qualidade e segurança das aplicações.
- ✅ **Interface de Gerenciamento de Containers:** Implementação do Portainer como uma interface gráfica para facilitar a visualização e o gerenciamento dos containers Docker.
- ✅ **Interface para MongoDB:** Disponibilização do Mongo Express como uma ferramenta web para interagir e administrar bancos de dados MongoDB.
- ✅ **Interface para PostgreSQL:** Integração do pgAdmin para fornecer uma interface gráfica completa para a administração de bancos de dados PostgreSQL.
- ✅ **Interface para MySQL:** Adição do phpMyAdmin para oferecer uma interface web para a gestão de bancos de dados MySQL.
- ✅ **Interface para Redis:** Implementação do RedisInsight para fornecer uma interface visual para monitorar e interagir com o servidor Redis.
- ✅ **Monitoramento de Métricas:** Configuração do Prometheus para coletar métricas de diversos serviços da infraestrutura, permitindo o acompanhamento do desempenho.
- ✅ **Visualização de Dashboards:** Implementação do Grafana para criar dashboards personalizados a partir das métricas do Prometheus, facilitando a análise e a identificação de gargalos ou problemas.
- ✅ **Monitoramento de Recursos de Containers:** Integração do cAdvisor para coletar e expor métricas de uso de recursos (CPU, memória, rede, disco) dos containers em execução.
- ✅ **Exportadores de Métricas:** Configuração de exportadores para MongoDB, PostgreSQL, MySQL, Redis e Node Exporter para coleta de métricas detalhadas.
- ✅ **Serviço de Banco de Dados PostgreSQL:** Um serviço de banco de dados relacional PostgreSQL pronto para ser utilizado pelas aplicações.
- ✅ **Serviço de Banco de Dados MongoDB:** Um serviço de banco de dados NoSQL MongoDB disponível para armazenamento de dados flexível.
- ✅ **Serviço de Banco de Dados MySQL:** Um serviço de banco de dados relacional MySQL configurado e pronto para uso.
- ✅ **Serviço de Cache Distribuído:** Implementação do Redis como um sistema de cache de alta performance para otimizar a velocidade das aplicações.
- ✅ **Configuração via Arquivo `.env`:** Utilização de um arquivo `.env` para gerenciar as variáveis de ambiente de forma centralizada e segura.
- ✅ **Automação de Tarefas Comuns:** Criação de um `Makefile` com comandos simplificados para executar tarefas como iniciar, parar e visualizar logs dos serviços.
- ✅ **Verificação de Segurança de Dependências:** Implementação de um script utilizando OWASP Dependency-Check para identificar possíveis vulnerabilidades nas dependências dos projetos.
- ✅ **Documentação Detalhada:** Elaboração de um `README.md` abrangente, explicando a finalidade, os serviços incluídos e como utilizar a infraestrutura.

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
| 🖥️ **Node Exporter**    | `9100`      | *Acesso interno (para métricas do sistema)*   |
| 📦 **MongoDB Exporter** | `9216`      | *Acesso interno (para métricas do MongoDB)*   |
| 🐘 **Postgres Exporter**| `9187`      | *Acesso interno (para métricas do PostgreSQL)*|
| 🐬 **MySQL Exporter**   | `9104`      | *Acesso interno (para métricas do MySQL)*     |
| 📦 **Redis Exporter**   | `9121`      | *Acesso interno (para métricas do Redis)*     |
## 🌍 Environment Configuration

Este projeto utiliza um arquivo `.env` para armazenar variáveis de ambiente. Certifique-se de definir corretamente os valores no seu ambiente local antes de executar os comandos abaixo.

## 📦 Arquivos Importantes
- **ENV_FILE**: `.env`
- **Docker Compose** utiliza este arquivo para configurar os serviços automaticamente.

## 🚀 Comandos Principais

Este projeto oferece comandos práticos para gerenciar a infraestrutura e os serviços. Você pode executá-los utilizando o `Makefile` ou os scripts definidos no `package.json` com `npm run`. Escolha a abordagem que preferir.

### 🔹 Inicializar e Gerenciar Containers
| Comando                     | Descrição                                                                 | Comando Alternativo (npm)         |
|-----------------------------|---------------------------------------------------------------------------|-----------------------------------|
| `make up`                   | Inicia todos os containers definidos na variável `SERVICES`.             | `npm run start`                   |
| `make down`                 | Para todos os containers, mantendo os volumes.                           | `npm run stop`                    |
| `make rebuild`              | Para, faz build e reinicia todos os containers definidos.                | `npm run rebuild`                 |

### 🔹 Logs e Status
| Comando                     | Descrição                                                                 | Comando Alternativo (npm)         |
|-----------------------------|---------------------------------------------------------------------------|-----------------------------------|
| `make logs`                 | Exibe os logs em tempo real de todos os serviços.                        | `npm run logs`                    |
| `make ps`                   | Lista os containers ativos.                                              | Não disponível via npm            |

### 🔹 Build e Rebuild
| Comando                     | Descrição                                                                 | Comando Alternativo (npm)         |
|-----------------------------|---------------------------------------------------------------------------|-----------------------------------|
| `make build`                | Faz o build dos containers.                                              | `npm run build`                   |
| `make rebuild`              | Reconstrói os containers forçando a recriação.                           | `npm run rebuild`                 |

### 🔹 Verificação de Dependências
| Comando                               | Descrição                                                                 | Comando Alternativo (npm)         |
|---------------------------------------|---------------------------------------------------------------------------|-----------------------------------|
| `make check-deps`                     | Executa o OWASP Dependency-Check com configurações padrão.               | `npm run check-deps`              |
| `make check-deps-path path=<caminho>` | Executa o Dependency-Check em um caminho específico.                     | `npm run check-deps-path`         |

### 🔹 Lint e Formatação (npm apenas)
| Comando                     | Descrição                                                                 |
|-----------------------------|---------------------------------------------------------------------------|
| `npm run lint`              | Executa o ESLint para verificar problemas no código.                     |
| `npm run format`            | Executa o Prettier para formatar o código automaticamente.               |


> 💡 **Nota:** Certifique-se de configurar corretamente o arquivo `.env` antes de executar os comandos acima.

### Como escolher entre `make` e `npm run`?
- Use `make` se você já está familiarizado com o Makefile e prefere gerenciar os serviços diretamente.
- Use `npm run` se você prefere centralizar os comandos no `package.json` e utilizar o mesmo fluxo de trabalho para desenvolvimento e automação.

Ambas as abordagens são equivalentes e oferecem flexibilidade para atender às suas preferências.

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
| `node-exporter`      | `9100` | Exportador de métricas do sistema operacional |
| `cadvisor`           | `8080` | Monitoramento de containers Docker            |
| `mongodb-exporter`   | `9216` | Exportador de métricas do MongoDB             |
| `postgres-exporter`  | `9187` | Exportador de métricas do PostgreSQL          |
| `mysql-exporter`     | `9104` | Exportador de métricas do MySQL               |
| `redis-exporter`     | `9121` | Exportador de métricas do Redis               |

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

  - job_name: 'mysql-exporter'
    static_configs:
      - targets: ['mysql-exporter:9104']

  - job_name: 'redis-exporter'
    static_configs:
      - targets: ['redis-exporter:9121']
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

## 🔮 **Passos futuros**

- [ ] 📦 Adicionar suporte ao Redis e RabbitMQ.
- [ ] 📊 Configurar dashboards personalizados no Grafana.
- [ ] 🔒 Implementar autenticação para os serviços expostos.
- [ ] 🧪 Criar testes automatizados para validar a infraestrutura.
- [ ] **🛠️ Refatorar build scripts para utilizar `npm`:**
    - [ ] ⚙️ Analisar os comandos atuais do `Makefile` e identificar os equivalentes em scripts `npm`.
    - [ ] 📝 Criar scripts no `package.json` (por exemplo, `build`, `start`, `test`, `lint`).
    - [ ] 🔄 Substituir as chamadas ao `make` por comandos `npm run <script>`.
    - [ ] 📄 Documentar a nova estrutura de build com `npm`.
- [ ] **✨ Otimizar o fluxo de desenvolvimento com `npm`:**
    - [ ] ➕ Adicionar ferramentas de desenvolvimento como linters (`eslint`, `prettier`) e formatadores como dependências de desenvolvimento (`devDependencies`).
    - [ ] ⚙️ Configurar scripts `npm` para executar essas ferramentas (por exemplo, `lint`, `format`).
    - [ ] 🎣 Integrar essas verificações no ciclo de desenvolvimento (por exemplo, através de hooks de commit com `husky`).
- [ ] **🚢 Considerar o uso de ferramentas de build mais avançadas baseadas em Node.js:**
    - [ ] 🧐 Avaliar ferramentas como `webpack` ou `parcel` para o empacotamento de assets (se aplicável ao projeto).
    - [ ] 🧩 Investigar o uso de task runners como `gulp` ou `grunt` (se o projeto se beneficiar de fluxos de trabalho mais complexos).

> 💡 **Nota:** Este projeto está em constante desenvolvimento. Algumas funcionalidades podem estar incompletas ou sujeitas a alterações. Contribuições são sempre bem-vindas! 🛠️

## 🌍 **Junte-se a nós**

Se você acredita que este projeto pode ajudar outros desenvolvedores, compartilhe com sua rede! Vamos construir juntos uma infraestrutura de desenvolvimento mais eficiente e acessível para todos. 🚀✨

## 🛠️ **Contribua e faça parte da comunidade**

Este projeto é **open-source** e está em constante evolução. Sua contribuição é muito bem-vinda! Seja você um desenvolvedor experiente ou iniciante, há várias formas de ajudar:

- 💬 **Sugira melhorias:** Abra uma issue com suas ideias.
- 🛠️ **Contribua com código:** Envie pull requests com novas funcionalidades ou correções.
- ⭐ **Dê uma estrela no GitHub:** Isso ajuda o projeto a alcançar mais desenvolvedores.

## 🙏 **Agradecimentos**

Agradecemos por utilizar este projeto! Caso tenha sugestões, melhorias ou encontre algum problema, sinta-se à vontade para abrir uma issue ou enviar um pull request. Sua contribuição é muito bem-vinda! 💡

## ✍️ **Autor**

Desenvolvido com ❤️ por **Kleilson Santos**.

- 🌐 [GitHub](https://github.com/KleilsonSantos) - KleilsonSantos
- 💼 [LinkedIn](https://www.linkedin.com/in/KleilsonSantos) - KleilsonSantos