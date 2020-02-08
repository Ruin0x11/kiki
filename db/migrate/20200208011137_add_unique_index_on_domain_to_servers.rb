class AddUniqueIndexOnDomainToServers < ActiveRecord::Migration[5.2]
  def change
    add_index :servers, :domain, unique: true
  end
end
