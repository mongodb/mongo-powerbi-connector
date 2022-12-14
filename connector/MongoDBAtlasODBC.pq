[Version = "0.0.0"]
section MongoDBAtlasODBC;

[DataSource.Kind="MongoDBAtlasODBC", Publish="MongoDBAtlasODBC.Publish"]
shared MongoDBAtlasODBC.Contents = Value.ReplaceType(MongoDBAtlasODBCImpl, MongoDBAtlasODBCType);

MongoDBAtlasODBCType = type function(
    mongodbUri as (type text meta[
        Documentation.FieldCaption = "MongoDB URI",
        Documentation.FieldDescription = "MongoDB connection URI",
        Documentation.SampleValues = {"mongodb://hostname:port/admin"}
    ]), 
    database as (type text meta [
        Documentation.FieldCaption = "Database",
        Documentation.FieldDescription = "Database to connect to",
        Documentation.SampleValues = {"db"}
    ]),
    optional options as record)
    as table meta [
        Documentation.Name = "MongoDB Atlas SQL"
    ];

MongoDBAtlasODBCImpl = (mongodbUri as text, database as text, optional options as record) as table => 
    let
        ValidOptionsMap = #table(
            {"Name","Type","Description","Default","Validate"},
            {
                {
                    "ApplicationName", type nullable text, 
                    "Enter a value to use as the Application Name in the SQL traces", 
                    null, 
                    each _ = null or _ <> null
                }
            }
        ),
        ValidatedOptions = ValidateOptions(options, ValidOptionsMap),
        ConnectionString = GetConnectionString(mongodbUri, database, ValidatedOptions),
        CredentialConnectionString = GetCredentialConnectionString(),
        Config = BuildOdbcConfig(),
        OdbcDatasource = Odbc.DataSource(ConnectionString, Config
            & [ CredentialConnectionString = CredentialConnectionString ])
    in
        OdbcDatasource;

GetCredentialConnectionString = () as record =>
    let
        Credential = Extension.CurrentCredential(),
        CredentialConnectionString = [
            UID = Credential[Username],
            PWD = Credential[Password]
        ]
    in
        CredentialConnectionString;

NullFieldCheck = (field as any, fieldName as text ) =>
    let 
        Result = if field <> null then Record.AddField([], fieldName, field) else []
    in
        Result;

ProcessAuthSrc = (queryEntry as any, pathEntry as any) =>
    let
        DefaultAuthSrc = "admin",
        FieldName = "AUTH_SRC",
        // The 'authSource' connection option takes precedence over the /defaultauthdb value in the connection string.
        // If both are unspecified, then authSource defaults to 'admin'.
        AuthSrc =    if queryEntry <> null then
                        queryEntry
                    else if pathEntry <> null and Text.Length(Text.Remove(pathEntry, "/")) > 0 then
                        Text.Remove(pathEntry, "/")
                    else
                        DefaultAuthSrc,
        Result = Record.AddField([], FieldName, AuthSrc)
    in 
        Result;

ProcessUri = (uri as text) as any => 
    let
        DefaultPort = "27017",
        UriParts = Uri.Parts(uri),
        BadUri = UriParts[Host] = "" or UriParts[Fragment] <> ""
            or UriParts[UserName] <> "" or UriParts[Password] <> "",
        // http and https schemes automatically set port values to 80 and 443 respectively.
        // The following checks whether the user has set the port values explicitly to 80 or 443.
        // An unknown scheme will set the port value to -1 if it is not specified
        Port =  if  (UriParts[Port] = 80 and not Text.Contains(uri, ":80")) or
                    (UriParts[Port] = 443 and not Text.Contains(uri, ":443")) or
                    UriParts[Port] = -1 then
                    DefaultPort
                else
                    Number.ToText(UriParts[Port]),
        SSL = NullFieldCheck(UriParts[Query][ssl]?, "SSL"),
        TLS = NullFieldCheck(UriParts[Query][tls]?, "TLS"),
        AuthSrc = ProcessAuthSrc(UriParts[Query][authSource]?, UriParts[Path]?),
        Server = Text.Combine({UriParts[Host], ":", Port}),
        Result =  Record.Combine({[ SERVER =  Server ], SSL, TLS, AuthSrc})
    in 
        if BadUri then 
            error "Invalid URI"
        else
             Result;

