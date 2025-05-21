let
    Source = MongoDBAtlasODBC.Contents("mongodb://localhost", "db2", []),
    db2_Database = Source{[Name="db2",Kind="Database"]}[Data],
    table_ops_Table = db2_Database{[Name="table_ops",Kind="Table"]}[Data],
    m = Table.NestedJoin(table_ops_Table, {"int0"}, table_ops_Table, {"int1"}, "table_ops2", JoinKind.Inner),
    ret = Table.ExpandTableColumn(m, "table_ops2",
      {
            "_id",
            "bool0",
            "str0",
            "int0",
            "int1",
            "int2",
            "num0"
      },
      {
            "t._id",
            "t.bool0",
            "t.str0",
            "t.int0",
            "t.int1",
            "t.int2",
            "t.num0"
      }
    )
in
    ret
