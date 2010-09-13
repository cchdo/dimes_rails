class Upload < ActiveRecord::Base
    validates_presence_of :filename
    validates_presence_of :public
    validates_presence_of :directory

    belongs_to :user

    has_attachment :storage => :file_system,
                   :partition => false,
                   :path_prefix => 'datafiles'
end
