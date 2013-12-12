# This is a set of sample deployment recipes for deploying via Capistrano.
# One of the recipes (deploy:symlink_nginx) assumes you have an nginx configuration
# file at config/nginx.conf. You can make this easily from the provided sample
# nginx configuration file.
#
# For help deploying via Capistrano, see this thread:
# http://meta.discourse.org/t/deploy-discourse-to-an-ubuntu-vps-using-capistrano/6353

require 'bundler/capistrano'
require 'sidekiq/capistrano'
require 'capistrano-rbenv'

# Repo Settings
# You should change this to your fork of discourse
set :repository, 'git@github.com:mayank2707/discourse.git'
set :deploy_via, :remote_cache
set :branch, fetch(:branch, 'development')
set :scm, :git
ssh_options[:forward_agent] = true

set :rbenv_ruby, '2.0.0-p247'
set :scm, :git
set :deploy_via, :remote_cache
set :git_enable_submodules, 1
set :rbenv_ruby_version, "1.9.3-p448"

# General Settings
set :deploy_type, :deploy
set :deploy_via, :remote_cache

default_run_options[:pty] = true
set :bundle_cmd, 'bundle'
# Server Settings
set :user, 'fiverroot'
set :use_sudo, false
set :rails_env, :production

role :app, '23.96.16.34', primary: true
role :db,  '23.96.16.34', primary: true
role :web, '23.96.16.34', primary: true

# Application Settings
set :application, 'discourse'
set :deploy_to, "/var/www/#{application}"

# Perform an initial bundle
after "deploy:setup" do
  run "cd #{current_path} && bundle install"
end

# Tasks to start/stop/restart thin
namespace :deploy do
   [:start, :stop].each do |t|
    desc "#{t} task is a no-op with mod_rails"
    task t, :roles => :app do ;
  end
  # desc 'Start thin servers'
  # task :start, :roles => :app, :except => { :no_release => true } do
  #   run "cd #{current_path} && RUBY_GC_MALLOC_LIMIT=90000000 bundle exec thin -C config/thin.yml start", :pty => false
  # end

  # desc 'Stop thin servers'
  # task :stop, :roles => :app, :except => { :no_release => true } do
  #   run "cd #{current_path} && bundle exec thin -C config/thin.yml stop"
  # end

  # desc 'Restart thin servers'
  # task :restart, :roles => :app, :except => { :no_release => true } do
  #   run "cd #{current_path} && RUBY_GC_MALLOC_LIMIT=90000000 bundle exec thin -C config/thin.yml restart"
  # end
end

desc "Bundle gems"
task :bundle_install do
  run "cd #{current_path} && bundle install"
end

desc "Restarting mod_rails with restart.txt"
task :restart, :roles => :app, :except => { :no_release => true } do
  run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
end

task :link_db, :roles => :app do
  run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
  run "ln -nfs #{shared_path}/config/redis.yml #{release_path}/config/redis.yml"
  run "ln -nfs #{shared_path}/config/production.rb #{release_path}/config/environments/production.rb"
  run "ln -nfs #{shared_path}/config/secret_token.rb #{release_path}/config/initializers/secret_token.rb"
end
end

# after "deploy:restart", "resque:restart"
# after "deploy:finalize_update", "bundle:install"
before 'deploy:assets:precompile', 'deploy:link_db'
after "deploy:update", "deploy:cleanup"


# Symlink config/nginx.conf to /etc/nginx/sites-enabled. Make sure to restart
# nginx so that it picks up the configuration file.
namespace :config do
  # task :nginx, roles: :app do
  #   puts "Symlinking your nginx configuration..."
  #   sudo "ln -nfs #{release_path}/config/nginx.conf /etc/nginx/sites-enabled/#{application}"
  # end
end

# after "deploy:setup", "config:nginx"

# Seed your database with the initial production image. Note that the production
# image assumes an empty, unmigrated database.
# namespace :db do
#   desc 'Seed your database for the first time'
#   task :seed do
#     run "cd #{current_path} && psql -d discourse_production < pg_dumps/production-image.sql"
#   end
# end

# Migrate the database with each deployment
after  'deploy:update_code', 'deploy:migrate'
