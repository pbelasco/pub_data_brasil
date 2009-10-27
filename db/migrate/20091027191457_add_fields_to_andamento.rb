class AddFieldsToAndamento < ActiveRecord::Migration
  def self.up
    add_column :andamentos, :media_link, :string
    add_column :andamentos, :local, :string
  end

  def self.down
    remove_column :andamentos, :local
    remove_column :andamentos, :media_link
  end
end
