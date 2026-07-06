# VuFind Docker Standalone

Pacote Docker independente para subir somente o VuFind com MariaDB e Solr
externo. Esta pasta pode ser usada como raiz de um novo repositorio.

## Requisitos

- Docker Engine
- Docker Compose plugin v2
- Git
- Uma instancia Solr ja existente, acessivel pelo container do VuFind

## Configuracao

```bash
cp .env.example .env
```

Edite `.env` e configure pelo menos:

```env
SOLR_EXTERNAL_URL=http://seu-solr:8983/solr
```

Se deixar `VUFIND_SITE_URL` vazio, `vufind.sh` calcula
`http://localhost:${VUFIND_WEB_PORT}`. Preencha essa variavel apenas quando
for publicar com uma URL externa fixa.

O modulo local Oasisbr fica habilitado por padrao:

```env
VUFIND_LOCAL_MODULES=Oasisbr
```

Esse valor e passado para o Apache como `SetEnv VUFIND_LOCAL_MODULES`, para
que as rotas e configuracoes do modulo sejam carregadas nas requisicoes web.

## Subir

```bash
./vufind.sh install
```

O script clona `./vufind` automaticamente quando o diretorio ainda nao tem
um checkout valido do VuFind. Quando o checkout ja existe, `install` atualiza
o codigo com Git, constroi as imagens e inicia os servicos.

## Comandos

| Comando | Descricao |
| --- | --- |
| `./vufind.sh install` | Faz uma instalacao inicial clonando ou atualizando o VuFind configurado, construindo as imagens e iniciando o ambiente completo. |
| `./vufind.sh update` | Atualiza o codigo do VuFind com Git, reconstrui as imagens sem cache e recria o ambiente. O comando para se houver alteracoes locais no checkout `./vufind`. |
| `./vufind.sh rebuild` | Reconstrui as imagens Docker locais mantendo o codigo atual intacto, depois recria o ambiente. |
| `./vufind.sh restart` | Reinicia os containers existentes sem remover ou recriar containers. |
| `./vufind.sh start` | Inicia containers existentes. |
| `./vufind.sh stop` | Para os containers do ambiente sem remover volumes ou dados. |
| `./vufind.sh logs [args...]` | Exibe logs. Sem argumentos, acompanha os logs do VuFind e do banco. |
| `./vufind.sh health` | Verifica os endpoints do VuFind e do Solr externo. |
| `./vufind.sh shell` | Abre um shell no container do VuFind. |
| `./vufind.sh help` | Exibe a lista de comandos disponiveis e orientacoes de uso. |

## Estrutura

```text
.
├── docker-compose.yml
├── vufind.sh
├── docker/vufind/
│   ├── Dockerfile
│   ├── apache-vufind.conf
│   └── entrypoint.sh
├── .env.example
├── .dockerignore
└── .gitignore
```

Dados persistentes ficam em `volume/` e o codigo do VuFind clonado fica em
`vufind/`. Ambos estao no `.gitignore`.
# la-referencia-vufind-docker
