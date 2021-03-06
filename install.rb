require 'fileutils'
RAILS_ROOT = File.dirname(__FILE__) + "/../../../" unless defined? RAILS_ROOT
 
def copy_files(source_path, destination_path, directory)
  source, destination = File.join(directory, source_path), File.join(RAILS_ROOT, destination_path)
  FileUtils.mkdir(destination) unless File.exist?(destination)
  FileUtils.cp_r(Dir.glob(source+'/*'), destination, 
                 {:remove_destination => true, :verbose => true})
end

directory = File.dirname(__FILE__)
copy_files("/public/css", "/public/css", directory)
copy_files("/public/javascripts", "/public/javascripts", directory)
copy_files("/app/views/activejquery", "/app/views/activejquery", directory)


