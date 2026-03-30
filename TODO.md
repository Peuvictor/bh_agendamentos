# 📋 BH Agendamentos - Gestão de Tarefas

## ✅ Concluído (O que já funciona)
- [x] Setup inicial do projeto (Rails + Tailwind).
- [x] Autenticação de utilizadores (Devise).
- [x] Vitrine de Serviços na Home.
- [x] Lógica de Agendamento com slots de 30 min.
- [x] Comprovativo de Agendamento (Show).
- [x] Bloqueio de horários passados no JavaScript.
- [x] CRUD de Serviços protegido para o usuário logado.
- [x] Criação do perfil de Prestador com Devise (Roles).
- [x] Trava de segurança no `ServicesController` (Apenas Prestadores criam serviços).
- [x] Regra de Anti-Overbooking no Banco de Dados (Backend blindado devolvendo erro 422).

## 🚧 A Fazer (Sprint de Amanhã - Máximo 3 Tarefas)
- [ ] **1. O Fantasma do Front-end (Debug JS):** O backend já bloqueia o overbooking, mas o front-end ainda não pinta o botão de vermelho antes do clique. Investigar por que o JavaScript (`aplicarFiltroDeHorarios`) não está lendo a lista do `@busy_slots` quando a página recarrega (Testar cache do Sprockets/Importmap, logs do console e o carregamento do DOM).
- [ ] **2. Painel do Prestador (Dashboard):** Criar a interface da rota `dashboard` no `AppointmentsController`. Fazer uma tela onde o prestador consiga ver, em formato de lista ou tabela, todos os clientes que agendaram horários com ele, ordenados por data e hora.
- [ ] **3. Cancelamento Inteligente:** Testar e garantir o fluxo de cancelamento (Destroy). Se um cliente ou prestador cancelar um agendamento, aquele horário específico precisa voltar a aparecer como disponível (verde) no calendário de marcações.

## 💡 Backlog (Ideias para o futuro)
- [ ] Envio de e-mail automático quando um horário é cancelado ou confirmado.
- [ ] Dashboard de Administrador (Dono geral do App, com acesso a todos os dados).
- [ ] Edição de Perfil (Permitir que o Prestador adicione foto, telefone e bio).
