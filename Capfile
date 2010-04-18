load 'deploy' if respond_to?(:namespace)

set :application,       "usesthis.com"
set :branch,            "master"
set :deploy_to,         "/usr/local/www/#{application}"
set :deploy_via,        :remote_cache
set :repository,        "git@github.com:waferbaby/usesthis.git"
set :runner,            "d"
set :scm,               :git
set :user,              "d"
set :use_sudo,          false

role :app, "usesthis.com"
role :web, "usesthis.com"

namespace :deploy do
    %w(start stop restart).each do |action|
        task action.to_sym do
            find_and_execute_task("thin:#{action}")
        end
    end
    
    task :restart, :roles => :app do
        deploy.stop
        deploy.start
    end
    
    task :symlink_shared do
        run "ln -nfs #{shared_path}/conf/settings.yml #{deploy_to}/current/conf/settings.yml"
        run "ln -nfs /usr/local/www/shared/fonts/ #{deploy_to}/current/public/fonts"
    end
end

namespace :thin do
    %w(start stop restart).each do |action|
        task action.to_sym, :roles => :app do
            run "/var/lib/gems/1.8/bin/thin #{action} -C #{deploy_to}/current/conf/thin.yml"
        end
    end
end

namespace :sync do
    task :images do
        run "cd #{deploy_to}/current/public/images && git pull"
    end
end

after "deploy:symlink", "deploy:symlink_shared"