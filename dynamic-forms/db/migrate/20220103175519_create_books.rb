class CreateBooks < ActiveRecord::Migration[6.1]
  def change
    create_table :books do |t|
      t.string :name
      t.references :author, null: false, foreign_key: true

      t.timestamps
    end
    add_index :books, :name
  end
end
