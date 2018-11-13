class CreateLastReportUrl < ActiveRecord::Migration
  def change
    create_table :spree_last_reports do |t|
      t.string  :url
      t.timestamps
    end
  end
end
