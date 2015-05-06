class AddNameDescToRuns < ActiveRecord::Migration
  def change
    add_column :runs, :name, :string
    add_column :runs, :description, :string
  end
end
