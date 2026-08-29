# Validação do Mercado Pago em staging

Este runbook valida o Payment Brick, a API de pagamentos, os webhooks assinados e a expiração automática contra o sandbox real do Mercado Pago. Ele deve ser executado em um staging HTTPS isolado; não faz parte da suíte automática nem do CI.

O sandbox do Checkout Bricks permite simular aprovação com cartão de teste. Para PIX, a validação esperada é a criação da cobrança pendente, a exibição do QR Code e a expiração segura — não uma transferência bancária real.

Referências oficiais:

- [Realizar compra de teste com Checkout Bricks](https://www.mercadopago.com.br/developers/pt/docs/checkout-bricks/integration-test/test-payment-flow)
- [Integrar PIX no Payment Brick](https://www.mercadopago.com.br/developers/pt/docs/checkout-bricks/payment-brick/payment-submission/pix)
- [Configurar e validar Webhooks](https://www.mercadopago.com.br/developers/pt/docs/your-integrations/notifications/webhooks)

## Segurança

- Use somente Public Key e Access Token de **teste**, pertencentes à mesma aplicação Mercado Pago.
- Armazene credenciais e assinatura secreta apenas no gerenciador de segredos do staging.
- Nunca copie para tickets, commits ou evidências: credenciais, `x-signature`, dados completos do cartão, payload do pagador, QR Code ou código PIX.
- Registre identificadores de agendamento e pagamento apenas parcialmente, por exemplo `…a1b2c3`.
- Use um cliente exclusivo do sistema para sandbox, com e-mail controlado e diferente do e-mail da conta vendedora do Mercado Pago.

## Pré-requisitos

- [ ] Staging executando o commit que será validado, com `/up` respondendo HTTP 200.
- [ ] Migrações aplicadas no PostgreSQL do staging.
- [ ] Redis disponível e Sidekiq consumindo as filas `default` e `maintenance`.
- [ ] `MERCADO_PAGO_PUBLIC_KEY` e `MERCADO_PAGO_ACCESS_TOKEN` de teste configurados.
- [ ] `PAYMENT_EXPIRATION_MINUTES=30`.
- [ ] Um serviço de baixo valor e dois horários futuros identificados como `SANDBOX-AAAA-MM-DD`.
- [ ] Um cliente exclusivo para a execução, sem reutilizar a conta vendedora.

## Configurar o webhook

1. Em **Suas integrações**, abra a mesma aplicação que forneceu as credenciais de teste.
2. Em **Webhooks**, configure como URL de teste:

   ```text
   https://<host-do-staging>/webhooks/mercado_pago
   ```

3. Habilite o evento de criação e atualização de pagamentos e salve.
4. Copie a assinatura secreta gerada para `MERCADO_PAGO_WEBHOOK_SECRET` no gerenciador de segredos do staging.
5. Reinicie os processos web e worker e confirme novamente `/up` e o consumo das duas filas.

Não use uma URL de produção com credenciais de teste. Se o painel oferecer um simulador, deixe o teste assinado para depois da primeira cobrança, quando haverá um identificador de pagamento real para consulta.

## Cenário 1 — cartão aprovado

1. Entre no staging como o cliente de sandbox e crie um agendamento no primeiro horário reservado para o teste.
2. Confirme que a tela apresenta o valor do serviço e que o Payment Brick termina de carregar.
3. Selecione cartão e use os dados de teste publicados na documentação oficial. Use `APRO` como nome do titular para simular aprovação.
4. Envie o pagamento uma única vez e confirme na interface a mensagem de pagamento aprovado.
5. Aguarde a entrega real do webhook. Depois, use o simulador do painel com o mesmo identificador para validar também um reenvio assinado e idempotente.
6. Confira no banco e nos logs, sem copiar payloads sensíveis:
   - pagamento `aprovado`, com o valor exato do serviço e `expires_at` vazio;
   - agendamento `confirmado`, com `expires_at` vazio;
   - exatamente um e-mail de confirmação;
   - webhook HTTP 200 no painel;
   - `WebhookDelivery` autenticado com resultado `approved` ou `already_processed` e estado remoto `approved`;
   - nenhum e-mail ou transição duplicada após o reenvio.

É aceitável existir uma primeira auditoria `not_found` se a notificação chegar antes do commit do pagamento local. Nesse caso, uma entrega posterior precisa terminar em HTTP 200 e reconciliar o registro correto.

## Cenário 2 — PIX pendente e expiração

1. Crie outro agendamento no segundo horário reservado para o teste.
2. Selecione PIX e envie a cobrança uma única vez.
3. Confirme a exibição do QR Code e do campo copia-e-cola, mas não capture nem armazene seus conteúdos.
4. Confira imediatamente:
   - resposta e estado remoto `pending`;
   - pagamento e agendamento locais `pendente`;
   - mesmo `expires_at` nos dois registros, aproximadamente 30 minutos após a emissão;
   - `date_of_expiration` remoto compatível com esse instante;
   - webhook pendente, quando entregue, respondido com HTTP 200.
5. Não pague o código. Aguarde o horário de expiração e até cinco minutos adicionais para o cron, enfileiramento e retry normal do Sidekiq.
6. Confira ao final:
   - cobrança remota `cancelled`;
   - pagamento local `cancelado`, com `expired_at` preenchido;
   - agendamento local `cancelado`, com o mesmo motivo de expiração;
   - horário novamente disponível para reserva;
   - exatamente um e-mail de expiração;
   - execução do job na fila `maintenance` sem token, QR Code ou payload sensível nos logs.

## Consulta operacional

Use o console do staging e informe o UUID do agendamento sem colocá-lo em histórico compartilhado:

```ruby
appointment = Appointment.includes(:payment).find("UUID_DO_AGENDAMENTO")
payment = appointment.payment

{
  appointment_status: appointment.status,
  appointment_expires_at: appointment.expires_at,
  appointment_expired_at: appointment.expired_at,
  payment_status: payment&.status,
  payment_expires_at: payment&.expires_at,
  payment_expired_at: payment&.expired_at,
  webhook_results: WebhookDelivery.where(payment_id: payment&.id)
                                  .order(:created_at)
                                  .pluck(:status, :service_result, :remote_status, :response_status)
}
```

Consulte o pagamento remoto pelo painel do Mercado Pago ou pela SDK já configurada. Não grave a resposta integral em arquivo.

## Diagnóstico

| Resultado | Verificação |
| --- | --- |
| Brick não carrega | Public Key de teste, HTTPS, console do navegador e disponibilidade do SDK externo |
| `401` no webhook | assinatura secreta da mesma aplicação, `x-request-id`, relógio do servidor e URL de teste correta |
| `404` no webhook | corrida antes do commit local ou identificador que não pertence a um pagamento criado pelo staging |
| `422` no webhook | resultado local não reconhecido; correlacionar com `service_result` sem copiar o payload |
| `502` no webhook | falha de consulta/validação no gateway; aguardar retry sem liberar o horário |
| `503` no webhook | `MERCADO_PAGO_WEBHOOK_SECRET` ausente no processo web |
| PIX não expira | processo Sidekiq, fila `maintenance`, cron, retries e estado remoto da cobrança |

Se aparecer um defeito reproduzível, registre somente classe do erro, HTTP, estados e IDs mascarados. Crie um teste de regressão, aplique a correção mínima e repita integralmente o cenário afetado.

## Registro da execução

Preencha esta tabela apenas com dados redigidos:

| Campo | Cartão | PIX |
| --- | --- | --- |
| Data e fuso | — | — |
| Commit validado | — | — |
| Host do staging | — | — |
| Agendamento | `…______` | `…______` |
| Pagamento Mercado Pago | `…______` | `…______` |
| Estado remoto inicial/final | — | — |
| Estado local inicial/final | — | — |
| HTTP do webhook | — | — |
| Resultado da auditoria | — | — |
| E-mail único confirmado | — | — |
| Horário liberado | não se aplica | — |

## Critério de conclusão

A tarefa do roadmap só pode ser marcada como concluída quando todos os itens abaixo tiverem evidência:

- [ ] cartão aprovado e agendamento confirmado;
- [ ] webhook real assinado e reenvio idempotente;
- [ ] PIX criado com QR Code, prazo remoto e estados locais coerentes;
- [ ] PIX não pago cancelado após o prazo;
- [ ] horário liberado e e-mail de expiração enviado uma única vez;
- [ ] nenhum segredo ou dado de pagamento registrado;
- [ ] Minitest, RuboCop, Zeitwerk e `npm audit` aprovados no commit validado.

Mantenha os registros identificados no staging até a revisão das evidências. Não apague pagamentos ou auditorias manualmente; a limpeza deve seguir a política do ambiente e a retenção automática.
