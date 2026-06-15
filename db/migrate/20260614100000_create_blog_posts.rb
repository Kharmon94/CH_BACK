# frozen_string_literal: true

class CreateBlogPosts < ActiveRecord::Migration[8.0]
  def change
    create_table :blog_posts do |t|
      t.string :title, null: false
      t.string :slug, null: false
      t.text :excerpt
      t.text :body
      t.integer :status, null: false, default: 0
      t.datetime :published_at
      t.string :meta_title
      t.string :meta_description
      t.references :author, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :blog_posts, :slug, unique: true
    add_index :blog_posts, :status
    add_index :blog_posts, :published_at
  end
end
