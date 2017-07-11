class CreateUnits < ActiveRecord::Migration[5.0]
  def change
    create_table :units do |t|
      t.string :code
      t.string :name

      t.timestamps null: false
    end
  end
end
