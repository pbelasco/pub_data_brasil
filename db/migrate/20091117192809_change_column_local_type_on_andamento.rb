class ChangeColumnLocalTypeOnAndamento < ActiveRecord::Migration
  def self.up
    change_column :andamentos, :local, :text
  end

  def self.down
    change_column :andamentos, :local, :string
  end
end
