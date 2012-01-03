class Upload < ActiveRecord::Base
    validates_presence_of :filename
    validates_inclusion_of :public, :in => [true, false]
    validates_presence_of :directory

    belongs_to :user

    has_attachment :storage => :file_system,
                   :partition => true,
                   :path_prefix => 'datafiles'
end
