class Upload < ActiveRecord::Base
    validates_presence_of :filename

    has_attachment :storage => :file_system,
                   :partition => false,
                   :path_prefix => 'datafiles'
end
