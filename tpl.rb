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

##################### Gemfile
remove_file "Gemfile"
run "touch Gemfile"

add_source 'https://rubygems.org'
gem 'rails', '4.2.3'
gem 'passenger'
gem 'pg'

gem 'sass-rails', '~> 5.0'
gem 'uglifier', '>= 1.3.0'
gem 'jquery-rails'
gem 'jbuilder', '~> 2.0'

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

#################### gitignore

insert_into_file(".gitignore", "/config/secrets.yml\n", after: "/tmp\n")
insert_into_file(".gitignore", "/config/database.yml\n", after: "/tmp\n")

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

################### swagger_engine

inside 'config/initializers' do
  append_to_file("assets.rb", "Rails.application.config.assets.precompile += [\"swagger_engine/print.css\", \"swagger_engine/reset.css\"]"
end

copy_file "app/assets/javascripts/swagger_engine/swagger.json"

############################################
after_bundle do
  remove_dir "test"
  
################### application_controller.rb
  remove_file "app/controllers/application_controller.rb"
  copy_file "app/controllers/application_controller.rb"

################## rspec

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
  route "root 'home#index'"

  gsub_file("config/routes.rb", /^\s*#.*\n/, '')

################## git
  git :init
  git add: "."
  git commit: "-a -m 'Initial commit by Lisca template'"
end
