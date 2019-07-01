Sequel.migration do
  change do
    alter_table :sidecars do
      add_column :memory_in_mb, Integer, default: 0
    end
  end
end
