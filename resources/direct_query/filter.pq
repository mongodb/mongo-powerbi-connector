let
    Source = MongoDBAtlasODBC.Contents("mongodb://localhost", "db2", []),
    db2_Database = Source{[Name="db2",Kind="Database"]}[Data],
    table_ops_Table = db2_Database{[Name="table_ops",Kind="Table"]}[Data],
    #"Filtered Rows" = Table.SelectRows(table_ops_Table, each [bool0] = true),
    #"Filtered Rows1" = Table.SelectRows(#"Filtered Rows", each [num0] > -1),
    #"Filtered Rows2" = Table.SelectRows(#"Filtered Rows1", each [str0] = "hello"),
    #"Filtered Rows3" = Table.SelectRows(#"Filtered Rows2", each [int0] < 150),
    #"Filtered Rows4" = Table.SelectRows(#"Filtered Rows3", each [date0] > #datetime(1902, 5, 23, 0, 0, 12))
in
    #"Filtered Rows4"
