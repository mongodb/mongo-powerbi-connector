# Manual Testing (for Native Query)

At this time, Native Query must be tested manually by reviewers.

The following query is sufficient to test Native Query as it exercises mutliple areas of translation.

1. Ensure you have a local ADF running.
- Navigate to the `mongo-odbc-driver` repository locally.
- Run the ADF script via `./resources/run_adf start`
- After it sets up and returns back to the shell prompt, load local data via `cargo run --bin data_loader`
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
- In the Native Query box, input the following SQL query
  ```
  SELECT name as student_name, avg(grades.score) as average FROM grades JOIN class WHERE grades.studentid = class.studentid AND enrolled = true GROUP BY name
  ```

7. Verify results.
- There should be two rows and two columns

    |average | student_name |
    |--------|--------------|
    | 85.9 | John |
    | 86 | Mike   |
