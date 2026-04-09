# 💈 BH Agendamentos (Agendamentos BH)

> **Marketplace de agendamentos inteligente focado em profissionais independentes e negócios locais de Belo Horizonte.**

![Ruby](https://img.shields.io/badge/Ruby-3.x-CC342D?style=for-the-badge&logo=ruby&logoColor=white)
![Rails](https://img.shields.io/badge/Ruby_on_Rails-7.x-CC0000?style=for-the-badge&logo=ruby-on-rails&logoColor=white)
![TailwindCSS](https://img.shields.io/badge/Tailwind_CSS-38B2AC?style=for-the-badge&logo=tailwind-css&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2CA5E0?style=for-the-badge&logo=docker&logoColor=white)

---

## 🌍 O Projeto em Produção
O sistema está no ar e pode ser testado em:
🚀 **[https://bh-agendamentos.onrender.com](https://bh-agendamentos.onrender.com)**

---

## 🎯 A Solução
O **BH Agendamentos** elimina a necessidade de agendamentos manuais via WhatsApp, oferecendo uma interface onde o cliente visualiza o serviço, o prestador e sua disponibilidade, agendando de forma autônoma.

### ✨ Diferenciais Técnicos (O que há sob o capô)
- **Arquitetura de Banco de Dados:** Modelagem customizada de usuários para suportar múltiplos papéis (Roles) e associações complexas entre Clientes e Prestadores na mesma tabela de `Appointments`.
- **Deploy Moderno:** Aplicação totalmente conteinerizada com **Docker**, rodando no **Render** com pipeline de CI/CD automatizado.
- **Identidade Visual Dinâmica:** Integração de **Active Storage** para exibição de avatares dos prestadores diretamente nos cards de serviços, aumentando a conversão e confiança.
- **Frontend de Alta Performance:** Utilização de **Tailwind CSS** para um design responsivo, limpo e focado na usabilidade móvel.

---

## 🗺️ Roadmap de Evolução

### ✅ Concluído (MVP)
- [x] Dockerização completa (Ambiente de Dev e Produção).
- [x] Sistema de autenticação robusto com Devise.
- [x] Fluxo de criação de serviços exclusivo para Prestadores.
- [x] Visualização de fotos dos prestadores via Active Storage.
- [x] Deploy bem-sucedido com PostgreSQL em nuvem.

### 🚧 Em Desenvolvimento
- [ ] Implementação de notificações via e-mail em background (Sidekiq/Redis).
- [ ] Refatoração do fluxo de agendamento para seleção de datas dinâmicas.

### 🎯 Próximos Passos
- [ ] Sistema de avaliações e reviews de serviços.
- [ ] Integração com API de WhatsApp para lembretes automáticos.
- [ ] Testes automatizados com RSpec.

---

## 💻 Como rodar o projeto localmente

```bash
# 1. Clone o repositório
git clone [https://github.com/Peuvictor/bh_agendamentos.git](https://github.com/Peuvictor/bh_agendamentos.git)
cd bh_agendamentos

# 2. Suba os containers
docker-compose up --build

# 3. Setup inicial do banco
docker-compose exec web bin/rails db:prepare



👨‍💻 Autor
Pedro Guimarães Desenvolvedor Ruby on Rails Junior 📍 Belo Horizonte, MG

🔗 Meu LinkedIn
