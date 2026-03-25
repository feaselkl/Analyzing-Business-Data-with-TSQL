#!/bin/bash
# Start SQL Server in the background, wait for it to be ready,
# then restore the WideWorldImporters database.

# Start SQL Server in the background
/opt/mssql/bin/sqlservr &
SQLPID=$!

echo "Waiting for SQL Server to start..."
for i in {1..60}; do
    /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -C -Q "SELECT 1" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "SQL Server is ready."
        break
    fi
    sleep 1
done

# Check if WideWorldImporters already exists (avoid re-restoring on container restart)
DB_EXISTS=$(/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -C -h -1 -Q "SET NOCOUNT ON; SELECT COUNT(*) FROM sys.databases WHERE name = 'WideWorldImporters'" 2>/dev/null | tr -d '[:space:]')

if [ "$DB_EXISTS" = "0" ]; then
    echo "Restoring WideWorldImporters database..."
    /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -C -Q "
        RESTORE DATABASE [WideWorldImporters]
        FROM DISK = '/var/opt/mssql/backup/WideWorldImporters-Full.bak'
        WITH MOVE 'WWI_Primary'          TO '/var/opt/mssql/data/WideWorldImporters.mdf',
             MOVE 'WWI_UserData'         TO '/var/opt/mssql/data/WideWorldImporters_UserData.ndf',
             MOVE 'WWI_Log'              TO '/var/opt/mssql/data/WideWorldImporters.ldf',
             MOVE 'WWI_InMemory_Data_1'  TO '/var/opt/mssql/data/WideWorldImporters_InMemory_Data_1',
             REPLACE
    "
    echo "WideWorldImporters restored successfully."
else
    echo "WideWorldImporters already exists, skipping restore."
fi

# Keep SQL Server running in the foreground
wait $SQLPID
