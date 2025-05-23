let
    Source = MongoDBAtlasODBC.Contents("mongodb://localhost", "db2", []),
    db2_Database = Source{[Name="db2",Kind="Database"]}[Data],
    table_ops_Table = db2_Database{[Name="table_ops",Kind="Table"]}[Data],
    ret = Table.Group(table_ops_Table, {"str0", "bool0"}, {{"Count", each Table.RowCount(_), Int64.Type}, {"Sum", each List.Sum([int0]), type number}, {"Avg", each List.Average([num0]), type number}, {"Min", each List.Min([int1]), type number}, {"Max", each List.Max([int2]), type number}})
in
    ret
