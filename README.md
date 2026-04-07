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

✨ Funcionalidades Principais (Highlights Técnicos)
⚡ Select em Cascata (UX de Elite): Filtro dinâmico via JavaScript Vanilla que permite ao cliente escolher o profissional e ver apenas os serviços vinculados a ele, sem recarregar a página e integrado à lógica de bloqueio de horários.

🛡️ Prevenção de Overbooking (Full-Stack): Lógica no JavaScript desabilita horários passados e ocupados no Front-end em tempo real, enquanto o Model do Rails blinda o banco de dados contra concorrência.

👑 Painel Administrativo (Modo Deus): Dashboard centralizado com métricas globais do sistema, permitindo que o administrador gerencie prestadores, clientes e tenha controle total sobre cancelamentos.

✉️ Comunicação Assíncrona (Sidekiq + Action Mailer): Envio de e-mails transacionais (confirmação e cancelamento) processados em background no Redis, garantindo alta performance.

🖼️ Onboarding Completo: Fluxo de cadastro inteligente onde o usuário escolhe seu perfil (Cliente/Prestador) e já preenche Bio, Endereço e Foto de Perfil via Active Storage.

🗺️ Roadmap de Evolução
[x] Dashboard exclusivo para o Prestador de Serviços.

[x] E-mails em background com Action Mailer e Sidekiq.

[x] Edição de perfil e cartão de visitas (Avatar com Active Storage).

[x] Painel do Administrador Geral do Sistema.

[x] Filtro dinâmico de serviços por profissional (Cascata JS).

[ ] Implementação de notificações via API de WhatsApp.

[ ] Deploy para Produção (Hospedagem em nuvem).

[ ] Testes automatizados com RSpec.

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


👨‍💻 Autor
Pedro Guimarães

Desenvolvedor Ruby on Rails

Belo Horizonte, MG

Meu LinkedIn https://www.linkedin.com/in/pedro-guimaraes-dev/
