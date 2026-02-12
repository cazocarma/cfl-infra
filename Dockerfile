FROM mcr.microsoft.com/mssql/server:2022-latest

USER root
RUN mkdir -p /var/opt/mssql/seed /usr/config
COPY scripts/init-db.sh /usr/config/init-db.sh
RUN chmod +x /usr/config/init-db.sh && chown -R mssql:mssql /var/opt/mssql/seed /usr/config
USER mssql

EXPOSE 1433
CMD ["/bin/bash", "/usr/config/init-db.sh"]
