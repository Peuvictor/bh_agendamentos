# 💈 BH Agendamentos - Diretrizes de Desenvolvimento (AGENTS.md)

## 1. Escopo e Domínio Restrito
* **Sistema:** SaaS de agendamento de serviços locais em Belo Horizonte (ex: barbearias, pet shops, estúdios).
* **Bloqueio de Domínio:** O projeto **NÃO é um agregador de eventos**. O Codex e os sub-agentes estão proibidos de sugerir código ou tabelas referentes a ingressos, shows ou assentos.

## 2. Topologia de Copilotos e Roadmap
* **Don (Estratégia e Integração):** Acione para arquitetar a **reconciliação de status do Mercado Pago** (rejected, cancelled, refunded) e definir a estrutura de **logs de webhook e observabilidade** em produção.
* **Atlas (Infraestrutura e Dados):** Acione para blindar o PostgreSQL com travas de **idempotência concorrente** (evitando cobranças simultâneas) e para configurar o **CI no GitHub Actions**.
* **Mira (Engenharia Back-end):** Acione para corrigir as **métricas do dashboard** em `dashboard_controller.rb`, refatorar os **testes de sistema** em `appointments_test.rb` eliminando rastros de scaffolds antigos, e manter os controllers magros aplicando *early returns*.
* **Dora (Assincronia e Front-end):** Acione para estruturar o job de **expiração de PIX e reservas pendentes** no Sidekiq/Redis e para manutenções na interface com **Hotwire (Turbo/Stimulus) + Tailwind CSS**.

## 3. Padrões de Código e Execução
* **Ambiente Local:** Utilize exclusivamente o prefixo `docker compose exec web` para comandos de terminal.
* **Pagamentos:** O webhook (`POST /webhooks/mercado_pago`) é a fonte da verdade. É obrigatório manter a validação de `x-signature` e `x-request-id` intacta.
* **Segurança de Hardware:** É proibido habilitar logs excessivos do Codex em SQLite para prevenir desgaste de SSD no ambiente WSL.

## 4. Critérios de Aceitação (Checklist de Qualidade)
* O código só é considerado pronto após passar por:
  1. `bin/rails test` (com 100% de aprovação e sem regressões nas 136 asserções atuais).
  2. `SYSTEM_TEST_DRIVER=selenium` para qualquer alteração no Payment Brick.
  3. `bin/rails zeitwerk:check`.
  4. `npm audit` (mantendo 0 vulnerabilidades).
