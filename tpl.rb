# "Lisca" rails template
# inspirated from http://www.sitepoint.com/rails-application-templates-real-world/
# made by @batdevis
# supported by Rawfish (http://rawfishindustries.com/)

# VERSION 0.0.1

# Add the current directory to the path Thor uses
# to look up files
def source_paths
  Array(super) +
#    [File.expand_path(File.dirname(__FILE__))]
    [File.join(File.expand_path(File.dirname(__FILE__)),'files')]
end

################### readme

remove_file "README.rdoc"
copy_file "README.md"

##################### Gemfile
remove_file "Gemfile"
run "touch Gemfile"

add_source 'https://rubygems.org'
gem 'rails', '4.2.3'
gem 'therubyracer'
gem 'passenger-rails'
gem 'pg'

gem 'sass-rails', '~> 5.0'
gem 'uglifier', '>= 1.3.0'
gem 'jquery-rails'

gem_group :development do
  gem 'quiet_assets'
end

gem_group :development, :test do
  gem 'spring'
  gem 'pry-rails'
  gem 'web-console', '~> 2.0'
  gem 'rspec-rails', '~> 3.0', require: false
end

gem_group :test do
  gem 'webmock'
end

gem 'factory_girl_rails'
gem 'doorkeeper', '~> 3.0.0'
gem 'devise'
gem 'swagger_engine', git: "https://github.com/batdevis/swagger_engine.git"
gem 'faker'
gem 'koala'
gem 'figaro'
gem 'grape'
gem 'grape-raketasks'
gem 'oj'
gem 'grape-rabl'
gem 'redis-rails'

gem 'capistrano',  '~> 3.1'
gem 'capistrano-rails', '~> 1.1'
gem 'capistrano-touch-linked-files'
gem 'capistrano-passenger'

gem 'sidekiq'
gem 'devise-async'

#################### gitignore

insert_into_file(".gitignore", "/config/database.yml\n", after: "/tmp\n")
insert_into_file(".gitignore", "/public/assets\n", after: "/tmp\n")

################### config/database.yml

config_database = <<EOF
default: &default
  adapter: postgresql
  host: localhost
  port: 5432
  pool: 5
  timeout: 5000
  user: postgres
  password: postgres

development:
  <<: *default
  database: #{app_name}_development

test:
  <<: *default
  database: #{app_name}_test

production:
  <<: *default
  database: #{app_name}_production
EOF

inside 'config' do
  create_file "database.yml.example", config_database
  remove_file "database.yml"
  create_file "database.yml", config_database
end

################### redis

inside 'config/initializers' do
  comment_lines "session_store.rb", /Rails.application.config.session_store/
  append_to_file "session_store.rb" do <<-EOF
if Rails.env.production?
  Rails.application.config.session_store :redis_store, servers: (ENV['REDIS_URL'] || 'redis://localhost:6379/0/cache')
else
  Rails.application.config.session_store :cookie_store, key: '_#{app_name}_session'
end
  EOF
  end
end

inside 'config/environments' do
  insert_into_file "production.rb", after: "# config.cache_store = :mem_cache_store" do <<-EOF

  config.cache_store = :redis_store, (ENV['REDIS_URL'] || 'redis://localhost:6379/0/cache')
  EOF
  end
end


################### sidekiq

initializer 'sidekiq.rb', <<-CODE
Sidekiq.configure_server do |config|
  config.redis = { url: ENV['REDIS_URL'] || 'redis://localhost:6379/0/cache' }
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV['REDIS_URL'] || 'redis://localhost:6379/0/cache' }
end
CODE

inside 'config' do

  config_sidekiq = <<EOF
---
:queues:
  - default
  - [mailer, 2]
EOF

  create_file 'sidekiq.tml', config_sidekiq

end

################### devise async

initializer 'devise_async.rb', <<-CODE
Devise::Async.backend = :sidekiq
Devise::Async.queue = :mailer
CODE

################### views

layout_application = <<EOF
<!DOCTYPE html>
<html>
<head>
  <title>#{app_name}</title>
  <%= stylesheet_link_tag 'application', media: 'all' %>
  <%= javascript_include_tag 'application' %>
  <%= csrf_meta_tags %>
</head>
<body>

<%= yield %>

</body>
</html>
EOF

remove_file "app/views/layouts/application.html.erb"
create_file "app/views/layouts/application.html.erb", layout_application

copy_file "app/views/api/v1/users/show.rabl"
copy_file "app/views/api/v1/users/index.rabl"

