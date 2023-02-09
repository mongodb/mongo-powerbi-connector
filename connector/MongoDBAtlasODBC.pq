[Version = "0.0.0"]
section MongoDBAtlasODBC;

[DataSource.Kind = "MongoDBAtlasODBC", Publish = "MongoDBAtlasODBC.Publish"]
shared MongoDBAtlasODBC.Contents = Value.ReplaceType(MongoDBAtlasODBCImpl, MongoDBAtlasODBCType);

MongoDBAtlasODBCType = type function (
    mongodbUri as (
        type text meta [
            Documentation.FieldCaption = "MongoDB URI",
            Documentation.FieldDescription = "MongoDB connection URI",
            Documentation.SampleValues = {"mongodb://hostname:port/?ssl=true&authSource=admin"}
        ]
    ),
    database as (
        type text meta [
            Documentation.FieldCaption = "Database",
            Documentation.FieldDescription = "Database to connect to",
            Documentation.SampleValues = {"db"}
        ]
    ),
    optional query as (
        type text meta [
            Documentation.FieldCaption = "SQL Statement",
            Documentation.SampleValues = {"SELECT * FROM table"},
            Formatting.IsMultiLine = true,
            Formatting.IsCode = true
        ]
    ),
    optional options as record
) as table meta [
    Documentation.Name = "MongoDB Atlas SQL"
];

MongoDBAtlasODBCImpl = (mongodbUri as text, database as text, optional query as text, optional options as record) as table =>
    let
        ConnectionString = GetConnectionString(mongodbUri, database),
        CredentialConnectionString = GetCredentialConnectionString(),
        Config = BuildOdbcConfig(),
        DataSource =
            if query <> null then
                Odbc.Query(ConnectionString, query, [CredentialConnectionString = CredentialConnectionString])
            else
                Odbc.DataSource(ConnectionString, Config & [CredentialConnectionString = CredentialConnectionString]),
        Metadata = Value.Metadata(Value.Type(DataSource)),
        TransformColumns =
            let
                TransformColumns =
                    if query <> null then
                        TransformSqlUnknownColumns(DataSource)
                    else
                        TransformColumnKeepType(
                            DataSource,
                            "Data",
                            (tables) => TransformColumnKeepType(tables, "Data", TransformSqlUnknownColumns)
                        )
            in
                TransformColumns,
        WithMetadata = Value.ReplaceType(TransformColumns, Value.ReplaceMetadata(Value.Type(DataSource), Metadata))
    in
        Table.ChangeType(TransformColumns, Value.Type(TransformColumns));

GetCredentialConnectionString = () as record =>
    let
        Credential = Extension.CurrentCredential(),
        CredentialConnectionString = [
            UID = Credential[Username],
            PWD = Credential[Password]
        ]
    in
        CredentialConnectionString;

// Transforms the columns that the driver specifies as SQL_UNKNOWN_TYPE from binary to text values
shared TransformSqlUnknownColumns = (table) =>
    let
        Schema = Table.Schema(table),
        SqlBinaryTypes = Table.ToRecords(
            Table.SelectRows(Schema, each [TypeName] = "Binary.Type" and [NativeTypeName] <> "binData")
        ),
        TransformOperations = List.Accumulate(
            SqlBinaryTypes,
            table,
            (state, column) =>
                let
                    TransformColumn = Table.TransformColumns(
                        state, {column[Name], Text.FromBinary, type text}, null, MissingField.UseNull
                    )
                in
                    TransformColumn
        )
    in
        TransformOperations;

// Executes operation on specified columnName of the passed in table
shared TransformColumnKeepType = (table, columnName, operation) =>
    let
        TableType = Value.Type(table),
        TransformColumn = Table.TransformColumns(table, {columnName, operation}),
        ReplaceType = Value.ReplaceType(TransformColumn, TableType)
    in
        ReplaceType;

shared GetConnectionString = (uri as text, database as text) as record =>
    let
        DatabaseNotSet = (database = ""),
        ConnectionString = [
            DRIVER = "ADF_ODBC_DRIVER",
            DATABASE = database,
            URI = uri
        ]
    in
        if DatabaseNotSet then
            error "Database value cannot be empty"
        else
            ConnectionString;

// Data Source Kind description
MongoDBAtlasODBC = [
    // The TestConnection handler enables gateway support.
    // It will invoke the data source function to validate the credentials the user has provided.
    TestConnection = (dataSourcePath) =>
        let
            json = Json.Document(dataSourcePath), mongodbUri = json[mongodbUri], database = json[database]
        in
            {"MongoDBAtlasODBC.Contents", mongodbUri, database},
    Authentication = [
        UsernamePassword = []
    ],
    SupportsEncryption = true
];

// Data Source UI publishing description
MongoDBAtlasODBC.Publish = [
    Beta = true,
    Category = "Database",
    ButtonText = {Extension.LoadString("ButtonTitle"), Extension.LoadString("ButtonHelp")},
    LearnMoreUrl = "https://www.mongodb.com/atlas/sql",
    SourceTypeImage = MongoDBAtlasODBC.Icons,
    // SQL-399: Add DirectQuery mode support
    SupportsDirectQuery = false
];

MongoDBAtlasODBC.Icons = [
    Icon16 = {
        Extension.Contents("MongoDBAtlasODBC16.png"),
        Extension.Contents("MongoDBAtlasODBC20.png"),
        Extension.Contents("MongoDBAtlasODBC24.png"),
        Extension.Contents("MongoDBAtlasODBC32.png")
    },
    Icon32 = {
        Extension.Contents("MongoDBAtlasODBC32.png"),
        Extension.Contents("MongoDBAtlasODBC40.png"),
        Extension.Contents("MongoDBAtlasODBC48.png"),
        Extension.Contents("MongoDBAtlasODBC64.png")
    }
];

BuildOdbcConfig = () as record =>
    let
        AstVisitor = [
            // Specifying the supported LIMIT OFFSET format
            LimitClause = (skip, take) =>
                let
                    offset = if (skip > 0) then Text.Format("OFFSET #{0}", {skip}) else "",
                    limit = if (take <> null) then Text.Format("LIMIT #{0}", {take}) else ""
                in
                    [
                        Text = Text.Format("#{0} #{1}", {offset, limit}),
                        Location = "AfterQuerySpecification"
                    ]
        ],
        Config = [
            AstVisitor = AstVisitor,
            HierarchicalNavigation = true,
            SqlCapabilities = [
                FractionalSecondsScale = 3,
                LimitClauseKind = LimitClauseKind.LimitOffset,
                SupportsDerivedTable = true,
                SupportsNumericLiterals = true,
                SupportsStringLiterals = true,
                SupportsOdbcDateLiterals = true,
                SupportsOdbcTimeLiterals = true,
                SupportsOdbcTimestampLiterals = true
            ],
            SQLGetFunctions = [
                SQL_API_SQLBINDPARAMETER = false,
                SQL_CONVERT_FUNCTIONS = 0x2 /* SQL_FN_CVT_CAST */
            ],
            SQLGetInfo = [
                SQL_SQL_CONFORMANCE = 8 /* SQL_SC_SQL92_FULL */
            ]
        ]
    in
        Config;

Extension.LoadFunction = (name as text) =>
    let
        binary = Extension.Contents(name), asText = Text.FromBinary(binary)
    in
        Expression.Evaluate(asText, #shared);

Table.ChangeType = Extension.LoadFunction("Table.ChangeType.pqm");
