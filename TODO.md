📋 BH Agendamentos - Gestão de Tarefas (Atualizado)
✅ Concluído (Arquitetura Sênior)
[x] Banco de Dados Pro: Migração completa para UUID em todas as tabelas (Segurança e Escalabilidade).

[x] Persistência de Imagens: Integração total com Cloudinary (As fotos agora são eternas e não somem no deploy).

[x] Background Jobs: Setup de Sidekiq + Redis finalizado e testado via Dashboard.

[x] Fluxo de Agendamento: Refatorado para rotas aninhadas e lógica de cálculo de fim de horário automática.

[x] Validação de Conflitos: O prestador agora está protegido contra agendamentos sobrepostos em todos os seus serviços.

[x] UI/UX Fix: Barra de navegação corrigida (fim do problema do hidden) e botões de gestão visíveis para Prestadores.

🚧 In Progress (Foco na Experiência do Dono)
[ ] Dashboard do Prestador: Criar a visão centralizada para o barbeiro/estúdio ver quem agendou e quando.

[ ] Gestão de Status: Implementar botões para o prestador Confirmar ou Cancelar agendamentos.

[ ] Notificações Reais: Disparar os e-mails transacionais via Sidekiq assim que o cliente agendar.

🎯 Próximos Passos (O "Tapa" no Produto)
[ ] Refinamento de Perfil: Adicionar campos de WhatsApp e Endereço (essencial para o cliente chegar ao local).

[ ] Filtros de Busca: Sistema de busca na Home para filtrar serviços em BH por nome.

[ ] Refatoração de Código: Limpar a coluna duplicada duracao_minutos vs duration no banco de dados.

💡 Ideias de Expansão
[ ] Integração WhatsApp API: Enviar lembretes automáticos 2h antes do serviço.

[ ] Reviews: Sistema de estrelas e comentários após o atendimento.
