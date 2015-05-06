class CreateRuns < ActiveRecord::Migration
  def change
    create_table :runs do |t|
      t.string :status

      t.timestamps
    end
  end
end
