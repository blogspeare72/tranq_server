class CreateRules < ActiveRecord::Migration
  def change
    create_table :rules do |t|
      t.string :name
      t.string :code
      t.text :description
      t.integer :sequence
      t.text :rule_code

      t.timestamps
    end
  end
end
