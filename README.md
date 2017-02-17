#Lisca
###startup rails template

##How to use it

Clone it:
```
git clone {repo url}
```
go to new project dir
```
cd ..
```
create new rails app with postgresql db, no test unit and based on Lisca template:
```
rails new thenextbigthing --api -d postgresql -T -m lisca/tpl.rb
```

##Features

###Main Gems
* _swagger_engine_: api documentation
* _capistrano_: deploy
* _rspec_: test
* _figaro_: config vars
* _redis-rails_: cache store
* _activeadmin_: cms

###Installation
```
$ bundle install
$ cp config/application.yml.example config/application.yml
$ cp config/database.yml.example config/database.yml
```
Edit `/data/webapp/shared/config/*.yml` files

Use `./bin/rake secret` to generate *SECRET_KEY_BASE* value.

###Development Server
In a terminal, start local redis server:
```
$ redis-server
```
###activeadmin
To complete the installation and for the configuration follow the doc http://activeadmin.info/docs/documentation.html

###

###Deploy with capistrano

* create new git repo and add it:
  ```
  $ git remote add origin {your_git_repo_url}
  ```
* push the code:
  ```
  $ git push origin master -u
  ```

Suppose that we are working in `development` environment.

* set `repo_url` in `config/deploy.rb`
* set `server` in `config/deploy/development.rb`
* touch limyllinks files:
  ```
  $ cap development linked_files:touch
  ```
* give a check:
  ```
  $ cap development deploy:check
  ```
* ssh into the server:
  ```
  $ ssh dev@{server ip}
  ```
* became deployer:
  ```
  $ sudo su deploy
  ```
* edit `/data/webapp/shared/config/*.yml` files.

###Local development

```
./bin/serve
```

###System Requirements
* _ruby 2.2_

###Backing Services
* _postgresql 9.4_
* _redis_

##Credits
* [@batdevis](http://twitter.com/batdevis)
* supported by [Rawfish](http://rawfishindustries.com/)

  [![Rawfish Logo](http://rawfishindustries.com/wp-content/uploads/2015/03/logo_rawfish_WEB.jpg)](http://rawfishindustries.com)
