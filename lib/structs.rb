Post = Struct.new :id, :url, :source, :image_url, :tags, :rating, :parent_id, :version, keyword_init: true

WikiPage = Struct.new :id, :url, :title, :body, :other_names, keyword_init: true

Tag = Struct.new :id, :url, :name, :category, keyword_init: true

Pool = Struct.new :id, :url, :name, :description, :category, :post_ids, keyword_init: true
require "lib/result"
