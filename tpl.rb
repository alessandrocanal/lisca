# "Lisca" rails template
# inspirated from http://www.sitepoint.com/rails-application-templates-real-world/
# made by @batdevis
# supported by Rawfish (http://rawfishindustries.com/)

# VERSION 0.0.1

# Add the current directory to the path Thor uses
# to look up files
def source_paths
  Array(super) + 
    [File.expand_path(File.dirname(__FILE__))]
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
gem 'swagger_engine'
gem 'faker'
gem 'koala'

#################### gitignore

insert_into_file(".gitignore", "/config/secrets.yml\n", after: "/tmp\n")
insert_into_file(".gitignore", "/config/database.yml\n", after: "/tmp\n")

################### config/database.yml

inside 'config' do
  create_file 'database.yml.example' do <<-EOF
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

# Warning: The database defined as "test" will be erased and
# re-generated from your development database when you run "rake".
# Do not set this db to the same as development or production.
test:
  <<: *default
  database: #{app_name}_test

production:
  <<: *default
  database: #{app_name}_production

EOF
  end
end

run "cp config/database.yml.example config/database.yml"

################### devise


  
############################################
after_bundle do
  remove_dir "test"
  
################### config/application.rb

################### application_controller.rb

  gsub_file 'app/controllers/application_controller.rb', /protect_from_forgery with: :exception/, '#protect_from_forgery with: :exception'

################## rspec

  run "spring stop"
  generate "rspec:install"
  run "bundle binstubs rspec-core"

################### doorkeeper

run "rails generate doorkeeper:install"

comment_lines "config/initializers/doorkeeper.rb", 
  /fail "Please configure doorkeeper resource_owner_authenticator block located in/
  
insert_into_file "config/initializers/doorkeeper.rb", 
  "    current_user || warder.authenticate!(scope: :user)\n",
  after: "resource_owner_authenticator do\n"

insert_into_file "config/initializers/doorkeeper.rb", 
  before: "\n  resource_owner_authenticator do\n" do <<-RUBY

  #https://github.com/doorkeeper-gem/doorkeeper/wiki/Using-Resource-Owner-Password-Credentials-flow
  resource_owner_from_credentials do |routes|
    User.enter(params)
  end  
  RUBY
  end

append_to_file "config/initializers/doorkeeper.rb", 
  "\nDoorkeeper.configuration.token_grant_types << 'password'"

generate(:doorkeeper, "migration")

################## Health Check route
  generate(:controller, "health index")
  route "root to: 'health#index'"

################## git
  git :init
  git add: "."
  git commit: "-a -m 'Initial commit by Lisca template'"
end
