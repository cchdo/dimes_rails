#!/usr/bin/env /srv/dimes/script/runner --environment=production
#
# Import a directory into the DIMES file repository
# Run this script using <rails app>/script/runner
#

require 'action_controller'
require 'action_controller/test_process.rb'
require 'find'

$root = 'dimes_static/uploads'
$dimes_user = User.find_by_login('dimes')

puts Rails.env
puts $dimes_user.login

def upload_file(path, dir, filename)
    mimetype = `file --brief --mime-type #{path}`.gsub(/\n/, "")
    size = File.size(path)
    mtime = File.mtime(path)

    # This will "upload" the file at path and create the new model.
    u = Upload.new(
        :description => nil, :public => true, :directory => dir,
        :filename => filename, :user => $dimes_user, :created_at => mtime,
        :uploaded_data => ActionController::TestUploadedFile.new(path, mimetype))
    print "#{filename} "
    if u.save
        puts 'success'
    else
        puts u.errors.each_full {|msg| p msg}
    end
end


def shorten(dir)
    '/' + (dir[($root.length + 1)..dir.length] || '')
end


#dir_blacklist = ['/cgi-bin', '/uploads', '/cruise1', '/cruise2', '/cruise3', '/pop', '/outreach', '/manuscripts']
dir_blacklist = ['/cgi-bin']
blacklist = ['Thumbs.db']
Find.find($root) do |path|
    if FileTest.directory?(path)
        Find.prune if dir_blacklist.include?(shorten(path))
        next
    end
    directory, filename = File.split(path)
    directory = shorten(directory)

    next if blacklist.include?(filename)

    upload_file(path, directory, filename)
end
