set :stages, %w(staging production)
set :default_stage, "staging"
require File.expand_path("#{File.dirname(__FILE__)}/../vendor/gems/capistrano-ext-1.2.1/lib/capistrano/ext/multistage")

namespace :ferret do
  desc "Restart the ferret server instance"
  task :restart  do
    run "cd #{deploy_to}/#{current_dir} && " +
    "./script/ferret_server --root='./' -e #{rails_env} stop; "  +
    "./script/ferret_server --root='./' -e #{rails_env} start; " 
  end
  desc "Start the ferret server instance"
  task :start do
    run "cd #{deploy_to}/#{current_dir} && " +
    "./script/ferret_server --root='./' -e #{rails_env} stop; " 
  end
  desc "Stop the ferret server instance"
  task :start do
    run "cd #{deploy_to}/#{current_dir} && " +
    "./script/ferret_server --root='./' -e #{rails_env} start; " 
  end
end



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