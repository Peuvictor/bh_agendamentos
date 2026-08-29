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
- Dashboard do prestador com receita recebida e prevista, ticket médio, clientes pagantes e indicadores da agenda.
- Avaliações de serviços após o atendimento.
- Upload de avatar e fotos de serviços com Active Storage e Cloudinary.
- Notificações por e-mail processadas em segundo plano com Sidekiq e Redis.
- Expiração automática e segura de reservas e cobranças PIX abandonadas.
- Reconciliação idempotente de reembolsos totais informados pelo Mercado Pago.
- Painel administrativo para moderação de usuários e serviços.

## Pagamentos

A integração com o Mercado Pago utiliza o Payment Brick no navegador e a SDK Ruby oficial no backend. O valor cobrado é obtido diretamente do serviço salvo no banco, e o endpoint valida a autenticação, a propriedade do agendamento, o estado da reserva e a existência de pagamentos anteriores antes de chamar o gateway.

O ciclo implementado atualmente é:

1. o cliente reserva um horário, criando um agendamento `pendente`;
2. o cliente é direcionado para a tela de pagamento;
3. pagamentos `approved` confirmam o agendamento e disparam o e-mail de confirmação;
4. pagamentos `pending`, como PIX ainda não compensado, mantêm o agendamento pendente até a notificação assíncrona;
5. o webhook valida a assinatura, consulta o pagamento na API e confirma a reserva quando o PIX muda para `approved`;
6. uma reserva sem cobrança expira após 30 minutos; a emissão de um PIX renova integralmente esse prazo e envia o mesmo instante ao Mercado Pago em `date_of_expiration`;
7. ao vencer, o sistema consulta o estado remoto e só libera o horário depois de confirmar aprovação, rejeição ou cancelamento da cobrança;
8. cancelamentos e expirações preservam o registro e liberam o horário para uma nova reserva;
9. pagamentos com estado remoto `refunded` marcam pagamento e agendamento como `reembolsado`, registram `refunded_at`, liberam o horário e notificam o cliente uma única vez.

A resposta do backend mantém o status real devolvido pelo Mercado Pago. Tentativas de pagar agendamentos cancelados, passados, pertencentes a outro cliente ou com pagamento já registrado são rejeitadas.

O webhook está disponível em `POST /webhooks/mercado_pago`. Ele valida os headers `x-signature` e `x-request-id` com a chave secreta, exige um timestamp recente, consulta o pagamento na API oficial e processa reenvios sem duplicar a confirmação ou o e-mail. O banco também garante um único pagamento por agendamento e por identificador do Mercado Pago.

Cada recebimento autenticado do webhook gera um registro de auditoria com o tipo e identificador do evento, IDs de correlação, resultado do processamento, estado remoto, código HTTP, duração e uma classificação de falha quando aplicável. Requisições com assinatura inválida ou configuração ausente não são persistidas; elas produzem apenas um evento JSON estruturado nos logs. O conteúdo da requisição, assinaturas, mensagens de exceção e segredos não são registrados. O job `PurgeWebhookDeliveriesJob` remove diariamente, pela fila `maintenance`, os registros além do prazo configurado por `WEBHOOK_EVENT_RETENTION_DAYS` (90 dias por padrão; mínimo de 7).

Cobranças são criadas sob trava do agendamento, impedindo duplicidade e corrida com a expiração. A reconciliação mantém o horário reservado em caso de timeout, resposta desconhecida ou divergência de identificador, valor ou referência externa. Transições repetidas não duplicam e-mails.

O reembolso total é um estado terminal: notificações atrasadas de aprovação, processamento, cancelamento ou rejeição não revertem registros `reembolsado`. O reembolso prevalece sobre estados locais anteriores e também é reconhecido durante o job de expiração, inclusive após conflito de cancelamento remoto. Reembolsos não entram nas métricas financeiras do prestador e não bloqueiam o horário na agenda.

Nesta etapa, apenas o estado total `refunded` é reconciliado. Um pagamento `approved` com detalhe de reembolso parcial continua aprovado; solicitação de reembolso, valor devolvido e identificador da operação permanecem sob responsabilidade do Mercado Pago e não são persistidos pela aplicação.

### Expiração e operação do Sidekiq

O `sidekiq-cron` agenda `ExpireAppointmentsSweepJob` na fila `maintenance` a cada minuto. O varredor percorre as reservas pendentes vencidas em lotes de 100 e enfileira um job unitário por UUID. Cada job trava primeiro o agendamento e depois o pagamento, consulta o Mercado Pago quando existe cobrança e registra somente IDs, resultado, estado remoto e duração.

Estados remotos `pending`, `in_process` e `authorized` são cancelados no gateway antes da expiração local. Uma aprovação confirma a reserva; `cancelled` e `rejected` concluem a expiração; `refunded` registra o reembolso e libera o horário. Erros temporários ou dados divergentes levantam erro para retry e não liberam o horário. A primeira expiração ou transição para reembolso envia o respectivo e-mail específico ao cliente.

O arquivo `config/sidekiq.yml` configura o processo para consumir as filas `default` e `maintenance`. Em produção, mantenha esse arquivo no comando padrão `bundle exec sidekiq`; se a plataforma substituir a lista de filas pela linha de comando, inclua `-q default -q maintenance`.

## Tecnologias

