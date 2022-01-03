class CreateJoinTableCollectionsBooks < ActiveRecord::Migration[6.1]
  def change
    create_join_table :collections, :books do |t|
      # t.index [:collection_id, :book_id]
      # t.index [:book_id, :collection_id]
    end
  end
end
