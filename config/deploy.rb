set :stages, %w(staging production)
set :default_stage, "staging"
require File.expand_path("#{File.dirname(__FILE__)}/../vendor/gems/capistrano-ext-1.2.1/lib/capistrano/ext/multistage")

namespace :delayed_job do
  desc "Start delayed_job process" 
  task :start, :roles => :app do
    run "cd #{current_path}; script/delayed_job start RAILS_ENV=#{rails_env}" 
  end

  desc "Stop delayed_job process" 
  task :stop, :roles => :app do
    run "cd #{current_path}; script/delayed_job stop RAILS_ENV=#{rails_env}" 
  end

  desc "Restart delayed_job process" 
  task :restart, :roles => :app do
    run "cd #{current_path}; script/delayed_job restart RAILS_ENV=#{rails_env}" 
  end
end

after "deploy:start", "delayed_job:start" 
after "deploy:stop", "delayed_job:stop" 
after "deploy:restart", "delayed_job:restart" 

namespace :solr do
  desc "Start solr process" 
  task :start, :roles => :app do
    run "cd #{latest_release} && #{rake} solr:start RAILS_ENV=#{rails_env}  2>/dev/null"
  end
  
  desc "Stop solr process" 
  task :stop, :roles => :app do
    run "cd #{latest_release} && #{rake} solr:stop RAILS_ENV=#{rails_env} 2>/dev/null"
  end

  desc "Restart solr process" 
  task :restart, :roles => :app do
    solr.stop
    solr.start
  end
end

after "deploy:start", "solr:start" 
after "deploy:stop", "solr:stop" 
after "deploy:restart", "solr:restart"

namespace :db do
  desc 'Dumps the production database to db/production_data.sql on the remote server'
  task :remote_db_dump, :roles => :db, :only => { :primary => true } do
    run "cd #{deploy_to}/#{current_dir} && " +
      "rake RAILS_ENV=#{rails_env} db:database_dump --trace;"  +
      "tar cvzf db/production_data.sql.tgz db/production_data.sql"
  end

  desc 'Downloads db/production_data.sql from the remote production environment to your local machine'
  task :remote_db_download, :roles => :db, :only => { :primary => true } do  
    execute_on_servers(options) do |servers|
      
      self.sessions[servers.first].sftp.connect do |tsftp|
        tsftp.download!("#{deploy_to}/#{current_dir}/db/production_data.sql.tgz", "production_data.sql.tgz")
      end
    end
  end

  desc 'Cleans up data dump file'
  task :remote_db_cleanup, :roles => :db, :only => { :primary => true } do
    execute_on_servers(options) do |servers|
      self.sessions[servers.first].sftp.connect do |tsftp|
        tsftp.remove! "#{deploy_to}/#{current_dir}/db/production_data.sql.tgz" 
        tsftp.remove! "#{deploy_to}/#{current_dir}/db/production_data.sql" 
      end
    end
  end 

  desc 'Dumps, downloads and then cleans up the production data dump'
  task :remote_db_runner do
    remote_db_dump
    remote_db_download
    remote_db_cleanup
  end
end