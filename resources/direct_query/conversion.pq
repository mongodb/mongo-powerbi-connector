let
    Source = MongoDBAtlasODBC.Contents("mongodb://localhost", "db2", []),
    db2_Database = Source{[Name="db2",Kind="Database"]}[Data],
    transforms_Table = db2_Database{[Name="transforms",Kind="Table"]}[Data],
    #"Changed Type" = Table.TransformColumnTypes(transforms_Table,{
        {"bool0", Int64.Type},
        {"bool1", type text},
        {"bool2", type logical},
        {"int0", Int64.Type},
        {"int1", type text},
        {"int2", type logical},
        {"int3", type datetime},
        {"num0", Int64.Type},
        {"num1", type text},
        {"num2", type logical},
        {"date0", type datetime},
        {"date1", type text},
        {"str1", type logical},
        {"str2", type text},
        {"str3", Int64.Type}
    })
in
    #"Changed Type"
