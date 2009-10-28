class AddIdSilegToAndamento < ActiveRecord::Migration
  def self.up
    add_column :andamentos, :id_sileg, :integer
  end

  def self.down
    remove_column :andamentos, :id_sileg
  end
end
