section MongoDBAtlasODBCDataSourceTests;

shared IntegrationTests = [
    uri = "mongodb://localhost/?ssl=false",
    DataSource = MongoDBAtlasODBC.Contents(uri, "integration_test_2", []),
    // Sort the sales table, and retain first row
    DataSource_Sales = Table.FirstN(
        Table.Sort(
            DataSource{[Name = "integration_test_2", Kind = "Database"]}[Data]{[Name = "sales", Kind = "Table"]}[Data],
            {{"_id", Order.Ascending}}
        ),
        1
    ),
    DataSource_Complex_Types = DataSource{
        [Name = "integration_test", Kind = "Database"]
    }[Data]{
        [Name = "complex_types", Kind = "Table"]
    }[Data],
    Sales_Row = {
        [
            _id = "{""$oid"":""5bd761dcae323e45a93ccfeb""}",
            couponUsed = false,
            customer = "{""gender"":""F"",""age"":45,""email"":""vatires@ta.pe"",""satisfaction"":3}",
            items = "[{""name"":""binder"",""tags"":[""school"",""general"",""organization""],""price"":20.08,""quantity"":1},"
                & "{""name"":""pens"",""tags"":[""writing"",""office"",""school"",""stationary""],""price"":23.08,""quantity"":4},"
                & "{""name"":""backpack"",""tags"":[""school"",""travel"",""kids""],""price"":82.73,""quantity"":2},"
                & "{""name"":""printer paper"",""tags"":[""office"",""stationary""],""price"":15.98,""quantity"":3},"
                & "{""name"":""notepad"",""tags"":[""office"",""writing"",""school""],""price"":27.24,""quantity"":4},"
                & "{""name"":""notepad"",""tags"":[""office"",""writing"",""school""],""price"":27.7,""quantity"":5},"
                & "{""name"":""pens"",""tags"":[""writing"",""office"",""school"",""stationary""],""price"":59.86,""quantity"":5},"
                & "{""name"":""binder"",""tags"":[""school"",""general"",""organization""],""price"":27.33,""quantity"":9},"
                & "{""name"":""notepad"",""tags"":[""office"",""writing"",""school""],""price"":13.59,""quantity"":1}]",
            purchaseMethod = "In store",
            saleDate = #datetime(2015, 2, 23, 9, 53, 59.343),
            storeLocation = "Seattle"
        ]
    },
    Complex_Types_Row = {
        [
            _id = "{""$oid"":""5bd761dcae323e45a93ccff4""}",
            array = "[1,2,3,{""$oid"":""000000000000000000000003""},{""$timestamp"":{""t"":200,""i"":0}}]",
            boolean = true,
            dbPointer = "{""$dbPointer"":{""$ref"":""namespace"",""$id"":{""$oid"":""000000000000000000000001""}}}",
            double = 14.96,
            integer = 100,
            javascript = "{""$code"":""function(){ }""}",
            javascriptWithScope = "{""$code"":""function(){ }"",""$scope"":{""foo"":""bar""}}",
            maxKey = "{""$maxKey"":1}",
            minKey = "{""$minKey"":1}",
            object = "{""foo"":""bar"",""objId"":{""$oid"":""000000000000000000000002""},""value"":3,""time"":{""$timestamp"":{""t"":200,""i"":0}}}",
            objectId = "{""$oid"":""000000000000000000000001""}",
            regularExpression = "{""$regularExpression"":{""pattern"":""a(bc)*"",""options"":""""}}",
            symbol = "{""$symbol"":""symbol""}",
            timestamp = "{""$timestamp"":{""t"":100,""i"":0}}"
        ]
    },
    Complex_Types_NativeTypeNames = {
        "objectId",
        "array",
        "bool",
        "dbPointer",
        "double",
        "int",
        "javascript",
        "javascriptWithScope",
        "maxKey",
        "minKey",
        "object",
        "objectId",
        "regex",
        "symbol",
        "timestamp"
    },
    facts = {
        Fact("Verify values in sales collection from navigation table", Sales_Row, Table.ToRecords(DataSource_Sales)),
        Fact(
            "Verify values in complex_types collection from navigation table",
            Complex_Types_Row,
            Table.ToRecords(DataSource_Complex_Types)
        ),
        Fact(
            "Check schema, embedded complex types are tranformed to string",
            [
                items = {"Text.Type"},
                customer = {"Text.Type"}
            ],
            [
                items = Table.SelectRows(
                    Table.Schema(DataSource_Sales), each Text.Contains([Name], "items")
                )[TypeName],
                customer = Table.SelectRows(
                    Table.Schema(DataSource_Sales), each Text.Contains([Name], "customer")
                )[TypeName]
            ]
        ),
        Fact(
            "NativeTypeName facet is retained in complex types from navigation table",
            Complex_Types_NativeTypeNames,
            Table.Schema(DataSource_Complex_Types)[NativeTypeName]
        )
    },
    report = Facts.Summarize(facts)
][report];
/// COMMON UNIT TESTING CODE - From DataConnectors/UnitTesting
Fact = (_subject as text, _expected, _actual) as record =>
    [
        expected = try _expected,
        safeExpected = if expected[HasError] then "Expected : " & @ValueToText(expected[Error]) else expected[Value],
        actual = try _actual,
        safeActual = if actual[HasError] then "Actual : " & @ValueToText(actual[Error]) else actual[Value],
        attempt = try safeExpected = safeActual,
        result = if attempt[HasError] or not attempt[Value] then "Failure ⛔" else "Success ✓",
        resultOp = if result = "Success ✓" then " = " else " <> ",
        addendumEvalAttempt = if attempt[HasError] then @ValueToText(attempt[Error]) else "",
        addendumEvalExpected = try @ValueToText(safeExpected) otherwise "...",
        addendumEvalActual = try @ValueToText(safeActual) otherwise "...",
        fact = [
            Result = result & " " & addendumEvalAttempt,
            Notes = _subject,
            Details = " (" & addendumEvalExpected & resultOp & addendumEvalActual & ")"
        ]
    ][fact];
Facts = (_subject as text, _predicates as list) => List.Transform(_predicates, each Fact(_subject, _{0}, _{1}));

Facts.Summarize = (_facts as list) as table =>
    [
        Fact.CountSuccesses = (count, i) =>
            [
                result = try i[Result],
                sum = if result[HasError] or not Text.StartsWith(result[Value], "Success") then count else count + 1
            ][sum],
        passed = List.Accumulate(_facts, 0, Fact.CountSuccesses),
        total = List.Count(_facts),
        format = if passed = total then "All #{0} Passed !!! ✓" else "#{0} Passed ☺  #{1} Failed ☹",
        result = if passed = total then "Success" else "⛔",
        rate = Number.IntegerDivide(100 * passed, total),
        header = [
            Result = result,
            Notes = Text.Format(format, {passed, total - passed}),
            Details = Text.Format("#{0}% success rate", {rate})
        ],
        report = Table.FromRecords(List.Combine({{header}, _facts}))
    ][report];

ValueToText = (value, optional depth) =>
    let
        List.TransformAndCombine = (list, transform, separator) =>
            Text.Combine(List.Transform(list, transform), separator),
        Serialize.Binary = (x) => "#binary(" & Serialize(Binary.ToList(x)) & ") ",
        Serialize.Function = (x) =>
            _serialize_function_param_type(
                Type.FunctionParameters(Value.Type(x)), Type.FunctionRequiredParameters(Value.Type(x))
            )
                & " as "
                & _serialize_function_return_type(Value.Type(x))
                & " => (...) ",
        Serialize.List = (x) => "{" & List.TransformAndCombine(x, Serialize, ", ") & "} ",
        Serialize.Record = (x) =>
            "[ "
                & List.TransformAndCombine(
                    Record.FieldNames(x),
                    (item) => Serialize.Identifier(item) & " = " & Serialize(Record.Field(x, item)),
                    ", "
                )
                & " ] ",
        Serialize.Table = (x) =>
            "#table( type " & _serialize_table_type(Value.Type(x)) & ", " & Serialize(Table.ToRows(x)) & ") ",
        Serialize.Identifier = Expression.Identifier,
        Serialize.Type = (x) => "type " & _serialize_typename(x),
        _serialize_typename = (x, optional funtype as logical) =>
            /* Optional parameter: Is this being used as part of a function signature? */ let
                isFunctionType = (x as type) =>
                    try if Type.FunctionReturn(x) is type then true else false otherwise false,
                isTableType = (x as type) => try if Type.TableSchema(x) is table then true else false otherwise false,
                isRecordType = (x as type) => try if Type.ClosedRecord(x) is type then true else false
            otherwise
                false,
                isListType = (x as type) => try if Type.ListItem(x) is type then true else false otherwise false
            in
                if funtype = null and isTableType(x) then
                    _serialize_table_type(x)
                else if funtype = null and isListType(x) then
                    "{ " & @_serialize_typename(Type.ListItem(x)) & " }"
                else if funtype = null and isFunctionType(x) then
                    "function " & _serialize_function_type(x)
                else if funtype = null and isRecordType(x) then
                    _serialize_record_type(x)
                else if x = type any then
                    "any"
                else
                    let
                        base = Type.NonNullable(x)
                    in
                        (if Type.IsNullable(x) then "nullable " else "")
                            & (
                                if base = type anynonnull then
                                    "anynonnull"
                                else if base = type binary then
                                    "binary"
                                else if base = type date then
                                    "date"
                                else if base = type datetime then
                                    "datetime"
                                else if base = type datetimezone then
                                    "datetimezone"
                                else if base = type duration then
                                    "duration"
                                else if base = type logical then
                                    "logical"
                                else if base = type none then
                                    "none"
                                else if base = type null then
                                    "null"
                                else if base = type number then
                                    "number"
                                else if base = type text then
                                    "text"
                                else if base = type time then
                                    "time"
                                else if base = type type then
                                    "type"
                                else /* Abstract types: */ if base = type function then
                                    "function"
                                else if base = type table then
                                    "table"
                                else if base = type record then
                                    "record"
                                else if base = type list then
                                    "list"
                                else
                                    "any /*Actually unknown type*/"
                            ),
        _serialize_table_type = (x) =>
            let
                schema = Type.TableSchema(x)
            in
                "table "
                    & (
                        if Table.IsEmpty(schema) then
                            ""
                        else
                            "["
                                & List.TransformAndCombine(
                                    Table.ToRecords(Table.Sort(schema, "Position")),
                                    each Serialize.Identifier(_[Name]) & " = " & _[Kind],
                                    ", "
                                )
                                & "] "
                    ),
        _serialize_record_type = (x) =>
            let
                flds = Type.RecordFields(x)
            in
                if Record.FieldCount(flds) = 0 then
                    "record"
                else
                    "["
                        & List.TransformAndCombine(
                            Record.FieldNames(flds),
                            (item) =>
                                Serialize.Identifier(item) & "=" & _serialize_typename(
                                    Record.Field(flds, item)[Type]
                                ),
                            ", "
                        )
                        & (if Type.IsOpenRecord(x) then ", ..." else "")
                        & "]",
        _serialize_function_type = (x) =>
            _serialize_function_param_type(Type.FunctionParameters(x), Type.FunctionRequiredParameters(x))
                & " as "
                & _serialize_function_return_type(x),
        _serialize_function_param_type = (t, n) =>
            let
                funsig = Table.ToRecords(
                    Table.TransformColumns(
                        Table.AddIndexColumn(Record.ToTable(t), "isOptional", 1), {"isOptional", (x) => x > n}
                    )
                )
            in
                "("
                    & List.TransformAndCombine(
                        funsig,
                        (item) =>
                            (if item[isOptional] then "optional " else "")
                                & Serialize.Identifier(item[Name])
                                & " as "
                                & _serialize_typename(item[Value], true),
                        ", "
                    )
                    & ")",
        _serialize_function_return_type = (x) => _serialize_typename(Type.FunctionReturn(x), true),
        Serialize = (x) as text =>
            if x is binary then
                try Serialize.Binary(x) otherwise "null /*serialize failed*/"
            else if x is date then
                try Expression.Constant(x) otherwise "null /*serialize failed*/"
            else if x is datetime then
                try Expression.Constant(x) otherwise "null /*serialize failed*/"
            else if x is datetimezone then
                try Expression.Constant(x) otherwise "null /*serialize failed*/"
            else if x is duration then
                try Expression.Constant(x) otherwise "null /*serialize failed*/"
            else if x is function then
                try Serialize.Function(x) otherwise "null /*serialize failed*/"
            else if x is list then
                try Serialize.List(x) otherwise "null /*serialize failed*/"
            else if x is logical then
                try Expression.Constant(x) otherwise "null /*serialize failed*/"
            else if x is null then
                try Expression.Constant(x) otherwise "null /*serialize failed*/"
            else if x is number then
                try Expression.Constant(x) otherwise "null /*serialize failed*/"
            else if x is record then
                try Serialize.Record(x) otherwise "null /*serialize failed*/"
            else if x is table then
                try Serialize.Table(x) otherwise "null /*serialize failed*/"
            else if x is text then
                try Expression.Constant(x) otherwise "null /*serialize failed*/"
            else if x is time then
                try Expression.Constant(x) otherwise "null /*serialize failed*/"
            else if x is type then
                try Serialize.Type(x) otherwise "null /*serialize failed*/"
            else
                "[#_unable_to_serialize_#]"
    in
        try Serialize(value) otherwise "<serialization failed>";
