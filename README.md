# Analyzing Business Data with T-SQL

This repository provides the supporting code for my presentation entitled [Analyzing Business Data with T-SQL](https://www.catallaxyservices.com/presentations/analyzing-business-data-with-tsql/).

## Running the Code

All scripts are in the `code/Scripts` folder and can be run from SQL Server Management Studio, Visual Studio Code, or whatever your SQL Server query runner of choice.

In order to run this code, you will need the [WideWorldImporters database](https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0) running on a recent version of SQL Server (ideally 2022 or later).

### Using Docker

The `code` folder includes a Dockerfile that builds a SQL Server 2025 instance with WideWorldImporters pre-loaded:

```bash
cd code
docker build -t wwi-sql2025 .
docker run -d -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=YourStr0ngP@ssword" -p 1433:1433 wwi-sql2025
```

Once the container is running, connect to `localhost,1433` with username `sa` and the password you specified.
