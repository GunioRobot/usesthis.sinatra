require 'rake'

namespace :db do
    task :prepare do
        require 'datamapper'
        
        Dir.glob('lib/*') do |lib|
            require lib
        end
        
        @config = YAML.load_file(File.join('conf', 'settings.yml'))
        DataMapper.setup(:default, @config[:database])
    end
    
    desc 'Create the database tables.'
    task :migrate => :prepare do
        DataMapper.auto_migrate!
    end
    
    desc 'Upgrade the database tables.'
    task :upgrade => :prepare do
        DataMapper.auto_upgrade!
    end
end

namespace :sync do
    desc 'Syncs the images directory with the current site.'
    task :images do
        exec "rsync -rv --progress --exclude '.DS_Store' public/images/ usesthis.com:/usr/local/www/usesthis.com/current/public/images/"
    end
end