class AddDataToRuns < ActiveRecord::Migration
  def change
    add_column :runs, :api_descriptor, :text
    add_column :runs, :control_file, :text
    add_column :runs, :oauth, :text
  end
end
