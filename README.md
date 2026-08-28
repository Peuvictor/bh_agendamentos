# 💈 BH Agendamentos

Marketplace de agendamentos para profissionais independentes e negócios locais de Belo Horizonte. Clientes podem encontrar serviços, escolher um horário e acompanhar suas reservas; prestadores gerenciam serviços, agenda e indicadores.

## Funcionalidades

- Cadastro e autenticação com Devise, incluindo perfis de cliente, prestador e administrador, com proteção contra criação pública de contas administrativas.
- Vitrine pública de serviços com busca por texto e filtro por bairros de Belo Horizonte.
- Cadastro e gerenciamento de serviços por prestadores.
- Agendamento inicialmente pendente, com cálculo de duração, validação de horários passados e prevenção de conflitos de agenda.
- Confirmação condicionada à aprovação do pagamento, sem permitir alteração manual de status pelo cliente.
- Cancelamento lógico, preservando o histórico do agendamento e do pagamento enquanto libera o horário na agenda.
- Área de agendamentos para clientes e prestadores.
- Dashboard do prestador com métricas de agenda e faturamento.
- Avaliações de serviços após o atendimento.
- Upload de avatar e fotos de serviços com Active Storage e Cloudinary.
- Notificações por e-mail processadas em segundo plano com Sidekiq e Redis.
- Painel administrativo para moderação de usuários e serviços.

## Pagamentos

A integração com o Mercado Pago utiliza o Payment Brick no navegador e a SDK Ruby oficial no backend. O valor cobrado é obtido diretamente do serviço salvo no banco, e o endpoint valida a autenticação, a propriedade do agendamento, o estado da reserva e a existência de pagamentos anteriores antes de chamar o gateway.

O ciclo implementado atualmente é:

1. o cliente reserva um horário, criando um agendamento `pendente`;
2. o cliente é direcionado para a tela de pagamento;
3. pagamentos `approved` confirmam o agendamento e disparam o e-mail de confirmação;
4. pagamentos `pending`, como PIX ainda não compensado, mantêm o agendamento pendente;
5. cancelamentos preservam o registro e liberam o horário para uma nova reserva.

A resposta do backend mantém o status real devolvido pelo Mercado Pago. Tentativas de pagar agendamentos cancelados, passados, pertencentes a outro cliente ou com pagamento já registrado são rejeitadas.

A integração ainda está em evolução. Antes do uso em produção, é necessário implementar o webhook para atualizar pagamentos assíncronos, tratar expiração de reservas e PIX, fortalecer a idempotência contra chamadas concorrentes e validar o fluxo completo no ambiente de testes do Mercado Pago.

## Tecnologias

- Ruby 3.3 e Rails 7.1
- PostgreSQL
- Redis e Sidekiq
- Devise
- Hotwire (Turbo e Stimulus)
- Tailwind CSS
- Docker e Docker Compose
- Cloudinary / Active Storage
- Mercado Pago Payment Brick, SDK JavaScript e SDK Ruby oficial

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
- `MERCADO_PAGO_ACCESS_TOKEN` para a SDK Ruby no backend;
- chave pública do Mercado Pago para inicializar o Payment Brick no navegador;
- `DATABASE_URL`, `REDIS_URL` e configurações de e-mail no ambiente de produção.

Nunca versione arquivos `.env`, tokens ou chaves de produção.

## Qualidade e testes

O projeto utiliza Minitest 5, compatível com a versão atual do Rails. Os testes podem ser executados dentro do container:

```bash
docker compose exec web bin/rails test
```

A suíte cobre os principais fluxos de cadastro seguro, serviços, agendamentos, pagamentos, cancelamentos, mailers, dashboard e administração. Estado validado atualmente:

```text
40 testes, 97 asserções, 0 falhas e 0 erros
```

Também é possível verificar o carregamento completo da aplicação com:

```bash
docker compose exec web bin/rails zeitwerk:check
```

## Próximas evoluções

- Finalizar o fluxo assíncrono do Mercado Pago com webhooks, expiração de reservas e idempotência persistente.
- Ampliar a cobertura do gateway com testes de sistema no navegador e validação no sandbox do Mercado Pago.
- Consolidar métricas e relatórios para prestadores.
- Adicionar CI para validar testes, carregamento da aplicação e qualidade do código a cada alteração.

## Autor

Pedro Victor Oliveira Guimarães

Desenvolvedor Ruby on Rails — Belo Horizonte, MG
