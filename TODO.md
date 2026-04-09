📋 BH Agendamentos - Gestão de Tarefas (Atualizado)
✅ Concluído (MVP Operacional)
[x] Arquitetura Base: Setup Rails 7 + Tailwind CSS + Docker.

[x] Autenticação: Sistema de login/cadastro com Devise.

[x] Banco de Dados de Produção: Migração completa para PostgreSQL.

[x] Gestão de Roles: Diferenciação entre Cliente e Prestador (Roles/Enums).

[x] Vitrine Dinâmica: Home listando serviços com foto do prestador e preço.

[x] Identidade Visual: Integração de Active Storage para Avatares.

[x] Segurança de Escopo: Prestadores só gerenciam seus próprios serviços.

[x] Deploy Real: Aplicação hospedada no Render com CI/CD.

[x] UX/UI Moderno: Layout responsivo focado na "vibe" de Belo Horizonte.

🚧 In Progress (Foco Total)
[ ] Fluxo de Agendamento: Refatorar o AppointmentsController para suportar a nova estrutura de client_id (Onde o Frederico parou).

[ ] Persistência de Imagens: Configurar Cloudinary ou AWS S3 (Atualmente as fotos somem no deploy do Render Free).

[ ] Dashboard do Prestador: Finalizar a tela de gestão de horários recebidos.

🎯 Próximos Passos (Diferenciais)
[ ] Notificações: Implementar e-mails transacionais (Action Mailer).

[ ] Background Jobs: Configurar Sidekiq/Redis para processamento de filas.

[ ] Filtros Avançados: Busca de serviços por nome ou categoria.

[ ] Testes: Iniciar cobertura com RSpec (Modelos e Controllers).

💡 Ideias de Expansão
[ ] Integração com API de WhatsApp para lembretes automáticos.

[ ] Sistema de avaliações (Review) após a conclusão do serviço.
