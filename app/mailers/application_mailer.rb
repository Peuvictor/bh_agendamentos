class ApplicationMailer < ActionMailer::Base
  default from: -> { ENV.fetch('MAILER_FROM', 'nao-responda@agendabh.com.br') }
  layout "mailer"
end
