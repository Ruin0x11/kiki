class AddSchemeToServers < ActiveRecord::Migration[5.2]
  def change
    add_column :servers, :scheme, :string, default: "https", null: false
  end
end

