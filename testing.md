# Smoke Test

For a new system setup, follow the installation steps in [install.md](install.md)
## Setup
### Start local Atlas Data Federation
##### Set the following environment variables
POSIX:
```
export ADF_TEST_LOCAL_USER=<adf username>
export ADF_TEST_LOCAL_PWD=<adf password>
export ADF_TEST_LOCAL_AUTH_DB=<local auth db>
export ADF_TEST_LOCAL_HOST=<local host address>
export MDB_TEST_LOCAL_PORT=<MongoDB port>
```
Windows:
```
setx ADF_TEST_LOCAL_USER "<adf username>"
setx ADF_TEST_LOCAL_PWD "<adf password>"
setx ADF_TEST_LOCAL_AUTH_DB "<local auth db>"
setx ADF_TEST_LOCAL_HOST "<local host address>"
setx MDB_TEST_LOCAL_PORT "<MongoDB port>"
```
##### Golang install location
The `run_adf.sh` script expects the `go` install to be in a specific location.  
For POSIX systems, the script will check for the `go` executable in `/opt/golang/$GO_VERSION`.  
For Windows systems `C:\golang\$GO_VERSION`.  Where `$GO_VERSION` is in the format `GO_VERSION="go1.18"`.  
Ensure that your `go` install is in the correct location.  Alternatively, you can modify the `run_adf.sh` script to point to the correct location.

