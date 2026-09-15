# Roadmap do BH Agendamentos

Estado revisado em setembro de 2026. O projeto utiliza Minitest como suíte oficial e RuboCop para análise estática; não há migração planejada para RSpec.

## Entregue

- [x] Carga explícita `demo:seed` para cliente, prestador e administrador, com fotos fictícias, senhas privadas, renovação semanal sem duplicação, preservação de alterações e recuperação de uploads; roteiro local e Render documentado.
- [x] README com seis capturas reais de desktop e mobile, roteiro reproduzível com dados fictícios e visão da arquitetura com diagrama e fluxos principais.
- [x] Revisão mobile de visitantes, clientes, prestadores e administradores: menu expansível, formulários responsivos, turnos por dia e cartões administrativos, preservando a identidade visual.
- [x] Testes de navegador para criar, remover e persistir múltiplos turnos da agenda.
- [x] Reagendamento por cliente e prestador de reservas confirmadas e pagas, com duração e pagamento preservados, histórico, e-mail aos participantes e proteção contra disputas de horário.
- [x] Autenticação e perfis de cliente, prestador e administrador com Devise.
- [x] Serviços, busca por texto e filtros por bairros de Belo Horizonte.
- [x] Agendamentos com duração, bloqueio de horários passados e prevenção de conflitos.
- [x] Agenda semanal configurável pelo prestador, com turnos dinâmicos, dias fechados e bloqueios gerais ou por serviço.
- [x] Arquivamento e reativação de serviços, preservando o histórico e impedindo novas reservas enquanto arquivados.
- [x] Calendário visual diário, semanal e mensal do prestador, com agendamentos, bloqueios, expediente e histórico opcional.
- [x] Edição de feriados e bloqueios futuros ou em andamento pela Disponibilidade e pelo calendário, incluindo data, horário, motivo e serviço afetado, sem alterar agendamentos existentes.
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
- [x] Minitest compatível com Rails 7.1: 226 testes de aplicação e 870 asserções aprovados na validação da revisão mobile, incluindo seis cenários de concorrência PostgreSQL.
- [x] 18 testes de sistema aprovados com Selenium e Chrome portátil (315 asserções), incluindo oito cenários mobile com validação de larguras, acessibilidade e persistência.
- [x] Calendário validado com Selenium: navegação, detalhes, histórico e alternância entre visualizações (13 asserções aprovadas).
- [x] Edição de bloqueios validada com Selenium pela Disponibilidade e pelo calendário, incluindo persistência após recarregar (dois testes e nove asserções aprovados).
- [x] RuboCop para Ruby, Rails e Minitest, com linha de base do legado.
- [x] Banco PostgreSQL de teste isolado do banco de desenvolvimento no Docker.
- [x] Auditoria JavaScript sem vulnerabilidades conhecidas.
- [x] Deploy de demonstração no Render com SMTP da Brevo e Mercado Pago sandbox.
- [x] Runbook de staging validado com cartão, PIX, webhook assinado e agenda configurável.

## Próximas tarefas prioritárias

### Qualidade e automação

- [ ] Adicionar testes de navegador para bloqueios gerais, bloqueios por serviço e dias sem expediente.
- [ ] Ampliar testes de sistema para os estados finais do pagamento.

### Evoluções dependentes de infraestrutura

- [ ] Enviar lembretes de atendimento com 24 horas de antecedência quando houver Background Worker ativo no ambiente hospedado.
- [ ] Integrar os eventos estruturados do webhook a alertas e painéis operacionais.

## Manutenção contínua

- [ ] Reduzir gradualmente as exceções registradas em `.rubocop_todo.yml`.
- [ ] Manter `npm audit` sem vulnerabilidades e dependências atualizadas.
