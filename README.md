# 💈 BH Agendamentos

> **Um sistema de agendamentos inteligente e responsivo focado em resolver os principais gargalos de profissionais independentes e negócios locais.**

![Ruby](https://img.shields.io/badge/Ruby-3.x-CC342D?style=for-the-badge&logo=ruby&logoColor=white)
![Rails](https://img.shields.io/badge/Ruby_on_Rails-7.x-CC0000?style=for-the-badge&logo=ruby-on-rails&logoColor=white)
![TailwindCSS](https://img.shields.io/badge/Tailwind_CSS-38B2AC?style=for-the-badge&logo=tailwind-css&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2CA5E0?style=for-the-badge&logo=docker&logoColor=white)

---

## 🎯 O Problema vs. A Solução

**O Problema:** Profissionais que gerenciam agendas pelo WhatsApp sofrem com:
1. Choque de horários (Overbooking).
2. Clientes esquecendo os horários.
3. Perda de tempo respondendo "quais horários você tem livre?".

**A Solução (BH Agendamentos):** Uma plataforma onde o cliente vê em tempo real a disponibilidade do profissional, agenda de forma autônoma e recebe notificações automáticas por e-mail, enquanto o profissional gerencia tudo através de um painel exclusivo.

---

## ✨ Funcionalidades Principais (Highlights Técnicos)

- **🛡️ Prevenção de Overbooking (Full-Stack):** Lógica no JavaScript desabilita horários passados e ocupados no Front-end em tempo real, enquanto o Model do Rails blinda o banco de dados contra concorrência e falsificação de requisições.
- **✉️ Comunicação Assíncrona (Sidekiq + Action Mailer):** Envio de e-mails transacionais (confirmação e cancelamento) processados em background no Redis, garantindo que o usuário não enfrente telas de carregamento travadas.
- **🖼️ Upload de Mídias Nuvem-Ready:** Gerenciamento de fotos de perfil com `Active Storage`, configurado para rodar localmente no momento, mas pronto para integração com Amazon S3 alterando apenas uma linha de configuração.
- **🔐 Autorização e Permissões:** Sistema robusto de contas (Devise) separando Clientes e Prestadores de Serviço, onde a interface se adapta de acordo com o nível de acesso (Role) do usuário logado.

---

## 🛠️ Como rodar o projeto na sua máquina

Este projeto foi totalmente encapsulado utilizando **Docker**. Você não precisa instalar Ruby, Rails ou PostgreSQL na sua máquina, apenas o Docker e o Docker Compose.

**1. Clone o repositório:**
```bash
git clone [https://github.com/Peuvictor/bh_agendamentos.git](https://github.com/Peuvictor/bh_agendamentos.git)
cd bh_agendamentos

2. Suba os containers em segundo plano:

Bash
docker-compose up -d
3. Prepare o Banco de Dados:

Bash
docker-compose exec web bin/rails db:setup
4. Acesse o sistema:

Aplicação: http://localhost:3000

Caixa de E-mails de Teste: http://localhost:3000/letter_opener

🗺️ Roadmap de Evolução
[x] Dashboard exclusivo para o Prestador de Serviços.

[x] E-mails em background com Action Mailer e Sidekiq.

[x] Edição de perfil e cartão de visitas (Avatar com Active Storage).

[ ] Painel do Administrador Geral do Sistema.

[ ] Implementação de pagamentos (Sinal de reserva) via API.

[ ] Testes automatizados com RSpec.

👨‍💻 Autor
Pedro Guimarães

Desenvolvedor Ruby on Rails

Belo Horizonte, MG

Meu LinkedIn https://www.linkedin.com/in/pedro-guimaraes-dev/
