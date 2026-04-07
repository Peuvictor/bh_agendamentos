FROM ruby:3.3.0

# Instala as dependências do sistema operacional, banco e frontend
RUN apt-get update -qq && apt-get install -y \
  build-essential \
  libpq-dev \
  postgresql-client \
  nodejs \
  npm \
  tzdata \
  bash \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /myapp

# Copia os arquivos de gems primeiro para aproveitar o cache do Docker
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Copia o restante do projeto
COPY . .

EXPOSE 3000

ENV PORT=10000

CMD ["sh", "-c", "bundle exec rails db:migrate && bundle exec rails server -b 0.0.0.0 -p ${PORT:-3000}"]
