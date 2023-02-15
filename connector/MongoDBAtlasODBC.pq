[Version = "0.0.0"]
section MongoDBAtlasODBC;

// When set to true, additional trace information will be written out to the User log. 
// This should be set to false before release. Tracing is done through a call to 
// Diagnostics.LogValue(). When EnableTraceOutput is set to false, the call becomes a 
// no-op and simply returns the original value.
EnableTraceOutput = true;

AtlasSQLLink="https://www.mongodb.com/atlas/sql";

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
        ConnectionString = Diagnostics.LogValue("ConnectionString", GetConnectionString(mongodbUri, database)),
        CredentialConnectionString = GetCredentialConnectionString(),
        Config = Diagnostics.LogValue("BuildOdbcConfig", BuildOdbcConfig()),
        DataSource =
            if query <> null then
                Odbc.Query(ConnectionString, query, [CredentialConnectionString = CredentialConnectionString])
            else
                Odbc.DataSource(ConnectionString, Config & [OnError = OnError, CredentialConnectionString = CredentialConnectionString]),
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
                TransformColumns
    in
        TransformColumns;

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
        SqlBinaryTypes = Diagnostics.LogValue("TransformSqlUnknownColumns", Table.ToRecords(
            Table.SelectRows(Schema, each [TypeName] = "Binary.Type" and [NativeTypeName] <> "binData")
        )),
        TransformOperations = List.Accumulate(
            SqlBinaryTypes,
            table,
            (state, column) =>
                let
                    ColumnType = Type.TableColumn(Value.Type(table), column[Name]),
                    PreservedFacetFields = {"NativeTypeName", "NativeDefaultExpression", "NativeExpression"},
                    Facets = Record.SelectFields(Type.Facets(ColumnType), PreservedFacetFields),
                    TypeWithFacets = Type.ReplaceFacets(type nullable text, Facets),
                    ToNullableText = (value) => if value = null then null else Text.FromBinary(value),
                    TransformColumn = Table.TransformColumns(state, {column[Name], ToNullableText, TypeWithFacets})
                in
                    TransformColumn
        )
    in
        TransformOperations;

// Executes operation on specified columnName of the passed in table
shared TransformColumnKeepType = (table, columnName, operation) =>
    let
        TableType = Value.Type(table), TransformColumn = Table.TransformColumns(table, {columnName, operation})
    in
        Value.ReplaceType(TransformColumn, TableType);

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

DataSourceMissingClientLibrary = "DataSource.MissingClientLibrary";
shared OnError = (errorRecord as record) =>
    let
        ErrRecord = Diagnostics.LogValue("OnError Record", errorRecord),
        Reason = ErrRecord[Reason]?,
        ReasonVal = if Reason = null then "" else Reason,
        Message = ErrRecord[Message]?,
        MessageVal = if Message = null then "None" else Message,
        Newline = Text.From(Character.FromNumber(10))
    in
        if ReasonVal = "DataSource.Error" then
            let
                SqlState = ErrRecord[Detail][OdbcErrors][SQLState]?,
                SqlStateVal = if SqlState = null then "" else Text.Combine({"SQLSTATE: ", Lines.ToText(SqlState)}),
                NativeError = ErrRecord[Detail][OdbcErrors][NativeError]?,
                NativeErrorVal = if NativeError = null then "" else Text.Combine({"NativeError: ", Lines.ToText(List.Transform(NativeError, Text.From))})
            in
                error "Data source error occurred." 
                        & Newline
                        & SqlStateVal 
                        & NativeErrorVal 
                        & "Error message: " 
                        & MessageVal
        else if ReasonVal = DataSourceMissingClientLibrary then
                    error "Missing client library for datasource" 
                      & Newline 
                      & "Visit " 
                      & Text.From(AtlasSQLLink)
                      & " for more information."
        else if ReasonVal = "Extension.CredentialError" then
            error "Credential error occurred." & Newline & MessageVal
        else
            error "An unknown error occurred. Error message:" & Newline & MessageVal;

// Data Source Kind description
MongoDBAtlasODBC = [
    // The TestConnection handler enables gateway support.
    // It will invoke the data source function to validate the credentials the user has provided.
    TestConnection = (dataSourcePath) =>
        let
            dataSourcePathVal = Diagnostics.LogValue("TestConnection dataSourcePath", dataSourcePath),
            json = Json.Document(dataSourcePathVal), 
            mongodbUri = json[mongodbUri], 
            database = json[database]
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
    LearnMoreUrl = AtlasSQLLink,
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

// 
// Load common library functions
// 
Extension.LoadFunction = (name as text) =>
    let
        binary = Extension.Contents(name),
        asText = Text.FromBinary(binary)
    in
        Expression.Evaluate(asText, #shared);

// Diagnostics module contains multiple functions. We can take the ones we need.
Diagnostics = Extension.LoadFunction("Diagnostics.pqm");
Diagnostics.LogValue = if (EnableTraceOutput) then Diagnostics[LogValue] else (prefix, value) => value;
