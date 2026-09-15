# Agenda e reagendamento

[Voltar ao README](../README.md)

## Calendário do prestador

Após entrar com uma conta de prestador, acesse **Calendário** (`/provider/calendar`). A página reúne os agendamentos recebidos e os bloqueios gerais ou por serviço, com visualizações de dia, semana e mês. A visualização inicial é semanal no desktop e diária em telas pequenas; os horários usam o fuso de Brasília (`America/Sao_Paulo`).

Agendamentos pendentes e confirmados aparecem por padrão. A opção **Exibir cancelados e reembolsados** acrescenta esses registros ao período consultado. Ao selecionar um evento, o prestador vê cliente, serviço, horário e status do agendamento, ou motivo e abrangência do bloqueio. Agendamentos oferecem um link para sua página de detalhes.

O expediente configurado é destacado na grade. A tela **Disponibilidade** (`/provider/availability`) reúne os turnos semanais e o cadastro, edição e remoção de bloqueios. O diálogo do calendário oferece **Editar bloqueio** para registros ainda não encerrados, abrindo o mesmo formulário usado pela lista. Para reagendar um atendimento confirmado e pago, abra seus detalhes e selecione **Reagendar**.

O FullCalendar carrega somente os eventos que cruzam o período visível, por meio de `GET /provider/calendar/events`, com parâmetros `start`, `end` e `include_history`. O endpoint é restrito ao prestador autenticado e não retorna contato do cliente nem dados financeiros. A grade diária/semanal desta versão exibe o intervalo das 06h às 22h.

### Edição de feriados e bloqueios

Na Disponibilidade, selecione **Editar** ao lado do bloqueio, ou use **Editar bloqueio** no calendário. O formulário permite alterar data, dia inteiro ou faixa de horário, serviço afetado e motivo opcional (até 150 caracteres). Ao salvar, a aplicação retorna à Disponibilidade com a confirmação. Erros mantêm os valores digitados para correção.

Bloqueios encerrados não podem ser editados. Nos bloqueios em andamento, o início original pode ser mantido; um novo início deve estar no futuro, exceto ao selecionar dia inteiro de hoje. O término deve permanecer no futuro. Os horários são interpretados no fuso de Brasília.

Um bloqueio associado a serviço arquivado pode manter esse vínculo, migrar para um serviço ativo ou passar a valer para todos os serviços. Não é permitido selecionar outro serviço arquivado. A atualização mantém o mesmo registro e não cancela nem modifica agendamentos existentes, mesmo quando o novo intervalo os sobrepõe.

As rotas de edição são `GET /provider/availability_blocks/:id/edit` e `PATCH /provider/availability_blocks/:id`, restritas aos bloqueios do prestador autenticado. O servidor verifica novamente se o bloqueio ainda pode ser editado no momento de salvar.

## Reagendamento

Cliente titular e prestador responsável podem selecionar **Reagendar** nos detalhes de um atendimento confirmado com pagamento aprovado, enquanto ele ainda não começou. O serviço precisa estar ativo e a reserva deve ter um intervalo válido. O prestador acessa os detalhes também pelo calendário.

A tela mostra o horário atual, a duração reservada e o valor efetivamente pago. Ao escolher nova data e hora, a aplicação valida novamente o expediente, os turnos, os bloqueios gerais ou por serviço e as reservas de todos os serviços do prestador. Os horários seguem o fuso de Brasília e a grade de 30 minutos. A consulta desconsidera o próprio agendamento, permitindo sobreposição parcial com seu intervalo anterior.

A mudança mantém o mesmo agendamento, cliente, serviço, pagamento e duração registrada, mesmo se preço ou duração do serviço forem alterados depois da reserva. O horário anterior é liberado somente quando a alteração e seu histórico são gravados juntos. Os detalhes exibem autor, momento da alteração e intervalos anterior e novo, inclusive após cancelamento ou reembolso. Cada mudança envia um e-mail ao cliente e ao prestador após a confirmação da transação; o e-mail usa os horários registrados no histórico.

Formulários desatualizados são recusados com instrução para recarregar, evitando sobrescrever outra mudança. Reservas pendentes, canceladas, reembolsadas, já iniciadas ou de serviços arquivados não podem ser reagendadas. Não há troca de serviço, nova cobrança, aprovação da outra parte ou reagendamento por arrastar no calendário.

As rotas autenticadas são `GET /appointments/:id/edit`, `PATCH /appointments/:id` e `GET /appointments/:id/available_slots?date=YYYY-MM-DD`. A atualização aceita `appointment_date`, `appointment_hour` e `schedule_token`, emitido pelo formulário. Sucesso redireciona aos detalhes com HTTP 303; erros de validação retornam 422 e conflitos de formulário retornam 409. A consulta retorna `{ "slots": ["08:00", "08:30"] }` e é restrita aos participantes da reserva.

Criação e reagendamento compartilham uma trava por prestador, também usada nas alterações de expediente e bloqueios. O reagendamento trava prestador, serviço, agendamento e pagamento nessa ordem e revalida as condições dentro da transação. Cancelamento e reconciliação financeira compartilham a trava do agendamento. Bloqueios continuam preservando reservas existentes.

A migração `CreateAppointmentReschedulings` é aditiva e deve ser aplicada antes de iniciar a nova versão. Reservas anteriores continuam válidas, sem criação artificial de histórico. Registros antigos sem intervalo positivo não podem ser reagendados.
