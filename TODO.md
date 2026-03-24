# 📋 BH Agendamentos - Gestão de Tarefas

## ✅ Concluído (O que já funciona)
- [x] Setup inicial do projeto (Rails + Tailwind).
- [x] Autenticação de utilizadores (Devise).
- [x] Vitrine de Serviços na Home.
- [x] Lógica de Agendamento com slots de 30 min.
- [x] Comprovativo de Agendamento (Show).
- [x] Bloqueio de horários passados no JavaScript.
- [x] CRUD de Serviços protegido para o usuário logado.

## 🚧 A Fazer (Sprint de Amanhã - Máximo 3 Tarefas)
- [ ] **1. Os Dois Lados da Moeda (Roles):** Atualizar o `enum :role` no Model `User` para incluir o tipo `provider` (Prestador). Adicionar um botão/checkbox na tela de cadastro (`registrations/new`) para a pessoa escolher se quer só agendar ou se quer oferecer serviços.
- [ ] **2. A Fechadura do Prestador (Autorização):** Criar uma trava no `ServicesController` para que apenas usuários com a role `provider` consigam acessar a gestão de serviços. Se um `client` tentar acessar a URL `/services`, ele deve ser bloqueado com uma mensagem de erro.
- [ ] **3. Anti-Overbooking Definitivo:** Corrigir a validação `no_overlapping_appointments` para verificar conflitos na agenda do *Prestador inteiro*, e não apenas no serviço. Fazer com que esses horários já agendados também sumam (ou fiquem cinzas) lá no JavaScript da tela de agendamento do cliente.

## 💡 Backlog (Ideias para o futuro)
- [ ] Painel do Prestador para ele ver todos os agendamentos do dia dele.
- [ ] Envio de e-mail automático quando um horário é cancelado.
- [ ] Dashboard de Administrador (Dono do App).