################### assets

application_js = <<EOF
//= require jquery
//= require jquery_ujs
EOF

remove_file "app/assets/javascripts/application.js"
create_file "app/assets/javascripts/application.js", application_js
remove_file "app/assets/stylesheets/application.css"
copy_file "app/assets/stylesheets/application.scss"

################### application_controller.rb

application_controller = <<EOF
class ApplicationController < ActionController::Base
  protect_from_forgery with: :null_session, only: Proc.new { |c| c.request.format.json? }
end
EOF

remove_file "app/controllers/application_controller.rb"
create_file "app/controllers/application_controller.rb", application_controller

################### some questions, please

host = ask "app domain [localhost]"
port = ask "port [3000]"
host = "localhost" if host.blank?
port = "3000" if port.blank?
#repo_url = ask "repo url"

################### swagger_engine

inside 'config/initializers' do
  append_to_file("assets.rb", "Rails.application.config.assets.precompile += [\"swagger_engine/print.css\", \"swagger_engine/reset.css\"]")
end

copy_file "app/assets/javascripts/swagger_engine/swagger.json"
gsub_file "app/assets/javascripts/swagger_engine/swagger.json", "\"host\": \"localhost:3000\"", "\"host\": \"#{host}:#{port}\""

################### utility scripts

cmd = <<EOF
#!/usr/bin/env bash
grep \"PORT\" config/application.yml|awk '{print $2}'|xargs rails s -p
EOF
create_file "bin/serve", cmd
chmod 'bin/serve', 775

############################################

after_bundle do

################### sidekiq

run 'bundle binstubs sidekiq'

################### config/application.yml

  run 'bundle exec figaro install'
  config_application = <<EOF
HOST: "#{host}"
PORT: "#{port}"
SECRET_KEY_BASE: "please_generate_one_with_rake_secret_task"
SECRET_DEVISE: "please_generate_one_with_rake_secret_task"
EOF

  inside 'config' do
    remove_file "application.yml"
    create_file "application.yml.example", config_application
    create_file "application.yml", config_application
  end

################### config/secrets.yml

  config_secrets = <<EOF
production:
  secret_key_base: <%= ENV["SECRET_KEY_BASE"] %>
development:
  secret_key_base: <%= ENV["SECRET_KEY_BASE"] %>
test:
  secret_key_base: <%= ENV["SECRET_KEY_BASE"] %>
EOF

  inside 'config' do
    remove_file "secrets.yml"
    create_file "secrets.yml", config_secrets
  end

################## rspec

  remove_dir "test"
  run "spring stop"
  generate "rspec:install"
  run "bundle binstubs rspec-core"

  insert_into_file "spec/rails_helper.rb",
    after: "# Add additional requires below this line. Rails is not loaded until this point!" do <<-RUBY

Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }
require 'webmock/rspec'
    RUBY
    end

  insert_into_file "spec/rails_helper.rb",
    after: "config.infer_spec_type_from_file_location!" do <<-RUBY

  config.include Helpers
  WebMock.disable_net_connect!(allow_localhost: true)
  RUBY
    end

  inside "spec/support" do
    copy_file "api_helper.rb"
    copy_file "stub_helper.rb"
  end

################### devise

  run "rails generate devise:install"
  run "rails generate devise User"
  inside 'config/initializers' do
    insert_into_file "devise.rb",
      "  config.secret_key = ENV['SECRET_DEVISE']\n\n",
      before: "  # ==> Mailer Configuration"
  end
################### doorkeeper

  run "rails generate doorkeeper:install"
  run "rails generate doorkeeper:migration"

  inside 'config/initializers' do
    comment_lines "doorkeeper.rb",
      /fail "Please configure doorkeeper resource_owner_authenticator block located in/

    insert_into_file "doorkeeper.rb",
      "    current_user || warder.authenticate!(scope: :user)\n",
      after: "resource_owner_authenticator do\n"

    insert_into_file "doorkeeper.rb",
      before: "\n  resource_owner_authenticator do\n" do <<-RUBY

      #https://github.com/doorkeeper-gem/doorkeeper/wiki/Using-Resource-Owner-Password-Credentials-flow
      resource_owner_from_credentials do |routes|
        User.enter(params)
      end
      RUBY
      end

    append_to_file "doorkeeper.rb",
      "\nDoorkeeper.configuration.token_grant_types << 'password'"

  end

  gsub_file "config/routes.rb", "  use_doorkeeper" do <<-EOF
  use_doorkeeper do
    skip_controllers :applications, :authorized_applications, :authorizations
  end
  EOF
  end

