class CommentsModel < ActiveRecord::Migration
  def up
	create_table :comments, id:false do |t|
		t.references :commentable, polymorphic: true, index: true
		t.text :content
		t.timestamps
	end

	execute <<-SQL
		ALTER TABLE `comments`
			MODIFY COLUMN `commentable_id` bigint unsigned not null,
			MODIFY COLUMN `commentable_type` varchar(50)
	SQL
	
  end

  def down
	drop_table :comments
  end
end
