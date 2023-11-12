let
    Source = MongoDBAtlasODBC.Contents("mongodb://localhost", "reports", []),
    reports_Database = Source{[Name="reports",Kind="Database"]}[Data],
    table_ops_Table = reports_Database{[Name="table_ops",Kind="Table"]}[Data],
    ret = Table.Group(table_ops_Table, {"str0", "bool0"}, {{"Count", each Table.RowCount(_), Int64.Type}, {"Sum", each List.Sum([int0]), type number}, {"Avg", each List.Average([num0]), type number}, {"Min", each List.Min([int1]), type number}, {"Max", each List.Max([int2]), type number}, {"All", each _, type table [_id=number, bool0=logical, int0=number, int1=number, int2=number, num0=number, str0=text]}})
in
    ret
