📋 BH Agendamentos - Gestão de Tarefas (Atualizado)
✅ Concluído (Arquitetura Sênior & UX)
[x] Banco de Dados Pro: Migração completa para UUID em todas as tabelas (Segurança e Escalabilidade).

[x] Persistência de Imagens: Integração total com Cloudinary via Active Storage com Direct Upload.

[x] Background Jobs: Setup de Sidekiq + Redis finalizado e testado via Dashboard.

[x] Fluxo de Agendamento: Refatorado para rotas aninhadas e lógica de cálculo de fim de horário automática.

[x] Validação de Conflitos: O prestador agora está protegido contra agendamentos sobrepostos.

[x] Onboarding Dinâmico: Usuário escolhe se é Cliente ou Prestador no ato do cadastro inicial (Permissão no Devise resolvida).

[x] Refinamento de Perfil: Campos de WhatsApp, Endereço, Bio e Avatar adicionados e funcionais na edição de perfil.

[x] Dashboard do Prestador (Visão): Tabela centralizada criada com botão dinâmico de integração direto com o WhatsApp do cliente.

🚧 In Progress (Foco na Lógica de Negócio)
[ ] Gestão de Status: Criar a rota (patch) e a ação no controller para os botões Confirmar ou Cancelar da Dashboard alterarem o status no banco de dados.

[ ] Notificações Reais: Disparar os e-mails transacionais (Action Mailer) via Sidekiq assim que o cliente agendar ou o status mudar.

🎯 Próximos Passos (O "Tapa" no Produto)
[ ] Filtros de Busca: Sistema de busca na Home (Vitrine) para filtrar serviços em BH por nome ou categoria.

[ ] Refatoração de Código: Limpar a coluna duplicada duracao_minutos vs duration na tabela de serviços.

💡 Ideias de Expansão
[ ] Integração WhatsApp API: Enviar lembretes automáticos 2h antes do serviço.

[ ] Reviews: Sistema de estrelas e comentários após o atendimento.
