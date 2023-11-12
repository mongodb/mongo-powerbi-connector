let
    Source = MongoDBAtlasODBC.Contents("mongodb://localhost", "reports", []),
    reports_Database = Source{[Name="reports",Kind="Database"]}[Data],
    table_ops_Table = reports_Database{[Name="table_ops",Kind="Table"]}[Data],
    #"Filtered Rows" = Table.SelectRows(table_ops_Table, each [bool0] = true),
    #"Filtered Rows1" = Table.SelectRows(#"Filtered Rows", each [num0] > -1),
    #"Filtered Rows2" = Table.SelectRows(#"Filtered Rows1", each [str0] = "hello"),
    #"Filtered Rows3" = Table.SelectRows(#"Filtered Rows2", each [int0] < 150)
in
    #"Filtered Rows3"
