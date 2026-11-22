/* =====================================================================
   PROYECTO INTEGRADOR - EQUIPO 1 - GRUPO O3
   ===================================================================== */
USE master;
GO

IF DB_ID(N'BD_Cafecito') IS NOT NULL
BEGIN
    ALTER DATABASE BD_Cafecito SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE BD_Cafecito;
END
GO

CREATE DATABASE BD_Cafecito;
GO

ALTER DATABASE BD_Cafecito SET COMPATIBILITY_LEVEL = 150;  -- necesario para OPENJSON, TRIM, STRING_AGG
GO

USE BD_Cafecito;
GO

CREATE SCHEMA stg AUTHORIZATION dbo;   -- capa de staging (datos crudos)
GO

PRINT 'BD_Cafecito y esquema stg creados correctamente.';
GO
