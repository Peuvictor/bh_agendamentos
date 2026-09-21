# Dados de demonstração

`bin/rails demo:seed` prepara os fluxos de cliente, prestador e administrador com pessoas fictícias,
fotos ilustrativas, pagamentos locais de exemplo e agenda no fuso de Brasília.
Não efetua cobranças nem envia e-mails de negócio durante a carga.

## Configuração e execução

No desenvolvimento, configure no `.env` local (não versionado):

```dotenv
DEMO_SEED_ENABLED=true
DEMO_CLIENT_PASSWORD=
DEMO_PROVIDER_PASSWORD=
DEMO_ADMIN_PASSWORD=
```

Preencha cada senha com um valor privado distinto, com no mínimo 8 caracteres, incluindo letra
maiúscula, letra minúscula, número e caractere especial, e no máximo 72 bytes.
Não há senha padrão; a configuração é validada antes de qualquer gravação.
O Docker Compose repassa as variáveis do `.env` ao serviço web. Configure também `CLOUDINARY_URL`
para o armazenamento utilizado em desenvolvimento e produção.

```bash
docker compose up -d web
docker compose exec web bin/rails db:prepare
docker compose exec web bin/rails demo:seed
```

O primeiro comando aplica as novas variáveis ao container. Fora do Docker, exporte as variáveis
no ambiente do processo Rails; o projeto não carrega `.env` diretamente.

No Render, disponibilize esta versão do código e configure as mesmas quatro variáveis e
`CLOUDINARY_URL` nas variáveis privadas do serviço. Em um shell operacional com acesso ao mesmo
banco e ambiente Rails do serviço, execute:

```bash
bin/rails demo:seed
```

A execução no ambiente hospedado é uma etapa explícita: não acrescente o comando ao build,
à inicialização da aplicação ou às migrations. `bin/rails db:seed` apenas informa o novo comando;
não limpa o banco nem cria os antigos prestadores aleatórios.

| Perfil | E-mail | Senha configurada por |
| --- | --- | --- |
| Cliente — Marina Costa | `cliente-demo@example.com` | `DEMO_CLIENT_PASSWORD` |
| Prestador — Rafael Almeida | `prestador-demo@example.com` | `DEMO_PROVIDER_PASSWORD` |
| Administrador Demo | `admin-demo@example.com` | `DEMO_ADMIN_PASSWORD` |

As senhas não são impressas. Os e-mails da tabela são os iniciais; se forem alterados pela
interface, o comando preserva a alteração e imprime os e-mails atuais. Reexecutar a carga não
troca senhas de contas existentes, mesmo se as variáveis tiverem mudado. Para alterá-las, use
o fluxo normal de edição da conta.
Os e-mails `example.com` são fictícios e não servem para receber recuperação de senha.

## Conteúdo e datas

O prestador fica na Savassi. O catálogo contém corte e barba (R$ 85), barba e cuidado facial
(R$ 55), corte clássico (R$ 50) e pacote especial arquivado (R$ 120), todos com duração inicial
de 60 minutos. Há expediente de segunda a sábado, das 08h às 12h e das 14h às 18h; domingo fechado.

Cada conjunto semanal começa na próxima segunda-feira estritamente posterior à execução.
Se executar numa segunda, a base será a segunda seguinte.

| Dia da semana base | Horário | Exemplo |
| --- | --- | --- |
| Segunda | 09h | Corte e barba confirmado e pago |
| Segunda | 11h | Barba pendente, sem cobrança |
| Segunda | 15h–16h | Bloqueio geral: organização do espaço |
| Terça | 10h | Barba confirmada e paga |
| Terça | 14h–15h | Bloqueio exclusivo de barba: manutenção dos materiais |
| Terça | 15h | Corte clássico cancelado, sem pagamento |
| Quarta | 14h | Corte clássico confirmado e pago |
| Quarta | 16h | Corte e barba reembolsado |

