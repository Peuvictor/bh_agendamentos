# Capturas do portfólio

As imagens mostram páginas reais do BH Agendamentos com dados fictícios. O roteiro usa o ambiente Rails de teste, fixtures e transações do framework de testes; não altera seeds nem o banco de desenvolvimento. As cobranças aprovadas são registros locais de exemplo, sem chamada ao Mercado Pago. Jobs e e-mails usam os adaptadores de teste.

## Telas e enquadramento

| Arquivo | Perfil e conteúdo | Janela |
| --- | --- | --- |
| `desktop-vitrine.png` | Visitante: três serviços ativos, busca e bairros | 1440 × 900 px |
| `desktop-agendamento.png` | Cliente: corte e barba confirmado, pagamento e reagendamento | 1440 × 900 px |
| `desktop-calendario.png` | Prestador: semana com reservas e bloqueio | 1440 × 900 px |
| `mobile-disponibilidade.png` | Prestador: domingo fechado, dois turnos de segunda a sábado e bloqueio | 390 × 900 px |
| `mobile-calendario.png` | Prestador: visão diária da segunda-feira | 390 × 900 px |
| `mobile-administracao.png` | Administrador: serviços ativos e um arquivado | 390 × 900 px |

O Chrome emula as dimensões CSS com escala 1. A captura abrange toda a página, portanto a altura do PNG pode superar os 900 px da janela. As imagens não recebem retoques nem alterações no HTML/CSS da aplicação. A página longa de disponibilidade fica recolhida no README principal para facilitar a leitura.

## Como atualizar

Com os serviços Docker do projeto ativos, Chrome e ChromeDriver compatíveis disponíveis no container e os assets compilados, execute a partir da raiz do repositório:

```bash
docker compose exec web env RAILS_ENV=test PARALLEL_WORKERS=1 \
  SYSTEM_TEST_DRIVER=selenium \
  CHROME_BINARY=/myapp/tmp/chrome-linux64/chrome \
  CHROMEDRIVER_PATH=/myapp/tmp/chromedriver-linux64/chromedriver \
  bundle exec ruby -Itest docs/screenshots/capture.rb
```

Ajuste os caminhos conforme a instalação local do navegador. O Chrome precisa das bibliotecas de sistema e de uma fonte de emoji para renderizar os ícones da interface. No container Debian, a fonte pode ser instalada com `docker compose exec web sh -lc 'apt-get update && apt-get install -y --no-install-recommends fonts-noto-color-emoji'`; essa preparação precisa ser repetida se o container for recriado.

Para recompilar assets após mudanças de interface, use `docker compose exec web npm run build` e `docker compose exec web npm run build:css`. O banco de teste deve estar preparado conforme as instruções do README principal, separado do banco de desenvolvimento.

O roteiro manual fica fora de `test/system`, para que a suíte normal não sobrescreva imagens versionadas. Ele exige explicitamente `RAILS_ENV=test` e Selenium, usa o suporte de testes de sistema do Rails com prazos maiores para inicialização e scripts do Chrome, e grava os seis PNGs nesta pasta. Execute sem outra suíte usando o mesmo banco de teste.

Os exemplos usam o prestador Rafael Almeida, a cliente Marina Costa e um administrador fictício, com e-mails em `example.com`. Os serviços são corte e barba (R$ 85), cuidado da barba (R$ 55), corte clássico (R$ 50) e um pacote arquivado (R$ 120). A agenda começa na próxima segunda-feira em relação à execução, no fuso `America/Sao_Paulo`, mantendo os exemplos futuros e a ação de reagendamento disponível.

Antes de salvar, o roteiro aguarda os elementos de cada tela, os eventos do calendário e as fontes. Ao terminar:

1. Abra os seis PNGs e confira textos, carregamento, enquadramento e ausência de erros ou diálogos sobrepostos.
2. Confira a galeria no README, incluindo as seções expansíveis e os links para tamanho original.
3. Execute `git diff --check` e versione os PNGs junto de eventuais ajustes nas legendas ou no roteiro.

As datas podem mudar a cada execução; estas imagens são exemplos de interface, não snapshots usados como asserções visuais.