################### devise and doorkeeper integration

  inside "app/models" do
    remove_file "user.rb"
    copy_file "user.rb"
    copy_file "social_account.rb"
    copy_file "concerns/doorkeeper_resource_owner_password_credentials_flow.rb"
    copy_file "concerns/social_auth.rb"
  end

  generate :migration, "create_social_accounts user:references provider:string uid:string token:string email:string data:json"
  generate :migration, "add_timestamps_to_social_accounts created_at:datetime updated_at:datetime"

  inside "app/controllers" do
    copy_file "lock_controller.rb"
    copy_file "profile_controller.rb"
    copy_file "tokens_controller.rb"
    copy_file "users/registrations_controller.rb"
  end

  gsub_file "config/routes.rb", "  devise_for :users" do <<-EOF
  devise_for :users, controllers: { registrations: 'users/registrations' }
  EOF
  end
  route "post 'tokens/social', to: 'tokens#social', defaults: { format: 'json' }"
  route "resource 'profile', only: :show, controller: 'profile', defaults: { format: 'json' }"

  inside "spec/api" do
    copy_file "auth_request.rb"
    copy_file "profile_request.rb"
  end

  inside "spec/factories" do
    copy_file "user.rb"
    copy_file "social_account.rb"
  end

################## grape

  inside "app/controllers/api" do
    copy_file "base.rb"
    copy_file "v1/base.rb"
    copy_file "v1/health_check.rb"
    copy_file "v1/users.rb"
  end

  route "mount API::Base => '/'"

  api_root = <<EOF
config.middleware.use(Rack::Config) do |env|
      env['api.tilt.root'] = Rails.root.join 'app', 'views', 'api'
    end
EOF
  environment api_root

################## swagger api-docs

  route "mount SwaggerEngine::Engine, at: '/api-docs'"

################## ping api

  inside "app/controllers" do
    copy_file "ping_controller.rb"
  end

  route "get 'ping', to: 'ping#index', defaults: { format: 'json' }"

  inside "spec/api" do
    copy_file "ping_request.rb"
  end

################## home api

  inside "app/controllers" do
    copy_file "home_controller.rb"
  end

  inside "app/views" do
    copy_file "home/index.html.erb"
    copy_file "home/fb.html.erb"
  end

  route "get 'home/fb', to: 'home#fb'"
  route "root 'home#index', via: :all"

  gsub_file("config/routes.rb", /^\s*#.*\n/, '')

################## capistrano

  run "bundle exec cap install STAGES=development,staging,production"

  gsub_file("Capfile",
    "# require 'capistrano/bundler'",
    "require 'capistrano/bundler'"
  )
  gsub_file("Capfile",
    "# require 'capistrano/rails/assets'",
    "require 'capistrano/rails/assets'"
  )
  gsub_file("Capfile",
    "# require 'capistrano/rails/migrations'",
    "require 'capistrano/rails/migrations'"
  )
  gsub_file("Capfile",
    "# require 'capistrano/passenger'",
    "require 'capistrano/passenger'"
  )
  insert_into_file("Capfile", "require 'capistrano/touch-linked-files'\n", before: "# Load custom tasks from")

  inside "config" do

    gsub_file("deploy.rb",
      "set :application, 'my_app_name'",
      "set :application, '#{app_name}'"
    )

    insert_into_file("deploy.rb",
      "set :rails_env, 'production'\n",
      after: "# set :deploy_to, '/var/www/my_app_name'\n"
    )

    gsub_file("deploy.rb",
      "# set :deploy_to, '/var/www/my_app_name'",
      "set :deploy_to, '/data/webapp'"
    )
    gsub_file("deploy.rb",
      "# set :linked_files, fetch(:linked_files, []).push('config/database.yml', 'config/secrets.yml')",
      "set :linked_files, fetch(:linked_files, []).push('config/database.yml', 'config/application.yml')"
    )
    gsub_file("deploy.rb",
      "# set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', 'public/system')",
      "set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', 'public/system')"
    )
=begin
    insert_into_file("deploy/development.rb",
      "set :branch, fetch(:branch, 'development')\n\n",
      before: "# role-based syntax\n"
    )
=end
  end

################## git
  git :init
  git add: "."
  git commit: "-a -m 'Initial commit by Lisca template'"
end
