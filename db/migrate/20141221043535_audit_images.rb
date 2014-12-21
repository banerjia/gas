class AuditImages < ActiveRecord::Migration
  def change
	create_table :audit_images, id: false do |t|
		t.references :imageable, polymorphic: true, index: true
		t.string :image_type, nil: false, default: 'jpeg', size: 20
		t.string :file, nil: false, size: 255

		t.timestamps
	end

	execute <<-SQL
	ALTER TABLE `audit_images`
	MODIFY COLUMN `imageable_id` bigint unsigned not null
	SQL


  end
end
