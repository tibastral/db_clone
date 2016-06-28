require 'active_record/connection_adapters/postgresql_adapter'
module ActiveRecord
  module ConnectionAdapters
    class PostgreSQLAdapter < AbstractAdapter
      def drop_database(name)
        raise "Nah, I won't drop the production database" if Rails.env.production?
        execute <<-SQL
          UPDATE pg_catalog.pg_database
          SET datallowconn=false WHERE datname='#{name}'
        SQL

        execute <<-SQL
          SELECT pg_terminate_backend(pg_stat_activity.pid)
          FROM pg_stat_activity
          WHERE pg_stat_activity.datname = '#{name}';
        SQL
        execute "DROP DATABASE IF EXISTS #{quote_table_name(name)}"
      end
    end
  end
end

namespace :db do
  desc "Import the last production backup into local db"
  task import_last_backup: :environment do
    Rake::Task['db:drop'].invoke
    Rake::Task['db:create'].invoke
    system "pg_restore -O -x -d #{Rails.configuration.database_configuration[Rails.env]['database']} tmp/latest.dump"
    Rake::Task['db:migrate'].invoke
  end

  desc "Clone the production db into local db"
  task clone_prod: :environment do
    system 'heroku pg:backups capture --remote heroku'
    system 'curl -o tmp/latest.dump `heroku pg:backups --remote heroku public-url`'
    Rake::Task['db:import_last_backup'].invoke
  end
end
