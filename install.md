# Installation
## Prerequisites

### Power BI Desktop

Download and install the latest version of Power BI Desktop on the [Power BI website](https://powerbi.microsoft.com/en-us/downloads/).

### MongoDB ODBC Driver
Download the MongoDB ODBC driver from the following link.  Replace `${release_version}` with the desired [release](https://github.com/mongodb/mongo-odbc-driver/tags) (e.g. "0.1.0"):
```
https://translators-connectors-releases.s3.us-east-1.amazonaws.com/mongosql-odbc-driver/windows/${release_version}/release/mongoodbc.dll
```
Download the [setupDSN.reg](resources/odbc/setupDSN.reg) file and update the values for `Driver` and `Setup` to point to the location of the `mongoodbc.dll` file. 
For example:
```
"Driver"="C:\\mongo-odbc-driver\\mongoodbc.dll"
```
Double-click on `setupDSN.reg` to apply the registry changes.

### Optional: Data Gateway
The on-premises data gateway is used as a bridge between the cloud-based Power BI service and your on-premises data sources, allowing you to securely transfer data between them.
It allows the scheduling of data refreshes to ensure that the data is up-to-date in the Power BI service.

Follow these [instructions](https://learn.microsoft.com/en-us/data-integration/gateway/service-gateway-install) to install the data gateway.

## Installing Power BI Connector

Download the Power BI custom connector release from the following link.  Replace `${release_version}` with the desired [release](https://github.com/mongodb/mongo-powerbi-connector/tags) (e.g. "0.1.0"):

```
https://translators-connectors-releases.s3.us-east-1.amazonaws.com/mongo-powerbi-connector/MongoDBAtlasODBC-${release_version}.pqx
```
Copy the custom connector to the `[Documents]\Power BI Desktop\Custom Connectors` directory.  
Note: If the directory does not exist, it will need to be manually created.

### Enabling Custom Connector
Users have two options to enable the custom connector in Power BI.  Adding the thumbprint of the certificate on the connector to the registry(recommended) or lowering the security settings in Power BI. 

#### Adding Thumbprint to Registry
To add the thumbprint value to the registry, run:
```reg import "resources/odbc/add_thumbprint.reg"```
To remove the value from the registry, run: 
```reg import "resources/odbc/remove_thumbprint.reg"```
#### Updating Power BI Security Settings  
Power BI security levels for Data Extensions will need to be updated to allow the custom connector to be loaded.  
Follow the instructions [here](https://learn.microsoft.com/en-us/power-bi/connect-data/desktop-connector-extensibility) to set the level to `(Not Recommended) Allow any extension to load without validation or warning.`

