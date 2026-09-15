# Pagamentos, auditoria e expiração

[Voltar ao README](../README.md) · [Validação em sandbox](mercado_pago_sandbox.md)

## Pagamentos

A integração com o Mercado Pago utiliza o Payment Brick no navegador e a SDK Ruby oficial no backend. O valor cobrado é obtido diretamente do serviço salvo no banco, e o endpoint valida a autenticação, a propriedade do agendamento, o estado da reserva e a existência de pagamentos anteriores antes de chamar o gateway.

O ciclo implementado atualmente é:

1. o cliente reserva um horário, criando um agendamento `pendente`;
2. o cliente é direcionado para a tela de pagamento;
3. pagamentos `approved` confirmam o agendamento e disparam o e-mail de confirmação;
4. pagamentos `pending`, como PIX ainda não compensado, mantêm o agendamento pendente até a notificação assíncrona;
5. o webhook valida a assinatura, consulta o pagamento na API e confirma a reserva quando o PIX muda para `approved`;
6. uma reserva sem cobrança expira no prazo de `PAYMENT_EXPIRATION_MINUTES` (30 minutos por padrão); a emissão de um PIX renova integralmente esse prazo e envia o mesmo instante ao Mercado Pago em `date_of_expiration`;
7. ao vencer, o sistema consulta o estado remoto: uma aprovação confirma a reserva e mantém o horário ocupado; rejeição ou cancelamento confirmados permitem a expiração local e liberam o horário;
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
