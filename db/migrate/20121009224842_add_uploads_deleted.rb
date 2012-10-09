class AddUploadsDeleted < ActiveRecord::Migration
  def self.up
    add_column :uploads, :deleted, :boolean, :default => false
  end

  def self.down
    remove_column :uploads, :deleted
  end
end
