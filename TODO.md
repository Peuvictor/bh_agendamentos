# Roadmap do BH Agendamentos

Estado revisado em setembro de 2026. O projeto utiliza Minitest como suíte oficial e RuboCop para análise estática; não há migração planejada para RSpec.

## Entregue

- [x] Autenticação e perfis de cliente, prestador e administrador com Devise.
- [x] Serviços, busca por texto e filtros por bairros de Belo Horizonte.
- [x] Agendamentos com duração, bloqueio de horários passados e prevenção de conflitos.
- [x] Agenda semanal configurável pelo prestador, com turnos dinâmicos, dias fechados e bloqueios gerais ou por serviço.
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
- [x] Minitest compatível com Rails 7.1: 170 testes e 637 asserções de aplicação aprovados.
- [x] Quatro testes de sistema para agendamento, checkout e gestão de serviços, com suporte a Selenium e Chrome portátil.
- [x] RuboCop para Ruby, Rails e Minitest, com linha de base do legado.
- [x] Banco PostgreSQL de teste isolado do banco de desenvolvimento no Docker.
- [x] Auditoria JavaScript sem vulnerabilidades conhecidas.
- [x] Deploy de demonstração no Render com SMTP da Brevo e Mercado Pago sandbox.
- [x] Runbook de staging validado com cartão, PIX, webhook assinado e agenda configurável.

## Próximas tarefas prioritárias

### Integridade e experiência principal

- [x] Arquivar e reativar serviços em vez de apagá-los, preservando agendamentos, pagamentos e avaliações anteriores.
- [x] Impedir novas reservas para serviços arquivados sem ocultar o histórico existente.
- [ ] Criar calendário visual diário, semanal e mensal para o prestador, reunindo agendamentos e bloqueios.
- [ ] Permitir a edição de feriados e bloqueios, incluindo data, horário, motivo e serviço afetado.
- [ ] Implementar reagendamento seguro com nova validação de disponibilidade e preservação do histórico.

### Interface e portfólio

- [ ] Revisar a navegação e os formulários em celulares e telas pequenas.
- [ ] Adicionar capturas de tela e uma visão da arquitetura ao README.
- [ ] Preparar dados de demonstração que apresentem claramente os fluxos de cliente, prestador e administrador.

### Qualidade e automação

- [ ] Adicionar testes de navegador para criar, remover e persistir múltiplos turnos da agenda.
- [ ] Adicionar testes de navegador para bloqueios gerais, bloqueios por serviço e dias sem expediente.
- [ ] Ampliar testes de sistema para os estados finais do pagamento.

### Evoluções dependentes de infraestrutura

- [ ] Enviar lembretes de atendimento com 24 horas de antecedência quando houver Background Worker ativo no ambiente hospedado.
- [ ] Integrar os eventos estruturados do webhook a alertas e painéis operacionais.

## Manutenção contínua

- [ ] Reduzir gradualmente as exceções registradas em `.rubocop_todo.yml`.
- [ ] Manter `npm audit` sem vulnerabilidades e dependências atualizadas.
