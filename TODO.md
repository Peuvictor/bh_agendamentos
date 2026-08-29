# Roadmap do BH Agendamentos

Estado revisado em agosto de 2026. O projeto utiliza Minitest como suíte oficial e RuboCop para análise estática; não há migração planejada para RSpec.

## Entregue

- [x] Autenticação e perfis de cliente, prestador e administrador com Devise.
- [x] Serviços, busca por texto e filtros por bairros de Belo Horizonte.
- [x] Agendamentos com duração, bloqueio de horários passados e prevenção de conflitos.
- [x] Cancelamento lógico preservando o histórico e liberando o horário.
- [x] Dashboard do prestador, avaliações e painel administrativo.
- [x] Active Storage com Cloudinary para avatares e imagens de serviços.
- [x] Sidekiq e Redis para processamento assíncrono e e-mails.
- [x] Checkout com Mercado Pago Payment Brick e mensagens amigáveis de configuração.
- [x] Pagamentos com preço obtido no servidor, ciclo `pending` → `approved` e confirmação condicionada ao pagamento.
- [x] Webhook do Mercado Pago com validação de assinatura, consulta à API e processamento idempotente de reenvios.
- [x] Restrições únicas para pagamentos por agendamento e identificador do Mercado Pago.
- [x] Expiração segura de reservas e PIX com reconciliação remota, jobs idempotentes e e-mail específico.
- [x] Criação de cobranças protegida por trava do agendamento e prazo PIX enviado ao Mercado Pago.
- [x] Reconciliação idempotente de reembolsos totais, com auditoria, notificação e liberação do horário.
- [x] Minitest compatível com Rails 7.1: 109 testes e 435 asserções aprovados.
- [x] Teste de sistema do fluxo agendamento → checkout com suporte a Selenium e Chrome portátil.
- [x] RuboCop para Ruby, Rails e Minitest, com linha de base do legado.
- [x] Banco PostgreSQL de teste isolado do banco de desenvolvimento no Docker.
- [x] Auditoria JavaScript sem vulnerabilidades conhecidas.

## Próximas tarefas prioritárias

- [x] Registrar eventos e falhas do webhook para observabilidade em produção, com retenção configurável.
- [ ] Executar e documentar uma cobrança completa no sandbox real do Mercado Pago.
- [x] Revisar e consolidar as métricas de faturamento e volume de clientes do dashboard.
- [x] GitHub Actions para RuboCop, Minitest, Zeitwerk e auditoria de dependências.

## Manutenção contínua

- [ ] Reduzir gradualmente as exceções registradas em `.rubocop_todo.yml`.
- [ ] Manter `npm audit` sem vulnerabilidades e dependências atualizadas.
- [ ] Ampliar testes de sistema para os estados finais do pagamento.
