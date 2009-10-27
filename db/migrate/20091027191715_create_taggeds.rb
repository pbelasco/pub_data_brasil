class CreateTaggeds < ActiveRecord::Migration
  def self.up
    create_table :taggeds do |t|
      t.references :tag
      t.references :proposicao

      t.timestamps
    end
  end

  def self.down
    drop_table :taggeds
  end
end
