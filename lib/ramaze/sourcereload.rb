#          Copyright (c) 2006 Michael Fellinger m.fellinger@gmail.com
# All files in this distribution are subject to the terms of the Ruby license.

require 'set'

module Ramaze
  class SourceReload
    attr_accessor :thread, :interval, :reload_glob, :map

    # Take interval and a regular expression for files that are going to be reloaded.
    def initialize interval = 1, reload_glob = %r{(^\./)|#{Dir.pwd}|ramaze}
      @interval, @reload_glob = interval, reload_glob
      @map, @files, @paths = [], [], []
      @mtimes = {}
    end

    # start reloader-thread and assign it to this instance.
    def start
      Inform.debug("initialize automatic source reload every #{interval} seconds")
      @thread = reloader
    end

    # Takes value of Global.sourcereload and unless it's false calls #start
    def self.startup options = {}
      interval = Global.sourcereload
      instance = new(interval)
      Thread.main[:sourcereload] = instance
      instance.reload # initial scan of all files
      instance.start if interval
    end

    # Start reload loop in separate Thread
    def reloader
      Thread.new do
        loop do
          reload
          sleep(@interval)
        end
      end
    end

    # One iteration of reload will look for files that changed since the last iteration
    # and will try to #safe_load it.
    # This method is quite handy if you want direct control over when your code is reloaded
    #
    # Usage example:
    #
    # trap :HUB do
    #   Ramaze::Inform.info "reloading source"
    #   Thread.main[:sourcereload].reload
    # end
    #

    def reload
      SourceReloadHooks.before_reload
      all_reload_files.each do |file|
        mtime = mtime(file)

        next if (@mtimes[file] ||= mtime) == mtime

        Inform.debug("reload #{file}")
        @mtimes[file] = mtime if safe_load(file)
      end
      SourceReloadHooks.after_reload
    end

    # Scans loaded features and paths for file-paths, filters them in the end
    # according to the @reload_glob
    def all_reload_files
      files, paths = $LOADED_FEATURES, Array['', './', *$LOAD_PATH]

      unless [@files, @paths] == [files, paths]
        @files, @paths = files.dup, paths.dup

        map = files.map do |file|
          possible = paths.map{|pa| File.join(pa.to_s, file.to_s) }
          possible.find{|po| File.exists?(po) }
        end

        @map = map.compact
      end

      m = @map.grep(@reload_glob)
    end

    # Safe mtime
    def mtime(file)
      File.mtime(file)
    rescue Errno::ENOENT
      false
    end

    # A safe Kernel::load, issuing the SourceReloadHooks dependin on the result.
    def safe_load(file)
      SourceReloadHooks.before_safe_load(file)
      load(file)
      SourceReloadHooks.after_safe_load_succeed(file)
      true
    rescue Object => ex
      SourceReloadHooks.after_safe_load_failed(file, ex)
      false
    end
  end

  # Holds hooks that are called before and after #reload and #safe_load

  module SourceReloadHooks
    module_function

    # Overwrite to add actions before the reload cycle is started.

    def before_reload
    end

    # Overwrite to add actions after the reload cycle has ended.

    def after_reload
    end

    # Overwrite to add actions before a file is Kernel::load-ed

    def before_safe_load(file)
    end

    # Overwrite to add actions after a file is Kernel::load-ed successfully,
    # by default we clean the Cache for compiled templates and resolved actions.

    def after_safe_load_succeed(file)
      Cache.compiled.clear
      Cache.resolved.clear
    end

    # Overwrite to add actions after a file is Kernel::load-ed unsuccessfully,
    # by default we output an error-message with the exception.

    def after_safe_load_failed(file, error)
      Inform.error(error)
    end
  end
end
