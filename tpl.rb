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
gem 'rails', '~> 5.1.2'
gem 'puma', '~> 3.9', '>= 3.9.1'
gem 'pg', '~> 0.21.0'
#gem 'swagger_engine', git: 'https://github.com/batdevis/swagger_engine.git'

gem 'jwt'
gem 'figaro'
gem 'rack-cors'

#gem 'activeadmin', github: 'activeadmin'
#gem 'inherited_resources', github: 'activeadmin/inherited_resources'
#gem 'activeadmin-globalize', '~> 1.0.0.pre', github: 'fabn/activeadmin-globalize', branch: 'develop'

gem 'globalize', github: 'globalize/globalize'
gem 'active_model_serializers', '~> 0.10.6'

gem 'delayed_job_active_record'
gem 'daemons'
gem 'aasm', '~> 4.12', '>= 4.12.1'
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
  gem 'faker', '~> 1.8', '>= 1.8.4'
  gem 'rspec-rails', '~> 3.6'
  gem 'factory_girl_rails'
  gem 'shoulda-matchers', '~> 3.1', '>= 3.1.2'
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

################### config/application.rb
application do
  "config.generators do |g|
    g.test_framework :rspec
  end"
end

################### application_controller.rb

application_controller = <<EOF
class ApplicationController < ActionController::API
  rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable_entity_response
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found_response
  rescue_from AASM::InvalidTransition, with: :render_invalid_transition

  def render_unprocessable_entity_response(exception)
    render json: {
      message: "Validation Failed",
      errors: ValidationErrorsSerializer.new(exception.record).serialize
    }, status: :unprocessable_entity
  end

  def render_not_found_response
    render json: { message: "Not found", errors: [{code: "not_found"}] }, status: :not_found
  end

  def render_invalid_transition
    render json: { message: "Invalid state transition", errors: [{code: "invalid_transition"}] }, status: :unprocessable_entity
  end

  def render_error_response(exception)
    render json: { message: exception.message, errors: [{code: exception.code}] }, status: exception.http_status
  end


  protected
  def authenticate_request!
    unless user_id_in_token?
      render json: { errors: ['Unauthorized'] }, status: :unauthorized
      return
    end
    # token ok, check se ho l'utente, se non ce l'ho lo registro
    u = User.find_by(uid: auth_token[:user_id])
    if u.blank?
      lang = request.headers['Accept-Language'].present? ? request.headers['Accept-Language'] : "it"
      #unlock_code = rand(6 ** 6).to_s.rjust(5,'0')
      cu = User.create({uid: auth_token[:user_id], email: auth_token[:email], prefered_language: lang[0,2] })
      #render json: { errors: ['User is blocked'] }, status: :unauthorized
      cu.reload
      @current_user = cu
    else
      @current_user = u
    #  unlock_code = params[:data][:code] rescue nil
    #  render json: { errors: ['User is blocked'] }, status: :unauthorized if u.locked && unlock_code.nil?
    end

  rescue JWT::VerificationError, JWT::DecodeError
    render json: { errors: ['Unauthorized'] }, status: :unauthorized
  end

  private
  def http_token
    @http_token ||= if request.headers['Authorization'].present?
      request.headers['Authorization'].split(' ').last
    end
  end

  def auth_token
    @auth_token ||= JsonWebToken.decode(http_token)
  end

  def user_id_in_token?
    http_token && auth_token && auth_token[:user_id]
  end
end
EOF

remove_file "app/controllers/application_controller.rb"
create_file "app/controllers/application_controller.rb", application_controller

################### app/lib/json_web_token.rb
json_web_token = <<EOF
class JsonWebToken
  def self.encode(payload)
    #JWT.encode(payload, Rails.application.secrets.secret_key_base)
  end

  def self.decode(token)
    return HashWithIndifferentAccess.new(JWT.decode(token, ENV['JWT_SECRET_KEY'], false)[0])
  rescue Exception => e
    nil
  end
end
EOF
create_file "app/lib/json_web_token.rb", json_web_token

################### app/lib/validation_error_serializer.rb
validation_error_serializer = <<EOF
class ValidationErrorSerializer

  def initialize(record, field, details)
    @record = record
    @field = field
    @details = details
  end

  def serialize
    {
      resource: resource,
      field: field,
      code: code
    }
  end

  private

  def resource
    I18n.t(
      underscored_resource_name,
      scope: [:resources],
      locale: :api,
      default: @record.class.to_s
    )
  end

  def field
     I18n.t(
      @field,
      scope: [:fields, underscored_resource_name],
      locale: :api,
      default: @field.to_s
    )
  end

  def code
    I18n.t(
      @details[:error],
      scope: [:errors, :codes],
      locale: :api,
      default: @details[:error].to_s
    )
  end

  def underscored_resource_name
    @record.class.to_s.gsub('::', '').underscore
  end
end
EOF

create_file "app/lib/validation_error_serializer.rb", validation_error_serializer

################### app/lib/validation_errors_serializer.rb
validation_errors_serializer = <<EOF
class ValidationErrorsSerializer

  attr_reader :record

  def initialize(record)
    @record = record
  end

  def serialize
    record.errors.details.map do |field, details|
      details.map do |error_details|
        ValidationErrorSerializer.new(record, field, error_details).serialize
      end
    end.flatten
  end
end
EOF

create_file "app/lib/validation_errors_serializer.rb", validation_errors_serializer

################### some questions, please

host = ask "app domain [localhost]"
port = ask "port [3000]"
host = "localhost" if host.blank?
port = "3000" if port.blank?
#repo_url = ask "repo url"

################### swagger_engine

#copy_file "lib/swagger_engine/swagger.json"
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

################## core model

  #run "./bin/rails generate model user"
  generate :model, "user email:string uuid:string"
  generate :serializer, "user"
  generate :model, "item name:string user:references"
  generate :serializer, "item"
################## rspec

  remove_dir "test"
  run "spring stop"
  generate "rspec:install"
  run "bundle binstubs rspec-core"


################## api

  inside "app/controllers" do
    copy_file "ping_controller.rb"
  end

  inside "app/controllers/api/v1" do
    copy_file "api_controller.rb"
    copy_file "users_controller.rb"
    copy_file "items_controller.rb"
  end

  route "get 'ping', to: 'ping#index', defaults: { format: 'json' }"
  route "scope module: 'api' do
      namespace :v1 do
        resources :users, only: [:index]
        resources :items
      end
    end"

################## home api


  gsub_file("config/routes.rb", /^\s*#.*\n/, '')

  rake "db:migrate"
################## git
  git :init
  #git add: "."
  #git commit: "-a -m 'Initial commit by Lisca template'"
end
