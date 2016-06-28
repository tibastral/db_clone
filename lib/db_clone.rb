require "db_clone/version"

class DbClone < Rails::Railtie
  rake_tasks do
    load 'tasks/db_clone.rake'
  end
end
