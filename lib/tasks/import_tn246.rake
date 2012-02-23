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
        desc 'Import DIMES TN246'
        task :import_tn246 => :environment do
                class OldUpload < ActiveRecord::Base
                    set_table_name 'uploads'
                    validates_presence_of :filename
                    validates_inclusion_of :public, :in => [true, false]
                    validates_presence_of :directory

                    belongs_to :user

                    has_attachment :storage => :file_system,
                                   :partition => false,
                                   :path_prefix => 'datafiles'
                end

                if Rails.env != 'production'
                        $stderr.puts 'This task is not running in the production environment "RAILS_ENV=production"'
                end

                puts 'Moving old files into partition'

                OldUpload.all(:conditions => ["`directory` NOT LIKE ?", "/TN246_Report%"]).each do |upload|
                        old_filepath = upload.public_filename
                        new_filepath = Upload.find(upload.id).public_filename
                        begin
                                FileUtils.mkdir_p(File.dirname(new_filepath))
                                FileUtils.mv(old_filepath, new_filepath)
                        rescue => e
                                $stderr.puts "#{old_filepath} not moved. #{e}"
                        end
                end

                puts 'Importing DIMES TN246'
                host = 'ftp.whoi.edu'
                # this is from the email
                dir = 'TN246_data'
                # this is myshen's guess from actual directory structure
                dir = 'TN246_Report'
                username = 'dimes'
                passwd = 'dimes1010'

                # I have abandoned using net/ftp to download from the server in
                # favor of using a dedicated ftp program. The server is simply
                # not responsive when using net/ftp.

                if ARGV.length < 2
                        $stderr.puts 'Please give the directory that contains all the files'
                end

                user_dimes = User.first(:conditions => {:login => 'dimes'})
                puts user_dimes.inspect

                dir = ARGV[1]

                puts "Importing #{dir}"
                walk(dir) do |path|
                        p = path.sub(dir, '')
                        while p.start_with?('/')
                                p = p.slice(1..-1)
                        end

                        short_path = File.join('/TN246_Report', p)
                        short_dir = File.dirname(short_path)
                        basename = File.basename(p)

                        if Upload.exists?(:directory => short_dir, :filename => basename)
                                puts "skipping already present file #{short_path}"
                                next
                        end

                        $stderr.puts "Uploading #{short_path}"

                        upload = Upload.new()
                        upload.public = true
                        upload.directory = short_dir

                        fh = File.open(path)
                        upload.set_temp_data(fh.read)
                        fh.close

                        upload.content_type = Mime::Type.lookup_by_extension(File.extname(basename).downcase.tr('.', '')) || 'application/octet-stream'
                        upload.filename = basename
                        upload.user = user_dimes

                        upload.save
                end
        end
end