shared GetConnectionString = (uri as text, database as text, options as record) as record =>
    let 
        Uri = ProcessUri(uri),
        AppName = options[ApplicationName]?,
        DatabaseNotSet = database = "",
        ConnectionString = [
            // SQL-1147: Connection string not accepting 'application_name'
            // APPLICATION_NAME = if AppName <> null then AppName else "MongoDB Atlas SQL - PowerBI",
            DRIVER = "ADF_ODBC_DRIVER",
            DATABASE = database
        ] & Uri
    in 
        if DatabaseNotSet then
            error "Database value cannot be empty"
        else
            ConnectionString;

// Data Source Kind description
MongoDBAtlasODBC = [
    Authentication = [
        UsernamePassword = []
    ],
    SupportsEncryption = true
];

// Data Source UI publishing description
MongoDBAtlasODBC.Publish = [
    Beta = true,
    Category = "Database",
    ButtonText = { Extension.LoadString("ButtonTitle"), Extension.LoadString("ButtonHelp") },
    LearnMoreUrl = "https://www.mongodb.com/atlas/sql",
    SourceTypeImage = MongoDBAtlasODBC.Icons,
    // SQL-399: Add DirectQuery mode support
    SupportsDirectQuery = false
];

MongoDBAtlasODBC.Icons = [
    Icon16 = { Extension.Contents("MongoDBAtlasODBC16.png"), Extension.Contents("MongoDBAtlasODBC20.png"), Extension.Contents("MongoDBAtlasODBC24.png"), Extension.Contents("MongoDBAtlasODBC32.png") },
    Icon32 = { Extension.Contents("MongoDBAtlasODBC32.png"), Extension.Contents("MongoDBAtlasODBC40.png"), Extension.Contents("MongoDBAtlasODBC48.png"), Extension.Contents("MongoDBAtlasODBC64.png") }
];

BuildOdbcConfig = () as record =>
    let
        Config = [
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

// ValidateOptions checks that the options are supported according to the validOptionsMap.
// Returns a record of validated key/values.  
// Function is from SqlODBC example.
ValidateOptions = (options as nullable record, validOptionsMap as table) as record =>
    let
        ValidKeys = Table.Column(validOptionsMap, "Name"),
        InvalidKeys = List.Difference(Record.FieldNames(options), ValidKeys),
        InvalidKeysText =
            if List.IsEmpty(InvalidKeys) then
                null
            else
                Text.Format(
                    "'#{0}' are not valid options. Valid options are: '#{1}'",
                    {Text.Combine(InvalidKeys, ", "), Text.Combine(ValidKeys, ", ")}
                ),
        ValidateValue = (name, optionType, description, default, validate, value) =>
                if (value is null and (Type.IsNullable(optionType) or default <> null)) or (Type.Is(Value.Type(value), optionType) and validate(value)) then
                    null
                else
                    Text.Format(
                        "This function does not support the option '#{0}' with value '#{1}'. Valid value is #{2}.",
                        {name, value, description}
                    ),
        InvalidValues = List.RemoveNulls(Table.TransformRows(validOptionsMap, each ValidateValue([Name],[Type],[Description],[Default],[Validate], Record.FieldOrDefault(options, [Name], [Default])))),
        DefaultOptions = Record.FromTable(Table.RenameColumns(Table.SelectColumns(validOptionsMap,{"Name","Default"}),{"Default","Value"})),
        NullNotAllowedFields = List.RemoveNulls(Table.TransformRows(validOptionsMap, each if not Type.IsNullable([Type]) and null = Record.FieldOrDefault(options, [Name], [Default]) then [Name] else null)),
        NormalizedOptions = DefaultOptions & Record.RemoveFields(options, NullNotAllowedFields, MissingField.Ignore)
    in
        if null = options then 
            DefaultOptions
        else if not List.IsEmpty(InvalidKeys) then
            error Error.Record("Expression.Error", InvalidKeysText)
        else if not List.IsEmpty(InvalidValues) then
            error Error.Record("Expression.Error", Text.Combine(InvalidValues, ", "))
        else
            NormalizedOptions;