- Ruby 3.3 e Rails 7.1
- PostgreSQL
- Redis e Sidekiq
- Devise
- Hotwire (Turbo e Stimulus)
- Tailwind CSS
- Docker e Docker Compose
- Minitest e RuboCop
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
POSTGRES_TEST_DB=bh_agendamentos_test
POSTGRES_USER=postgres
POSTGRES_PASSWORD=password
REDIS_URL=redis://redis:6379/1
MERCADO_PAGO_PUBLIC_KEY=
MERCADO_PAGO_ACCESS_TOKEN=
MERCADO_PAGO_WEBHOOK_SECRET=
PAYMENT_EXPIRATION_MINUTES=30
WEBHOOK_EVENT_RETENTION_DAYS=90
```

Integrações externas podem exigir variáveis adicionais:

- `CLOUDINARY_URL` para armazenamento de imagens;
- `MERCADO_PAGO_PUBLIC_KEY` para inicializar o Payment Brick no navegador;
- `MERCADO_PAGO_ACCESS_TOKEN` para a SDK Ruby no backend;
- `MERCADO_PAGO_WEBHOOK_SECRET` para validar a assinatura das notificações;
- `PAYMENT_EXPIRATION_MINUTES` para o prazo de reservas e PIX, em minutos; o padrão e o mínimo aceito são `30`;
- `WEBHOOK_EVENT_RETENTION_DAYS` para a retenção da auditoria de webhooks autenticados; o padrão é `90` dias e o mínimo aceito é `7`;
- `DATABASE_URL`, `REDIS_URL` e configurações de e-mail no ambiente de produção.

Nunca versione arquivos `.env`, tokens ou chaves de produção.

No Docker, `POSTGRES_DB` e `POSTGRES_TEST_DB` devem apontar para bancos diferentes. A suíte Rails prepara e limpa somente o banco de teste.

No painel do Mercado Pago, cadastre a URL HTTPS pública `https://seu-dominio/webhooks/mercado_pago` para notificações de pagamento e copie a assinatura secreta gerada para `MERCADO_PAGO_WEBHOOK_SECRET`.

### Validação no sandbox do Mercado Pago

Use a Public Key e o Access Token de teste pertencentes à mesma aplicação do Mercado Pago. O roteiro completo para configurar um staging HTTPS, validar cartão aprovado, webhook assinado e PIX pendente até a expiração está em [Validação do Mercado Pago em staging](docs/mercado_pago_sandbox.md).

No sandbox do Checkout Bricks, use cartão de teste para comprovar o fluxo aprovado. O PIX comprova emissão do QR Code, estado `pending`, prazo remoto, cancelamento por expiração e liberação segura do horário; não use um pagamento bancário real para tentar aprová-lo.

Se `MERCADO_PAGO_PUBLIC_KEY` estiver ausente ou a SDK externa não puder ser carregada, a tela exibirá uma mensagem amigável sem expor tokens ou detalhes internos.

O cenário automatizado de agendamento até o checkout roda sem navegador por padrão. Em um ambiente com Chrome instalado, utilize Selenium headless para também aguardar a renderização do Brick:

```bash
docker compose exec web sh -lc 'SYSTEM_TEST_DRIVER=selenium bin/rails test test/system/appointments_test.rb'
```

Para usar um navegador portátil sem instalação administrativa, informe também `CHROME_BINARY` e `CHROMEDRIVER_PATH` apontando para os executáveis compatíveis.

O ambiente local precisa ter Chrome ou Chromium disponível para esse modo. As credenciais de teste ficam apenas no arquivo `.env` local; elas não são versionadas. Sem essas credenciais, a suíte ainda valida estruturalmente a chegada ao checkout usando `rack_test`, mas não realiza uma cobrança sandbox.

## Qualidade e testes

O projeto utiliza Minitest 5, compatível com a versão atual do Rails. Os testes podem ser executados dentro do container:

```bash
docker compose exec web bin/rails test
```

A suíte cobre os principais fluxos de cadastro seguro, serviços, agendamentos, pagamentos, cancelamentos, mailers, dashboard e administração. Estado validado atualmente:

```text
109 testes, 435 asserções, 0 falhas e 0 erros
```

O cenário de sistema do agendamento até a tela de checkout também está validado com `1 teste e 5 asserções`.

O código Ruby, Rails e Minitest é analisado pelo RuboCop:

```bash
docker compose exec web bundle exec rubocop
```

A configuração mantém uma linha de base em `.rubocop_todo.yml` para o código legado. Novos arquivos e trechos fora dessa linha de base já precisam atender às regras de Ruby, Rails e Minitest.

Também é possível verificar o carregamento completo da aplicação com:

```bash
docker compose exec web bin/rails zeitwerk:check
```

Para auditar as dependências JavaScript:

```bash
docker compose exec web npm audit
```

Estado validado atualmente: `0 vulnerabilities`.

O GitHub Actions executa essas quatro verificações em cada pull request e em
alterações enviadas para a branch `main`.

## Próximas evoluções

- Executar o runbook no staging e registrar a validação real do sandbox do Mercado Pago.
- Integrar os eventos estruturados do webhook a alertas e painéis operacionais do ambiente de produção.

## Autor

Pedro Victor Oliveira Guimarães

Desenvolvedor Ruby on Rails — Belo Horizonte, MG
