let
    Source = MongoDBAtlasODBC.Contents("mongodb://localhost", "reports", []),
    reports_Database = Source{[Name="reports",Kind="Database"]}[Data],
    transforms_Table = reports_Database{[Name="transforms",Kind="Table"]}[Data],
    #"Lowercased Text" = Table.TransformColumns(transforms_Table,{
        {"str0", Text.Lower, type text},
        {"str1", Text.Upper, type text},
        {"str2", Text.Length, type text},
        {"num0", each Number.Round(_, 5), type number},
        {"num1", Number.RoundUp, type number},
        {"num2", Number.Abs, type number},
        {"num3", Number.Log10, type number},
        {"num4", each Number.Power(_, 15), type number},
        {"num5", each Number.Power(_, 2), type number},
        {"num6", each Number.Power(_, 3), type number},
        {"num7", Number.Sqrt, type number}
    }),
    #"Replaced Value" = Table.ReplaceValue(#"Lowercased Text","4","hello",Replacer.ReplaceText,{"str3"}),
    #"Replaced Value 2" = Table.ReplaceValue(#"Replaced Value", 1.7E-27, 42.5, Replacer.ReplaceValue, {"num8"})
in
    #"Replaced Value 2"
