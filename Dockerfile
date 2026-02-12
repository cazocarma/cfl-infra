FROM mcr.microsoft.com/mssql/server:2022-latest

USER root
RUN mkdir -p /var/opt/mssql/seed && chown -R mssql:mssql /var/opt/mssql/seed
USER mssql

EXPOSE 1433
