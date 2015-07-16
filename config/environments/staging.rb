BigApp::Application.configure do
  # Enable logging on Heroku
  config.logger = Logger.new(STDOUT)
  $stdout.sync = true
  # rest of config removed ..
end