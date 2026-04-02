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
- [x] **Edição de Perfil Avançada:** Upload de imagens com Active Storage, campos de Telefone, Bio e Endereço integrados ao Devise e interface estilizada.
- [x] **Vitrine do Profissional (`/perfil`):** Tela pública/cartão de visitas com a foto flutuante e dados de contato.

## 🚧 A Fazer (Próximo Desafio - O Chefão Final do MVP)
- [ ] **1. Dashboard de Administrador (O Grande Irmão):** Fazer o controle total. Criar a lógica para um "Dono do App" (Admin) conseguir visualizar o faturamento, acessar os dados de todos os prestadores e cancelar qualquer agendamento do sistema.

## 💡 Backlog (O Caminho para Nível Pleno / Portfólio de Elite)
- [ ] Melhoria de UX no Agendamento: Implementar Select em Cascata (Escolher o Profissional primeiro -> Filtrar Serviços depois) via JavaScript nativo e data-attributes.
- [ ] Notificações via WhatsApp (Integração de API para mandar mensagem no celular do cliente).
- [ ] Pagamento de Sinal/Reserva (Integração com Stripe ou MercadoPago cobrando taxa anti-falta).
- [ ] Cobertura de Testes Automatizados (Garantir a integridade do sistema com RSpec).
- [ ] Deploy para Produção (Hospedar na nuvem com banco PostgreSQL real e fotos no Amazon S3).
