# 📋 BH Agendamentos - Gestão de Tarefas

## ✅ Concluído (O que já funciona)
- [x] Setup inicial do projeto (Rails + Tailwind).
- [x] Autenticação de utilizadores (Devise).
- [x] Vitrine de Serviços na Home.
- [x] Lógica de Agendamento com slots de 30 min.
- [x] Comprovativo de Agendamento (Show).
- [x] CRUD de Serviços protegido para o usuário logado.
- [x] Criação do perfil de Prestador com Devise (Roles).
- [x] Trava de segurança no `ServicesController` (Apenas Prestadores criam serviços).
- [x] Regra de Anti-Overbooking no Banco de Dados (Backend blindado devolvendo erro 422).
- [x] **Front-end Blindado:** Bloqueio visual de horários passados e horários já agendados (integração Front e Back via JS).
- [x] **Painel do Prestador (Dashboard):** Tela exclusiva para gestão de clientes e horários do dia.
- [x] **Cancelamento Inteligente:** Fluxo seguro com pop-up nativo e liberação imediata do slot na agenda.
- [x] **Comunicação Assíncrona:** Action Mailer rodando em background com Sidekiq para e-mails de confirmação e cancelamento (Testado via `letter_opener_web`).
- [x] **Vitrine do Profissional (`/perfil`):** Tela pública/cartão de visitas com a foto flutuante e dados de contato.
- [x] **Dashboard de Administrador (Modo Deus):** Painel protegido para visão panorâmica das métricas e poder de cancelamento de qualquer agendamento do sistema.
- [x] **UX de Elite no Agendamento:** Select em Cascata via JavaScript Vanilla (Escolhe o Profissional -> Filtra dinamicamente os Serviços), integrado com o bloqueio de horários.
- [x] **Onboarding Profissional:** Fluxo de criação de conta (Sign Up) aprimorado com upload de Avatar, Endereço, Bio e escolha de Tipo de Conta diretamente no formulário do Devise.

## 🚧 A Fazer (A Encruzilhada Final do Portfólio)
> *O MVP está 100% pronto. A meta agora é escolher o próximo grande diferencial para brilhar nas entrevistas.*
- [ ] **O Troféu (Deploy):** Hospedar a aplicação na nuvem (Render ou Fly.io), configurar um banco de dados PostgreSQL de produção e armazenar as imagens em nuvem (ex: Amazon S3 ou Cloudinary).
- [ ] **O Diferencial (WhatsApp):** Trocar ou adicionar notificações via WhatsApp utilizando uma API de mensagens.
- [ ] **O Selo de Qualidade (RSpec):** Implementar cobertura de testes automatizados para garantir a estabilidade do código a longo prazo.

## 💡 Backlog (Ideias de Expansão Futura)
- [ ] Pagamento de Sinal/Reserva (Integração com Stripe ou MercadoPago cobrando taxa anti-falta).
- [ ] Relatórios de Faturamento exportáveis em PDF ou CSV no Painel do Administrador.
