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
    Uri = ProcessUri(mongodbUri),
    ConnectionString = [
        Driver = "ADF_ODBC_DRIVER"
    ],
    CredentialConnectionString = GetCredentialConnectionString(),
    OdbcDatasource = Odbc.DataSource(ConnectionString, [
        // SQL-1118: Implement Odbc.Datasource SqlCapabilities and Extensible Options
    ] & CredentialConnectionString)
in
    OdbcDatasource;

GetCredentialConnectionString = () as record =>
    let
        Credential = Extension.CurrentCredential(),
        EncryptionEnabled = Credential[EncryptConnection]? = true,
        CredentialConnectionString = [
            UID = Credential[Username],
            PWD = Credential[Password],
            SSL = if EncryptionEnabled then 1 else 0
        ]
    in
        CredentialConnectionString;

// SQL-1117: Implement ProcessUri Function
ProcessUri = (uri as text) as record => 
    let
        Result = []
    in 
        Result;

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
