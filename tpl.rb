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
gem 'rails', '~> 5.0.1'
gem 'puma', '~> 3.0'
gem 'pg', '~> 0.19.0'
gem 'jbuilder', '~> 2.5'
gem 'swagger_engine', git: 'https://github.com/batdevis/swagger_engine.git'

gem 'jwt'
gem 'figaro'
gem 'rack-cors'

gem 'activeadmin', github: 'activeadmin'
gem 'inherited_resources', github: 'activeadmin/inherited_resources'
gem 'devise', '~> 4.2'

gem 'globalize', github: 'globalize/globalize'
gem 'activemodel-serializers-xml'
gem 'activeadmin-globalize', '~> 1.0.0.pre', github: 'fabn/activeadmin-globalize', branch: 'develop'

gem 'delayed_job_active_record'
gem 'daemons'
gem 'aasm', '~> 4.11', '>= 4.11.1'
gem 'redis', '~> 3.3', '>= 3.3.3'

gem_group :development, :test do
  gem 'byebug', platform: :mri
end

gem_group :development do
  gem 'listen', '~> 3.0.5'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

gem_group :test do
  gem 'faker', '~> 1.7', '>= 1.7.2'
  gem 'rspec-rails', '~> 3.5', '>= 3.5.2'
  gem 'factory_girl_rails'
  gem 'shoulda-matchers', '~> 3.1', '>= 3.1.1'
  gem 'shoulda-callback-matchers', '~> 1.1', '>= 1.1.4'
  gem 'rails-controller-testing'
end

gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

gem 'execjs'
gem 'therubyracer', :platforms => :ruby
gem 'uglifier', '>= 1.3.0'

#################### gitignore

insert_into_file(".gitignore", "/config/database.yml\n", after: "/tmp\n")
insert_into_file(".gitignore", "/config/application.yml\n", after: "/tmp\n")
insert_into_file(".gitignore", "/public/assets\n", after: "/tmp\n")

################### config/database.yml

config_database = <<EOF
default: &default
  adapter: postgresql
  host: localhost
  port: 5432
  pool: 5
  timeout: 5000
  username: postgres
  password: postgres

development:
  <<: *default
  database: #{app_name}_development

test:
  <<: *default
  database: #{app_name}_test
EOF

inside 'config' do
  create_file "database.yml.example", config_database
  remove_file "database.yml"
  create_file "database.yml", config_database
end

inside 'config/environments' do
  insert_into_file "production.rb", after: "# config.cache_store = :mem_cache_store" do <<-EOF

  config.cache_store = :redis_store, (ENV['REDIS_URL'] || 'redis://localhost:6379/0/cache')
  EOF
  end
end

################### application_controller.rb

application_controller = <<EOF
class ApplicationController < ActionController::Base
  attr_reader :current_user
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

copy_file "lib/swagger_engine/swagger.json"
#gsub_file "app/assets/javascripts/swagger_engine/swagger.json", "\"host\": \"localhost:3000\"", "\"host\": \"#{host}:#{port}\""

################### utility scripts

cmd = <<EOF
#!/usr/bin/env bash
grep \"PORT\" config/application.yml|awk '{print $2}'|head -1|xargs rails s -p
EOF
create_file "bin/serve", cmd
chmod 'bin/serve', 775

############################################

after_bundle do

################### config/application.yml

  run 'bundle exec figaro install'
  config_application = <<EOF
HOST: "#{host}"
PORT: "#{port}"
URL: "http://#{host}:#{port}"
SECRET_KEY_BASE: "please_generate_one_with_rake_secret_task"
SECRET_DEVISE: "please_generate_one_with_rake_secret_task"
FB_APP_ID: "xxx"
FB_APP_SECRET: "yyy"
REDIS_URL: "redis://localhost:6379/0/cache"
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
