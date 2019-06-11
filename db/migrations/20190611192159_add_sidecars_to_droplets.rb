Sequel.migration do
  change do
    alter_table :droplets do
      add_column :buildpack_sidecars, String, text: true
    end
  end
end
