# Manual Testing (for Native Query)

At this time, Native Query must be tested manually by reviewers.

The following query is sufficient to test Native Query as it exercises mutliple areas of translation.

1. Ensure you have a local ADF running.
- Navigate to the `mongo-odbc-driver` repository locally.
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
- Navigate back to the `mongo-powerbi-connector` repository.

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

| name | sale |
| ---- | ---- |
| notepad | 66.337 |
| printer paper | 164.544 |
| backpack | 354.19 |
| binder | 112.808 |
| pens | 113.941 |
| laptop | 3257.093 |
| envelopes | 77.661 |



