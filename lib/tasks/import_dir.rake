require 'fileutils'

def walk(dir, &block)
    Dir.foreach(dir) do |name|
        if name == '.' or name == '..'
            next
        end
        path = File.join(dir, name)
        if File.directory?(path)
            walk(path, &block)
        else
            yield(path)
        end
    end
end

namespace :db do
    desc 'Import directory'
    task :import_dir => :environment do
        if Rails.env != 'production'
            $stderr.puts 'WARN not in production environment: RAILS_ENV=production"'
        end

        dir = ARGV[1]
        basedir = ARGV[2]

        user_dimes = User.first(:conditions => {:login => 'dimes'})

        puts "Importing #{dir} as #{basedir}"
        walk(dir) do |path|
            relpath = path.sub(dir, '')
            while relpath.start_with?('/')
                relpath = relpath.slice(1..-1)
            end

            short_dir = File.join("/", basedir, File.dirname(relpath))
            basename = File.basename(relpath)

            if Upload.exists?(:directory => short_dir, :filename => basename)
                puts "skipping already present file #{relpath}"
                next
            end

            $stderr.puts "Uploading #{relpath} to #{short_dir}"

            upload = Upload.new()
            upload.public = false
            upload.directory = short_dir

            fh = File.open(path)
            upload.set_temp_data(fh.read())
            fh.close

            upload.content_type = Mime::Type.lookup_by_extension(File.extname(basename).downcase.tr('.', '')) || 'application/octet-stream'
            upload.filename = basename
            upload.user = user_dimes

            upload.save
        end
    end
end
