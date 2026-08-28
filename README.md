# 💈 BH Agendamentos

Marketplace de agendamentos para profissionais independentes e negócios locais de Belo Horizonte. Clientes podem encontrar serviços, escolher um horário e acompanhar suas reservas; prestadores gerenciam serviços, agenda e indicadores.

## Funcionalidades

- Cadastro e autenticação com Devise, incluindo perfis de cliente, prestador e administrador.
- Vitrine pública de serviços com busca por texto e filtro por bairros de Belo Horizonte.
- Cadastro e gerenciamento de serviços por prestadores.
- Agendamento com cálculo de duração, validação de horários passados e prevenção de conflitos de agenda.
- Área de agendamentos para clientes e prestadores.
- Dashboard do prestador com métricas de agenda e faturamento.
- Avaliações de serviços após o atendimento.
- Upload de avatar e fotos de serviços com Active Storage e Cloudinary.
- Notificações por e-mail processadas em segundo plano com Sidekiq e Redis.
- Painel administrativo para moderação de usuários e serviços.

## Pagamentos

A integração com o Mercado Pago está em evolução. O checkout e o endpoint de pagamento já fazem parte do código, mas o fluxo ainda está sendo consolidado antes do uso em produção — incluindo persistência, confirmação assíncrona e cobertura de testes.

## Tecnologias

- Ruby 3.3 e Rails 7.1
- PostgreSQL
- Redis e Sidekiq
- Devise
- Hotwire (Turbo e Stimulus)
- Tailwind CSS
- Docker e Docker Compose
- Cloudinary / Active Storage
- Mercado Pago

## Pré-requisitos

Para executar localmente com o ambiente recomendado, instale:

- Docker Desktop ou Docker Engine com Docker Compose v2;
- Git.

Não é necessário instalar Ruby, PostgreSQL ou Redis na máquina quando o Docker for utilizado.

## Execução local

Clone o repositório e entre na pasta do projeto:

```bash
git clone https://github.com/Peuvictor/bh_agendamentos.git
cd bh_agendamentos
```

Crie o arquivo de variáveis locais a partir do exemplo:

```bash
cp .env.example .env
```

Suba os serviços web, PostgreSQL, Redis e Sidekiq:

```bash
docker compose up --build -d
```

Prepare o banco de dados e, opcionalmente, crie dados de demonstração:

```bash
docker compose exec web bin/rails db:prepare
docker compose exec web bin/rails db:seed
```

O sistema estará disponível em [http://localhost:3000](http://localhost:3000).

Para acompanhar os logs:

```bash
docker compose logs -f web sidekiq
```

Para encerrar os containers:

```bash
docker compose down
```

## Variáveis de ambiente

As variáveis básicas de desenvolvimento estão em `.env.example`:

```dotenv
POSTGRES_DB=bh_agendamentos_development
POSTGRES_USER=postgres
POSTGRES_PASSWORD=password
REDIS_URL=redis://redis:6379/1
```

Integrações externas podem exigir variáveis adicionais:

- `CLOUDINARY_URL` para armazenamento de imagens;
- `MERCADO_PAGO_ACCESS_TOKEN` para o backend de pagamentos;
- chave pública do Mercado Pago para o checkout no navegador;
- `DATABASE_URL`, `REDIS_URL` e configurações de e-mail no ambiente de produção.

Nunca versione arquivos `.env`, tokens ou chaves de produção.

## Qualidade e testes

O projeto utiliza Minitest. Os testes podem ser executados dentro do container:

```bash
docker compose exec web bin/rails test
```

O conjunto de testes está sendo atualizado junto das evoluções recentes de autenticação, agenda e pagamentos.

## Próximas evoluções

- Finalizar o fluxo de pagamentos do Mercado Pago, incluindo webhooks e idempotência persistente.
- Ampliar a cobertura de testes de modelos, integrações e fluxos de autorização.
- Consolidar métricas e relatórios para prestadores.
- Adicionar CI para validar testes, carregamento da aplicação e qualidade do código a cada alteração.

## Autor

Pedro Victor Oliveira Guimarães

Desenvolvedor Ruby on Rails — Belo Horizonte, MG
