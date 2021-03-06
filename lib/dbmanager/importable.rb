# Extends the runner with database importing capabilities.
#
# The import process happens in the #run method, and is eventually delegated to
# the specific database adapter which must implement the #run method. This
# adapter will receive the source and target environment plus the path for the
# sql dump file.
#
# The source and target environment must use the same adapter, ie you cannot
# import a mysql database on a sqlite3 database. For that purpose you can use
# the taps gem.

module Dbmanager
  module Importable
    def self.extended(base)
      class << base; attr_reader :target; end
    end

    def run
      @target = get_env('target')
      if target.protected?
        raise EnvironmentProtectedError
      else
        execute_import
        output.puts 'Database Import completed.'
      end
    end

    def execute_import
      adapter::Importer.new(source, target, tmp_file).run
    end

    def adapter
      raise MixedAdapterError if source.adapter != target.adapter
      Dbmanager::Adapters.const_get source.adapter.capitalize
    end

    def tmp_file
      @tmp_file ||= File.join Dbmanager.rails_root, 'tmp', Time.now.strftime('%y%m%d%H%M%S')
    end
  end
end
