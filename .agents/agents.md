# 💈 BH Agendamentos - Antigravity & Codex Guidelines

## 1. Identidade e Domínio do Sistema
* **Natureza:** SaaS de agendamento para serviços locais (barbearias, pet shops, estúdios) em Belo Horizonte.
* **Restrição Absoluta:** Este sistema **NÃO é um agregador de eventos**. O Codex está expressamente proibido de sugerir arquiteturas, tabelas, models ou fluxos voltados para venda de ingressos ou shows.

## 2. Topologia de Copilotos (Antigravity)
* **Don (Orquestração e Arquitetura):** Invoque para desenhar a segurança dos fluxos do Mercado Pago, validação de assinaturas (`x-signature`) e estruturação de regras de negócio complexas.
* **Atlas (Dados e Infraestrutura):** Responsável pelo ambiente **Docker**, travas de concorrência no **PostgreSQL** e garantia de **idempotência** (evitar duplicação de pagamentos e reservas).
* **Mira (Engenharia Tática):** Responsável pelo código **Ruby 3.3 / Rails 7.1**. Deve aplicar *early returns*, manter *Skinny Controllers*, delegar lógica pesada e escrever testes robustos no **Minitest 5**.
* **Dora (Assincronia e UI):** Focada em **Sidekiq/Redis** para processar webhooks/expiração de PIX em background e na interface utilizando **Hotwire (Turbo/Stimulus) + Tailwind CSS**. Proibido introduzir frameworks JS pesados.

## 3. Regras de Execução Segura (Codex no WSL)
* **Execução via Container:** Como o projeto roda em WSL/Docker, o Codex deve sugerir comandos de terminal exclusivamente utilizando o prefixo `docker compose exec web` ou `bin/rails`.
* **Proteção de Hardware:** É proibido habilitar a gravação de logs de feedback ou telemetria verbosa do modelo em SQLite local para evitar desgaste no SSD.
* **Modo Seguro de Banco:** Sub-agentes não têm permissão para executar comandos como `db:drop` ou `db:reset` sem confirmação humana explícita.

## 4. Diretrizes Específicas: Mercado Pago (`payments_controller.rb`)
* O endpoint do webhook é a única fonte de verdade autorizada a consolidar um status de pagamento.
* O cálculo de duração e a validação de horários passados devem ser checados rigorosamente antes de instanciar o SDK.
* Reenvios de notificações pelo gateway devem ser absorvidos silenciosamente sem duplicar o envio de e-mails de confirmação.
