class CreateUploads < ActiveRecord::Migration
  def self.up
    create_table :uploads do |t|
      t.references :user
      t.text :description
      t.boolean :public, :default => false, :null => false
      t.integer :size, :null => false
      t.string :filename, :null => false
      t.string :content_type, :null => false
      t.timestamp :created_at
    end
  end

  def self.down
    drop_table :uploads
  end
end
