class CreateCustomEmojis < ActiveRecord::Migration[8.2]
  def change
    create_table :custom_emojis do |t|
      t.references :account, null: false, foreign_key: true
      t.references :creator, null: false, foreign_key: { to_table: :users }
      t.string :name, null: false
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :custom_emojis, [ :account_id, :name ], unique: true
  end
end
