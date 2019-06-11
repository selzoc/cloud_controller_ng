Sequel.migration do
  change do
    alter_table :processes do
      add_column :managed_by, String, size: 255, default: 'SYSTEM'
    end
  end
end
