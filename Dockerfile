# Usamos a imagem que já tem Ruby e o ambiente pronto
FROM ruby:3.3.0

# Instala as dependências (Atualizado para Node 20)
RUN apt-get update -qq && apt-get install -y \
  build-essential \
  libpq-dev \
  postgresql-client \
  tzdata \
  bash \
  curl \
  && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
  && apt-get install -y nodejs \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /myapp

# Copia dependências
COPY Gemfile Gemfile.lock ./
COPY package.json package-lock.json* ./

# Instala tudo e FORÇA o binário do Tailwind para Linux
RUN bundle install
RUN npm install
RUN npm install @tailwindcss/oxide-linux-x64-gnu

# Copia o projeto
COPY . .

# Compila os assets
RUN bundle exec rails assets:precompile

EXPOSE 3000
ENV PORT=10000

# Mantemos o nosso truque da migração automática
CMD ["sh", "-c", "bundle exec rails db:migrate && bundle exec rails server -b 0.0.0.0 -p ${PORT:-3000}"]