Na primeira carga também são criados dois atendimentos históricos, na segunda e terça de duas
semanas antes da semana base, pagos e avaliados com cinco estrelas. Permanecem os mesmos nas
renovações seguintes. Atendimentos passados usam o estado `confirmado`, conforme o modelo atual.

Pagamentos pré-carregados são registros locais fictícios com identificador `demo-…`, em estados
aprovado ou reembolsado. Não representam transações no Mercado Pago. A reserva pendente não
possui pagamento e segue `PAYMENT_EXPIRATION_MINUTES`; com Sidekiq ativo, ela expira normalmente.
Reexecutar não reabre a reserva nem estende seu prazo. Uma nova reserva criada pela interface
usa o checkout normal do ambiente; mantenha a demonstração hospedada no sandbox.

## Reexecução e falhas

- UUIDs determinísticos identificam os exemplos. Repetir na mesma semana preserva registros,
  senhas, fotos, cancelamentos, reagendamentos e alterações de serviços e expediente.
- Executar em outra semana acrescenta seis reservas, quatro pagamentos e dois bloqueios;
  preserva contas, catálogo e histórico anterior. A renovação não é automática.
- Registros ausentes são criados novamente; não há comando de reset ou limpeza.
- Contas externas que já utilizem um dos e-mails reservados causam erro, sem apropriação da conta.
- Conflitos com agendamentos, serviços arquivados ou expediente alterado interrompem toda a
  transação relacional. Corrija a incompatibilidade pela interface e execute novamente.
- Execuções simultâneas aguardam uma trava PostgreSQL comum, inclusive durante os uploads.
- As fotos são enviadas após a transação. Falhas de armazenamento mantêm os dados, listam os
  arquivos pendentes sem expor mensagens do provedor e retornam saída diferente de zero.
  Corrija a configuração e repita o comando; anexos existentes não são substituídos.

As cinco imagens estão versionadas em [db/demo/images](../db/demo/images/README.md), com origem
artificial e prompts documentados. O pacote arquivado reutiliza a foto de corte e barba.
A carga não baixa fotos de terceiros. O Active Storage pode enfileirar sua análise de imagens;
esse processamento utiliza a infraestrutura normal do projeto. Ações posteriores pela interface
e a expiração da reserva podem gerar as notificações normais para os e-mails fictícios.

## Roteiro de apresentação

1. **Visitante:** abra a vitrine, filtre pela Savassi e confira os três serviços ativos com fotos.
2. **Cliente:** entre como Marina, abra o corte e barba confirmado da segunda-feira e confira
   pagamento e ação **Reagendar**. Consulte também os exemplos cancelado, reembolsado e históricos.
3. **Prestador:** entre como Rafael, abra **Calendário** e avance até a semana indicada pelo comando.
   Confira reservas e bloqueios; habilite **Exibir cancelados e reembolsados** para o histórico.
   Em **Disponibilidade**, confira turnos, domingo fechado e abrangência dos bloqueios.
4. **Administrador:** entre na conta administrativa e consulte usuários e serviços; o pacote
   especial apresenta a ação **Reativar**. Alterações feitas na apresentação são preservadas.

O roteiro de [capturas do README](screenshots/README.md) continua independente desta carga.

## Verificação automatizada

```bash
docker compose exec web bin/rails test test/services/demo_seed_test.rb \
  test/services/demo_seed_preservation_test.rb test/services/demo_assets_test.rb \
  test/services/demo_seed_lock_test.rb
docker compose exec web env SYSTEM_TEST_DRIVER=selenium \
  CHROME_BINARY=/myapp/tmp/chrome-linux64/chrome \
  CHROMEDRIVER_PATH=/myapp/tmp/chromedriver-linux64/chromedriver \
  bin/rails test test/system/demo_journeys_test.rb
```

Os testes usam somente o banco e armazenamento de teste. Ajuste os caminhos do navegador para
a instalação disponível. Os cenários validam fotos locais e aguardam os eventos do calendário;
o layout ainda carrega o SDK do Mercado Pago e fontes externas. A validação automatizada não
executa a carga no Render.
