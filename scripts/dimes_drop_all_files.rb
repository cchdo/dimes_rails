#!/usr/bin/env /srv/dimes/script/runner
#
# Drop all files
#

Upload.all.each do |u|
    u.destroy
end
