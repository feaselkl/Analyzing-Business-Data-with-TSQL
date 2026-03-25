# SQL Server 2025 with WideWorldImporters pre-loaded
# Usage:
#   docker build -t wwi-sql2025 .
#   docker run -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=YourStr0ngP@ssword" -p 1433:1433 wwi-sql2025

FROM mcr.microsoft.com/mssql/server:2025-latest

USER root

# Install curl for downloading the backup file
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Create directories for backup and setup
RUN mkdir -p /var/opt/mssql/backup /var/opt/mssql/setup

# Download WideWorldImporters backup
RUN curl -L -o /var/opt/mssql/backup/WideWorldImporters-Full.bak \
    'https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak'

# Copy the setup script
COPY setup.sh /var/opt/mssql/setup/
RUN chmod +x /var/opt/mssql/setup/setup.sh

# Switch back to the mssql user
USER mssql

# Start SQL Server and run setup in parallel
CMD /bin/bash /var/opt/mssql/setup/setup.sh
