class CreateModels < ActiveRecord::Migration[5.2]
  def change
    create_table :servers do |t|
      t.timestamps null: false
      t.string :domain, null: false
      t.integer :api_type, null: false
      t.string :username, null: false
      t.string :auth, null: false
    end

    create_table :orders do |t|
      t.timestamps null: false
      t.integer :user_id, null: false
      t.integer :server_from_id, null: false
      t.integer :server_to_id, null: false
      t.string :url
      t.integer :url_type, null: false
      t.integer :url_id, null: false
      t.integer :pool_id
      t.integer :status, null: false
      t.string :message
      t.string :pools
    end

    create_table :users do |t|
      t.string :name, null: false
      t.string :encrypted_password, null: false
    end

    # create_table :sessions, id: false, primary_key: :id do |t|
    #   t.string :id
    #   t.string :sessionid, limit: 32
    #   t.datetime :expires
    #   t.references :user
    # end
  end
end
