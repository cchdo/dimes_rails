namespace :db do
    desc 'Fix zips that were saved for each file inside them'
    task :fix_zips => :environment do
        if Rails.env != 'production'
            $stderr.puts 'This task is not running in the production environment "RAILS_ENV=production"'
        end

        directories = [
            "/RAFOS/netCDF_format",
        ]

        uploads = Upload.find(:all, :conditions => ["directory IN (?)", directories])
        for uuu in uploads
            path = uuu.public_filename
            puts path
            begin
                Zip::ZipFile.open(path) do |zfile|
                    inner_path = File.join(File.basename(uuu.directory), uuu.filename)
                    zfile.get_input_stream(inner_path) do |istr|
                        uuu.set_temp_data(istr.read())
                        uuu.save
                    end
                end
            rescue Zip::ZipError => err
                puts err.inspect
                puts "likely not a zip file, skip."
            rescue Errno::ENOENT => err
                puts err.inspect
                Zip::ZipFile.open(path) {|zfile| puts zfile.entries.map {|x| x.name} }
            end
        end
    end
end
