class CreateDailyEntries < ActiveRecord::Migration
  def self.up
    create_table :daily_entries do |t|
      t.date :created_on
      t.float :open_price
      t.float :close_price
      t.float :high_price
      t.float :low_price
      t.references :stock

      t.timestamps
    end
  end

  def self.down
    drop_table :daily_entries
  end
end
