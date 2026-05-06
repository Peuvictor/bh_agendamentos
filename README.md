# 💈 BH Agendamentos

Marketplace de agendamentos inteligente focado em profissionais independentes e negócios locais de Belo Horizonte.

## 🌍 O Projeto em Produção
O sistema está no ar e pode ser testado em: 🚀 [BH Agendamentos](https://bh-agendamentos.onrender.com)

## 🎯 A Solução
O **BH Agendamentos** elimina a necessidade de agendamentos manuais via WhatsApp, oferecendo uma interface onde o cliente visualiza o serviço, o prestador e sua disponibilidade, agendando de forma autônoma e assíncrona.

## ✨ Diferenciais Técnicos (Sob o capô)
* **Arquitetura de Banco de Dados:** Modelagem customizada de usuários (`STI` ou `Enums`) para suportar múltiplos papéis (Clientes, Prestadores, Admins) e associações complexas na tabela de `Appointments`.
* **Deploy e DevOps:** Aplicação totalmente conteinerizada com **Docker**, rodando no **Render** com pipeline de CI/CD automatizado e execução de *Data Migrations* dinâmicas via `entrypoint`.
* **Armazenamento em Nuvem:** Integração do **Active Storage** com **Cloudinary** em produção para gerenciamento escalável de avatares e fotos de serviços.
* **Processamento Assíncrono:** Infraestrutura configurada com **Redis** e **Sidekiq** para garantir performance sem travar o *thread* principal durante uploads ou envio de notificações.
* **Frontend de Alta Performance:** Utilização de **Tailwind CSS** para um design responsivo, limpo e focado na usabilidade móvel.

## 🗺️ Roadmap de Evolução

### ✅ Entregues (MVP Consolidado)
- [x] Dockerização completa (Ambiente de Dev e Produção).
- [x] Sistema de autenticação robusto com Devise.
- [x] Upload de fotos em nuvem (Cloudinary/Active Storage).
- [x] **Agendamento Dinâmico:** Fluxo refatorado para seleção precisa de datas e horários.
- [x] **Notificações Assíncronas:** Alertas automáticos via e-mail (Sidekiq/Redis).
- [x] **Sistema de Avaliações:** Reviews e notas para os serviços prestados.
- [x] **Filtros Geográficos:** Busca de serviços segmentada por bairros de BH.
- [x] **Comunicação Rápida:** Botão de contato direto via API do WhatsApp do prestador.
- [x] Deploy com PostgreSQL e banco Key-Value (Redis) na nuvem.

### 🚧 Em Desenvolvimento / Próximos Passos
- [ ] Dashboard de métricas e controle de faturamento para o prestador.
- [ ] Integração de gateway de pagamento (Mercado Pago ou Stripe) para sinal de reserva.
- [ ] Cobertura de testes automatizados com **RSpec**.

## 💻 Como rodar o projeto localmente

**Pré-requisitos:** Ter o **Docker** e o **Docker Compose** instalados na sua máquina.

```bash
# 1. Clone o repositório
git clone https://github.com/Peuvictor/bh_agendamentos.git
cd bh_agendamentos

# 2. Suba os containers
docker-compose up --build -d

# 3. Setup inicial do banco de dados (Criação e Migrações)
docker-compose exec web bin/rails db:prepare

# 4. Popule o banco com dados falsos para teste de layout
docker-compose exec web bin/rails db:seed
O sistema estará disponível em http://localhost:3000.

👨‍💻 Autor
Pedro Victor Oliveira Guimarães

Desenvolvedor Ruby on Rails Junior | 📍 Belo Horizonte, MG

🔗 Meu LinkedIn