##### Run script to start a local ADF instance
```
./resources/run_adf.sh start
```
#### Install mongoimport
Download and install [MongoDB Command Line Database Tools](https://www.mongodb.com/try/download/database-tools)
Add mongoimport.exe to the `PATH` and change permissions to make it executable.
#### Load Sample Dataset
```
mongoimport.exe --uri="mongodb://$ADF_TEST_LOCAL_HOST:$MDB_TEST_LOCAL_PORT/supplies" \
            --drop resources/integration_test/testdata/sales.json
mongoimport.exe --uri="mongodb://$ADF_TEST_LOCAL_HOST:$MDB_TEST_LOCAL_PORT/integration_test" \
            --drop resources/integration_test/testdata/complex_types.json
```
#### Generate Schema
Generate the schema for the data that was loaded using the `mongo.exe` executable downloaded by the `run_adf.sh` script
```
MONGOSHELL=$(find ./local_adf/ | grep mongo.exe | head -1) 
chmod +x $MONGOSHELL
$MONGOSHELL -u $ADF_TEST_LOCAL_USER --password $ADF_TEST_LOCAL_PWD --authenticationDatabase \
            $ADF_TEST_LOCAL_AUTH_DB $ADF_TEST_LOCAL_HOST/admin \
            --eval 'db.runCommand({sqlGenerateSchema: 1, 
            sampleNamespaces: ["integration_test.complex_types", "supplies.sales"], setSchemas: true})'
```
#### Clear Power BI Cache
It is a good idea to clear the data cache and data source settings to ensure the connector is being correctly tested.
##### Clear Data Cache
* Navigate to `File` -> `Options and settings` -> `Options` -> `Data Load`
* Under `Data Cache Management Options` click on `Clear Cache`

##### Clear Saved Data Source Settings
* Navigate to `File` -> `Options and settings` -> `Data source settings`
* For `Data sources in current file` and `Global permissions` choose `Clear Permissions`->`Clear All Permissions` 

## Running Tests
### Navigation Table
Test that the expected tables are shown in the navigation table and that data is loaded in the expected format.
* `Get Data` -> `More...` -> `Database` -> `MongoDB Atlas SQL (Beta)`
* Enter MongoDB URI: `mongodb://localhost/?ssl=false`
* Enter Database: `integration_test`
* Click `OK`
* In the Navigator, expand the `integration_test` and `supplies` databases to show the underlying collections
* Choose the `complex_types` collection and verify that the expected preview loads
* Click `Transform Data`
* Update the query to the following to show the table schema:
```
= Table.Schema(integration_test_Database{[Name="complex_types",Kind="Table"]}[Data])
```
* Confirm the `TypeName` and `NativeTypeName` columns have the expected values
  * The `TypeName` should be `Text.Type` for the complex types 
* Transform the `array` column to JSON
* Expand the list to new rows
* Click `Close and Apply`
* In `Visualizations` choose `Clustered column chart`
* In `Data` choose `double` and `integer`, verify the visualization is as expected

### Query
Test that data is loaded in the expected format when running a native query.
* `Get Data` -> `More...` -> `Database` -> `MongoDB Atlas SQL (Beta)`
* Enter MongoDB URI: `mongodb://localhost/?ssl=false`
* Enter Database: `supplies`
* Enter SQL Statement: `select * from sales`
* Click `OK`
* Verify that the expected preview loads
* Click `Transform Data`
* Confirm that the type is `Text` for all the columns with complex types
* Transform the `customer` column to JSON
* Expand all the values in the resulting `customer` records
* Change types of `customer.age` and `customer.satisfaction` to Whole Number
* Click `Close and Apply`
* In `Visualizations` choose `Clustered column chart`
* In `Data` for the Query choose `customer.age`, `customer.satisfaction`, and `_id`, verify the visualization is as expected

### On-Premises Data Gateway
* Open and sign in to the on-premises data gateway
* Go to the `Connectors` tab and choose `enable custom connectors`
* Ensure that the path points to the custom connectors folder
* Restart the gateway and Power BI Desktop and save the reports
* In Power BI, `Publish` the report that was created with the previous tests
* Ensure your gateway is set up by visiting the [gateways page](https://app.powerbi.com/groups/me/gateways)
* Visit the [Power BI Data hub](https://app.powerbi.com/datahub) and sign in 
* Your published data sources should appear here
* Hover over the data source, then use the `...` to select `settings`
* From here, you may be prompted to `Discover Data Sources` 
* Follow this prompt to establish the connection between Power BI and your database
* Return to your data set settings page, and you should now see additional options (i.e. “Gateway Connection” and “Data Source Credentials”) 
* Expand the latter, and input the credentials for your local ADF
* Return to the data hub, and refresh the dataset 
* This should then result in an updated timestamp under `refreshed`

# Manual Testing (for Native Query)

At this time, Native Query must be tested manually by reviewers.

The following query is sufficient to test Native Query as it exercises mutliple areas of translation.

1. Ensure you have a local ADF running following the .
- Navigate to the `mongo-powerbi-connector` repository locally.
- Run the ADF script via `./resources/run_adf start`
- Load data
  - If you have `mongoimport.exe` already installed, you can skip the downloading it. Otherwise
    ```
    MONGO_TOOLS_VERSION=100.6.1 curl -L -o mongodb-tools.zip \
    https://fastdl.mongodb.org/tools/db/mongodb-database-tools-windows-x86_64-$MONGO_TOOLS_VERSION.zip
    unzip -jn mongodb-tools.zip
    chmod +x mongoimport.exe
    ```
  - Import the data
    ```
    ./mongoimport.exe --uri="mongodb://localhost:28017/supplies" --drop resources/integration_test/testdata/sales.json
    ```
  - Set the ADF schema
    ```
    MONGOSH=$(find ./local_adf/ | grep mongo.exe | head -1)
    # Replace with the namespace you are adding
    $MONGOSH  -u mhuser -p pencil --eval 'db.runCommand({sqlGenerateSchema: 1, sampleNamespaces: ["supplies.sales"], setSchemas: true})' localhost/admin
    ```

2. Build the connector. The easiest way to do this is in VSCode, using the Power Query SDk.
- Navigate to the `connector` directory.
- `code .` to open the project in VSCode.
- Open `MongoDBAtlasODBC.pq`
- On the editor window, right click anywhere in the editor window for the `MongoDBAtlasODBC.pq` file and choose *Evaluate current power query file*
- Copy `bin\AnyCPU\Debug\connector.mez` to the Microsoft Power BI custom connector folder, located in `C:\Users\<username>\Documents\Power BI Desktop\Custom Connectors`.

3. Start Power BI.
4. Choose *Get Data*
5. Search for "mongodb" in the search box, and select the *MongoDB Atlas SQL (Beta)* connector.
6. Connect to your local ADF. 
- The URI should be `mongodb://localhost` 
- The database is `integration_test`.
- In the Native Query box, input the following SQL query which groups all sold items by name and calculates out how much revenue they generate per sale.
  ```
  SELECT name, AVG(price * quantity) as revenue_per_sale FROM(SELECT items_name as name, items_price as price, items_quantity as quantity FROM FLATTEN(UNWIND(sales WITH PATH => items))) as derived GROUP BY name
  ```
  
  This is equivalent to the following aggregation query and produces the same results.
  ```
  db.sales.aggregate([{$unwind: "$items"}, {$group: { _id: "$items.name", avgPrice: { $avg: {$multiply: ["$items.price", "$items.quantity"]}}}}])
  ```

7. Verify results. Numerics will display with higher precision in Power BI.

| name | revenue_per_sale |
| ---- | ---- |
| notepad | 66.337 |
| printer paper | 164.544 |
| backpack | 354.19 |
| binder | 112.808 |
| pens | 113.941 |
| laptop | 3257.093 |
| envelopes | 77.661 |

# Manual Testing (for Direct Query)

At this time, Direct Query must be tested semi-manually by reviewers, until such time as the Power Query
SDK uses the same Mashup Engine as Power BI.

Each Direct Query we want to run is stored in the `resources/direct_query` directory

1. Ensure you have a local ADF running.
- Navigate to the `mongo-powerbi-connector` repository locally.
- Run the ADF script via `./resources/run_adf start`
- Load data
  - If you have `mongoimport.exe` already installed, you can skip the downloading it. Otherwise
    ```
    MONGO_TOOLS_VERSION=100.6.1 curl -L -o mongodb-tools.zip \
    https://fastdl.mongodb.org/tools/db/mongodb-database-tools-windows-x86_64-$MONGO_TOOLS_VERSION.zip
    unzip -jn mongodb-tools.zip
    chmod +x mongoimport.exe
    ```
  - Import the data
    ```
    ./mongoimport.exe --uri="mongodb://localhost:28017/reports" --drop resources/integration_test/testdata/transforms.json
    ./mongoimport.exe --uri="mongodb://localhost:28017/reports" --drop resources/integration_test/testdata/table_ops.json
    ```
  - Set the ADF schema
    ```
    MONGOSH=$(find ./local_adf/ | grep mongo.exe | head -1)
    # Replace with the namespace you are adding
    $MONGOSH  -u mhuser -p pencil --eval 'db.runCommand({sqlGenerateSchema: 1, sampleNamespaces: ["reports.transforms", "reports.table_ops"], setSchemas: true})' localhost/admin
    ```

2. Build the connector. The easiest way to do this is in VSCode, using the Power Query SDk.
- Navigate to the `connector` directory.
- `code .` to open the project in VSCode.
- Open `MongoDBAtlasODBC.pq`
- On the editor window, right click anywhere in the editor window for the `MongoDBAtlasODBC.pq` file and choose *Evaluate current power query file*
- Copy `bin\AnyCPU\Debug\connector.mez` to the Microsoft Power BI custom connector folder, located in `C:\Users\<username>\Documents\Power BI Desktop\Custom Connectors`.

3. Start Power BI.
4. Choose *Get Data*
5. Search for "mongodb" in the search box, and select the *MongoDB Atlas SQL (Beta)* connector.
6. Connect to your local ADF.
- The URI should be `mongodb://localhost`
- Make sure to select the Direct Query radio button instead of Import
- The database is `reports`.
7. When the data explorer comes up, select the `reports` database and checkbox both collections:
- `transforms`
- `table_ops`
8. Wait a very long time for both collections to load
9. Open the `Advanced Query Editor` for the `transforms` table
10. Repeat the following process for the following queries: `resources/direct_query/conversion.pq`,
    `resources/direct_query/transforms.pq`
- Delete the previous query
- Copy the query from the proper pq file
- Paste into the query editor
- Select Done
- Wait a very long time for the query to run
- Ensure that there is a Direct Query for the last step by right clicking the last step and
  selecting `View Native Query` (which is confusing naming)
11. Repeat the following process for the following queries: `resources/direct_query/group.pq`,
    `resources/direct_query/merge_queries.pq`, `resources/direct_query/filter.pq`,
    `resources/direct_query/other_table_ops.pq`
- Delete the previous query
- Copy the query from the proper pq file
- Paste into the query editor
- Select Done
- Wait a very long time for the query to run
- Ensure that there is a Direct Query for the last step by right clicking the last step and
  selecting `View Native Query` (which is confusing naming)
