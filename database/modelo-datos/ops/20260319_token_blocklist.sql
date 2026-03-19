-- Token blocklist para revocacion de JWT antes de su expiracion.
-- Los registros se pueden purgar periodicamente donde ExpiresAt < GETUTCDATE().

IF NOT EXISTS (SELECT 1 FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'cfl' AND t.name = 'TokenBlocklist')
BEGIN
  CREATE TABLE [cfl].[TokenBlocklist] (
    Jti          CHAR(36)     NOT NULL,
    IdUsuario    BIGINT       NOT NULL,
    Motivo       VARCHAR(50)  NOT NULL,
    ExpiresAt    DATETIME2    NOT NULL,
    CreatedAt    DATETIME2    NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT PK_TokenBlocklist PRIMARY KEY (Jti),
    INDEX IX_TokenBlocklist_ExpiresAt (ExpiresAt)
  );
END
GO
