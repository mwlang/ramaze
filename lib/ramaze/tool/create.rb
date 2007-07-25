#          Copyright (c) 2006 Michael Fellinger m.fellinger@gmail.com
# All files in this distribution are subject to the terms of the Ruby license.

require 'fileutils'
require 'yaml'

module Ramaze
  module Tool

    # Create is a simple class used to create new projects based on the proto
    # directory.
    #
    # It is primarly used for this command:
    #
    #   ramaze --create project
    #
    # where project is the directory you want the content put into.

    class Create
      class << self

        # a method to create a new project by copying the contents of lib/proto
        # to the position you specify (project)
        #
        # It is just a nice wrapper showing you what files/directories are put
        # in place.

        def create project
          @basedir = ::Ramaze::BASEDIR / 'proto'
          @destdir = Dir.pwd / project

          puts "Creating project #{project}"

          FileUtils.mkdir_p(project)

          puts "Copying skeleton project to new project (#@destdir)..."

          directories, files =
            Dir[@basedir / '**' / '*'].partition{ |f| File.directory?(f) }

          create_dirs(*directories)
          copy_files(*files)

        end

        # create the directories recursivly

        def create_dirs(*dirs)
          dirs.each do |dir|
            dest = dir.gsub(@basedir, @destdir)

            puts "Create directory: '#{dest}'"
            FileUtils.mkdir_p(dest)
          end
        end

        # copy the files over

        def copy_files(*files)
          files.each do |file|
            dest = file.gsub(@basedir, @destdir)

            puts "Copy file: '#{dest}'"
            FileUtils.cp(file, dest)
          end
        end
      end
    end
  end
end
