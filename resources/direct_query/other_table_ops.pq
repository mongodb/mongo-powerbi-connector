let
    Source = MongoDBAtlasODBC.Contents("mongodb://localhost", "reports", []),
    reports_Database = Source{[Name="reports",Kind="Database"]}[Data],
    table_ops_Table = reports_Database{[Name="table_ops",Kind="Table"]}[Data],
    #"Sorted Rows" = Table.Sort(table_ops_Table,{{"bool0", Order.Ascending}, {"_id", Order.Descending}}),
    #"Kept Duplicates" = let columnNames = {"bool0"}, addCount = Table.Group(#"Sorted Rows", columnNames, {{"Count", Table.RowCount, type number}}), selectDuplicates = Table.SelectRows(addCount, each [Count] > 1), removeCount = Table.RemoveColumns(selectDuplicates, "Count") in Table.Join(#"Sorted Rows", columnNames, removeCount, columnNames, JoinKind.Inner),
    #"Kept First Rows" = Table.FirstN(#"Kept Duplicates",10),
    #"Kept Range of Rows" = Table.Range(#"Kept First Rows",1,8),
    #"Removed Top Rows" = Table.Skip(#"Kept Range of Rows",1),
    #"Removed Columns" = Table.RemoveColumns(#"Removed Top Rows",{"num0"}),
    #"Removed Other Columns" = Table.SelectColumns(#"Removed Columns",{"bool0", "int1"}),
    #"Duplicated Column" = Table.DuplicateColumn(#"Removed Other Columns", "bool0", "bool0 - Copy"),
    #"Removed Other Columns1" = Table.SelectColumns(#"Duplicated Column",{"bool0"})
in
    #"Removed Other Columns1"
