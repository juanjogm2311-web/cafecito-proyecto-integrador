/*
CAFECITO · EQUIPO 1 · GRUPO O3
02_etl_ingesta_bronce.sql
Carga los archivos y orígenes a staging (stg). En el proyecto actual,
stg representa la capa cruda equivalente a Bronce.
*/
/* =====================================================================
   PROYECTO INTEGRADOR - EQUIPO 1
   Script 03 · EXTRACCIÓN y carga a STAGING (datos crudos, SIN limpiar)
   Responsable: Ana Sofía Arroniz Domínguez (Data Engineer / Pipeline Lead)
   ===================================================================== */
USE BD_Cafecito;
GO
SET NOCOUNT ON;

-- Permite volver a ejecutar el script sin duplicar la carga
TRUNCATE TABLE stg.Clientes_Raw;
TRUNCATE TABLE stg.Ventas_Raw;
TRUNCATE TABLE stg.Clima_Raw;
TRUNCATE TABLE stg.Clima_JSON_Raw;
TRUNCATE TABLE stg.Entregas_Raw;
GO

/* ---------- ORIGEN 1a: clientes del e-commerce (extracción de BD_Ventas_Cafecito) ---------- */
INSERT INTO stg.Clientes_Raw (ID_Cliente, Nombre, Email, Telefono, Ciudad, Fecha_Registro) VALUES
    (N'CLI-001', N'  maría fernanda navarro castillo  ', N'maria.navarro1@correo.com', N'4776184138', N'Silao', N'2025-01-26'),
    (N'CLI-002', N'José Luis Rojas Ruiz', N'jose.rojas2@correo.com', N'4777188185', N'Leon', N'2026-01-08'),
    (N'CLI-003', N'Ana Karen Cruz Díaz', N'ana.cruz3@correo.com', N'4772521428', N'León', N'2026-02-13'),
    (N'CLI-004', N'JUAN CARLOS NAVARRO ORTIZ', N'juan.navarro4@correo.com', N'4779362688', N'GTO', N'2025-04-30'),
    (N'CLI-005', N'Daniela Díaz Reyes', N'daniela.diaz5@correo.com', NULL, N'Silao', N'2026-02-12'),
    (N'CLI-006', N'Luis Ángel Medina Reyes', N'  LUIS.MEDINA6@CORREO.COM', N'4775339316', N'GTO', N'2026-03-07'),
    (N'CLI-007', N'Valeria Ortiz Medina', N'valeria.ortiz7@correo.com', N'4779039473', N'Leon', N'2026-06-10'),
    (N'CLI-008', N'Diego   Alejandro Reyes Moreno', N'diego.reyes8@correo.com', N'4771425740', N'Silao', N'2025-08-18'),
    (N'CLI-009', N'Sofía Jiménez González', N'sofia.jimenez9@correo.com', N'4771820199', N'Leon', N'2026-06-20'),
    (N'CLI-010', N'Carlos Eduardo Navarro Vargas', N'carlos.navarro10@correo.com', NULL, N'Leon', N'2026-03-16'),
    (N'CLI-011', N'Ximena Morales González', N'ximena.morales11@correo.com', N'4779088515', N' leon ', N'2025-08-23'),
    (N'CLI-012', N'Miguel Ángel Rojas Navarro', N'miguel.rojas12@correo.com', N'4773047042', N'Leon', N'2026-04-13'),
    (N'CLI-013', N'Regina Vargas Morales', N'REGINA.VARGAS13@CORREO.COM ', N'4775211189', N'Leon', N'2026-02-16'),
    (N'CLI-014', N'Fernando Vargas Torres', N'fernando.vargas14@correo.com', N'4779420478', N'Leon', N'2026-05-06'),
    (N'CLI-015', N'Paola Moreno Navarro', N'paola.moreno15@correo.com', N'4777743569', N'Leon', N'2026-03-20'),
    (N'CLI-016', N'Ricardo Rodríguez Torres', N'ricardo.rodriguez16@correo.com', N'4775513674', N'LEON', N'2025-01-10'),
    (N'CLI-017', N'Andrea Hernández González', N'andrea.hernandez17@correo.com', N'4778687780', N'Leon', N'2026-06-20'),
    (N'CLI-018', N'Jorge Medina Morales', N'jorge.medina18@correo.com', N'4777038721', N'Leon', N'2025-07-24'),
    (N'CLI-019', N'Camila Ramírez Ruiz', N'camila.ramirez19@correo.com', NULL, N'Guanajuato', N'2026-04-23'),
    (N'CLI-020', N'Héctor Reyes Jiménez', N'hector.reyes20@correo.com', N'4779340912', N'Leon', N'2026-03-21'),
    (N'CLI-021', N'Mariana Gutiérrez Vargas', N'mariana.gutierrez21@correo.com', N'4771564049', N'Leon', N'2025-10-25'),
    (N'CLI-022', N'Alejandro Flores Cruz', N'alejandro.flores22@correo.com', N'4772650441', N'Leon', N'2026-03-25'),
    (N'CLI-023', N'Renata Ruiz Ruiz', N'renata.ruiz23@correo.com', N'4779643174', N'Silao', N'2025-09-23'),
    (N'CLI-024', N'Emilio Cruz Medina', N'emilio.cruz24@correo.com', N'4774071049', N'GTO', N'2026-03-12'),
    (N'CLI-025', N'Lucía Muñoz Aguilar', N'lucia.munoz25@correo.com', N'4779038740', N'Guanajuato', N'2025-03-07'),
    (N'CLI-026', N'Óscar Castillo Ramírez', N'oscar.castillo26@correo.com', N'4779362112', N'Leon', N'2026-01-15'),
    (N'CLI-027', N'Natalia Martínez Rodríguez', N'natalia.martinez27@correo.com', N'4777900650', N'Leon', N'2025-05-30'),
    (N'CLI-028', N'Rodrigo Cruz Medina', N'rodrigo.cruz28@correo.com', NULL, N'Leon', N'2025-04-05'),
    (N'CLI-029', N'Fátima García Cruz', N'fatima.garcia29@correo.com', N'4772393608', N'Leon', N'2025-07-23'),
    (N'CLI-030', N'Sergio Sánchez Martínez', N'sergio.sanchez30@correo.com', N'4771749254', N'Leon', N'2025-10-02'),
    (N'CLI-031', N'Itzel Vargas Jiménez', N'itzel.vargas31@correo.com', N'4776993671', N'GTO', N'2025-06-08'),
    (N'CLI-032', N'Gerardo García Flores', N'gerardo.garcia32@correo.com', N'4779254204', N'Silao', N'2025-05-19'),
    (N'CLI-033', N'Montserrat Gutiérrez Sánchez', N'montserrat.gutierrez33@correo.com', N'4778935346', N'Silao', N'2025-05-15'),
    (N'CLI-034', N'Iván Mendoza Navarro', N'ivan.mendoza34@correo.com', NULL, N'Silao', N'2025-10-25'),
    (N'CLI-035', N'Karla López Díaz', N'karla.lopez35@correo.com', N'4773686393', N'Leon', N'2025-05-19'),
    (N'CLI-036', N'Raúl Moreno Moreno', N'raul.moreno36@correo.com', N'4776133900', N'Leon', N'2026-06-04'),
    (N'CLI-037', N'Brenda Díaz Gómez', N'brenda.diaz37@correo.com', N'4773492025', N'GTO', N'2026-06-17'),
    (N'CLI-038', N'Arturo Moreno Rodríguez', N'arturo.moreno38@correo.com', N'4777308337', N'Guanajuato', N'2025-01-15'),
    (N'CLI-039', N'Elena Martínez Gómez', N'elena.martinez39@correo.com', N'4772232006', N'Leon', N'2025-02-22'),
    (N'CLI-040', N'Mauricio Muñoz Rivera', N'mauricio.munoz40@correo.com', N'4776929115', N'Leon', N'2025-01-27'),
    (N'CLI-007', N'Valeria Ortiz Medina', N'valeria.ortiz7@correo.com', N'4779039473', N'Leon', N'2026-06-10'),
    (N'CLI-022', N'Alejandro Flores Cruz', N'alejandro.flores22@correo.com', N'4772650441', N'Leon', N'2026-03-25');
GO

/* ---------- ORIGEN 1b: Ventas_Cafecito (pedidos del e-commerce) ----------
   Incluye los 5 pedidos originales del dataset (PED-101 a PED-105). */
INSERT INTO stg.Ventas_Raw (ID_Pedido, ID_Cliente, Fecha_Hora, ID_Sucursal, Tipo_Producto, Monto_Total, Sucursal_Ciudad) VALUES
    (N'PED-101', N'CLI-001', N'2026-08-01 08:30:00', N'SUC-01', N'Bebida Caliente', N'145.00', N'Leon'),
    (N'PED-108', N'CLI-001', N'2026-08-01 09:45:00', N'SUC-03', N'Bebida Caliente', N'150.00', N'Silao'),
    (N'PED-102', N'CLI-002', N'2026-08-01 14:15:00', N'SUC-02', N'Bebida Fría', N'180.00', N'Leon'),
    (N'PED-106', N'CLI-026', N'2026-08-01 14:50:00', N'SUC-01', N'Bebida Caliente', N'185.00', N'Leon'),
    (N'PED-107', N'CLI-003', N'2026-08-01 16:20:00', N'SUC-02', N'Repostería', N'165.00', N'Leon'),
    (N'PED-109', N'CLI-013', N'2026-08-01 18:40:00', N'SUC-04', N'Repostería', N'140.00', N'Guanajuato'),
    (N'PED-113', N'CLI-012', N'2026-08-02 07:40:00', N'SUC-04', N'Bebida Fría', N'185.00', N'Guanajuato'),
    (N'PED-103', N'CLI-001', N'2026-08-02 09:00:00', N'SUC-01', N'Bebida Caliente', N'210.00', N'Leon'),
    (N'PED-110', N'CLI-007', N'2026-08-02 12:50:00', N'SUC-02', N'Bebida Fría', N'140.00', N'Leon'),
    (N'PED-112', N'CLI-001', N'2026-08-02 15:15:00', N'SUC-03', N'Reposteria', N'60.00', N'Silao'),
    (N'PED-104', N'CLI-004', N'2026-08-02 16:45:00', N'SUC-02', N'Bebida Fría', N'95.00', N'Leon'),
    (N'PED-111', N'CLI-008', N'2026-08-02 18:05:00', N'SUC-03', N'bebida caliente ', N'195.00', N'Silao'),
    (N'PED-114', N'CLI-019', N'2026-08-02 19:10:00', N'SUC-04', N'bebida fría', N'175.00', N'Guanajuato'),
    (N'PED-116', N'CLI-026', N'2026-08-03 07:15:00', N'SUC-02', N'Bebida Fría', N'140.00', N'Leon'),
    (N'PED-118', N'CLI-024', N'2026-08-03 10:00:00', N'SUC-04', N'Bebida Caliente', N'145.00', N'Guanajuato'),
    (N'PED-105', N'CLI-003', N'2026-08-03 11:20:00', N'SUC-01', N'Repostería', N'130.00', N'Leon'),
    (N'PED-117', N'CLI-005', N'2026-08-03 15:20:00', N'SUC-03', N'Repostería', N'105.00', N'Silao'),
    (N'PED-115', N'CLI-021', N'2026-08-03 18:40:00', N'SUC-01', N'BEBIDA CALIENTE', N'105.00', N'Leon'),
    (N'PED-121', N'CLI-003', N'2026-08-04 07:05:00', N'SUC-02', N'Bebida Fría', N'120.00', N'Leon'),
    (N'PED-120', N'CLI-018', N'2026-08-04 07:10:00', N'SUC-01', N'Bebida Caliente', N'165.00', N'Leon'),
    (N'PED-124', N'CLI-007', N'2026-08-04 09:05:00', N'SUC-04', N'Bebida Fría', N'130.00', N'Guanajuato'),
    (N'PED-123', N'CLI-005', N'2026-08-04 10:50:00', N'SUC-03', N'Bebida Caliente', N'130.00', N'Silao'),
    (N'PED-119', N'CLI-011', N'2026-08-04 12:50:00', N'SUC-01', N'Bebida Fría', N'160.00', N'Leon'),
    (N'PED-122', N'CLI-026', N'2026-08-04 18:00:00', N'SUC-02', N'Bebida Fría', N'235.00', N'Leon'),
    (N'PED-127', N'CLI-018', N'2026-08-05 08:50:00', N'SUC-02', N'Bebida Caliente', N'160.00', N'Leon'),
    (N'PED-126', N'CLI-030', N'2026-08-05 11:05:00', N'SUC-01', N'Bebida Caliente', N'180.00', N'León'),
    (N'PED-130', N'CLI-023', N'2026-08-05 11:20:00', N'SUC-03', N'Repostería', N'180.00', N'Silao'),
    (N'PED-128', N'CLI-017', N'2026-08-05 12:45:00', N'SUC-02', N'Bebida Caliente', N'215.00', N'Leon'),
    (N'PED-131', N'CLI-019', N'2026-08-05 13:50:00', N'SUC-04', N'bebida caliente ', N'135.00', N'Guanajuato'),
    (N'PED-132', N'CLI-037', N'2026-08-05 18:45:00', N'SUC-04', N'Bebida Caliente', N'135.00', N'Guanajuato'),
    (N'PED-129', N'CLI-016', N'2026-08-05 19:05:00', N'SUC-03', N'Bebida Caliente', N'-95.00', N'Silao'),
    (N'PED-125', N'CLI-022', N'2026-08-05 20:05:00', N'SUC-01', N'Bebida Caliente', N'220.00', N'Leon'),
    (N'PED-137', N'CLI-010', N'2026-08-06 08:30:00', N'SUC-03', N'Bebida Caliente', N'215.00', N'Silao'),
    (N'PED-138', N'CLI-031', N'2026-08-06 11:10:00', N'SUC-04', N'Repostería', N'130.00', N'Guanajuato'),
    (N'PED-134', N'CLI-027', N'2026-08-06 12:30:00', N'SUC-01  ', N'Bebida Caliente', N'195.00', N'Leon'),
    (N'PED-135', N'CLI-002', N'2026-08-06 13:15:00', N'SUC-02', N'Repostería', N'150.00', N'Leon'),
    (N'PED-136', N'CLI-007', N'2026-08-06 16:10:00', N'SUC-02', N'BEBIDA CALIENTE', N'200.00', N'Leon'),
    (N'PED-133', N'CLI-032', N'2026-08-06 19:45:00', N'SUC-01', N' Bebida  Caliente', N'115.00', N'Leon'),
    (N'PED-140', N'CLI-035', N'2026-08-07 11:20:00', N'SUC-01', N'Bebida Fría', N'110.00', N'Leon'),
    (N'PED-139', N'CLI-026', N'2026-08-07 12:10:00', N'SUC-01', N'Bebida Fría', N'130.00', N'Leon'),
    (N'PED-141', N'CLI-006', N'2026-08-07 13:00:00', N'SUC-02', N'Bebida Fría', N'155.00', N'Leon'),
    (N'PED-143', N'CLI-032', N'2026-08-07 14:50:00', N'SUC-03', N'Bebida Caliente', N'205.00', N'Silao'),
    (N'PED-144', N'CLI-025', N'2026-08-07 17:30:00', N'SUC-04', N'Bebida Caliente', N'140.00', N'Guanajuato'),
    (N'PED-142', N'CLI-018', N'2026-08-07 17:40:00', N'SUC-02', N'Bebida Fría', N'145.00', N'Leon'),
    (N'PED-145', N'CLI-020', N'2026-08-07 18:10:00', N'SUC-04  ', N'Bebida Caliente', N'145.00', N'GTO'),
    (N'PED-149', N'CLI-032', N'2026-08-08 08:20:00', N' suc-03', N'Bebida Fría', N'195.00', N'Silao'),
    (N'PED-146', N'CLI-028', N'2026-08-08 11:10:00', N'SUC-01', N'Bebida Caliente', N'$195.00', N'Leon'),
    (N'PED-148', N'CLI-003', N'2026-08-08 12:00:00', N'SUC-02', N'Repostería', N'135.00', N'Leon'),
    (N'PED-147', N'CLI-002', N'2026-08-08 13:45:00', N'SUC-02', N'Bebida Fría', N'-190.00', N'Leon'),
    (N'PED-150', N'CLI-019', N'2026-08-08 19:45:00', N'SUC-04', N'BEBIDA CALIENTE', N'115.00', N'Guanajuato');
INSERT INTO stg.Ventas_Raw (ID_Pedido, ID_Cliente, Fecha_Hora, ID_Sucursal, Tipo_Producto, Monto_Total, Sucursal_Ciudad) VALUES
    (N'PED-154', N'CLI-032', N'2026-08-09 11:05:00', N'SUC-03', N'Bebida Fría', N'205.00', N'SILAO '),
    (N'PED-151', N'CLI-035', N'2026-08-09 12:05:00', N'SUC-01', N'Bebida Caliente', N'185.00', N'Leon'),
    (N'PED-156', N'CLI-019', N'2026-08-09 13:00:00', N'SUC-04', N'Bebida Caliente', N'125.00', N'Guanajuato'),
    (N'PED-153', N'CLI-026', N'2026-08-09 14:15:00', N'SUC-02', N'Bebida Caliente', N'120.00', N'Leon'),
    (N'PED-152', N'CLI-031', N'2026-08-09 15:00:00', N'SUC-01', N'Bebida Caliente', N'115.00', N'Leon'),
    (N'PED-155', N'CLI-005', N'2026-08-09 15:50:00', N'SUC-03', N'Bebida Caliente', N'195.00', N'Silao'),
    (N'PED-160', N'CLI-032', N'2026-08-10 09:00:00', N'SUC-03', N'Bebida Caliente', N'160.00', N'Silao'),
    (N'PED-157', N'CLI-020', N'2026-08-10 10:45:00', N'SUC-01', N' Bebida  Caliente', N'165.00', N'Leon'),
    (N'PED-158', N'CLI-002', N'2026-08-10 12:30:00', N'SUC-02', N'Bebida Fría', N'145.00', N'Leon'),
    (N'PED-159', N'CLI-015', N'2026-08-10 14:30:00', N'SUC-02  ', N'BEBIDA CALIENTE', N'125.00', N'Leon'),
    (N'PED-161', N'CLI-025', N'2026-08-10 20:45:00', N'SUC-04', N'Repostería', N'100.00', N'Guanajuato'),
    (N'PED-165', N'CLI-001', N'2026-08-11 11:45:00', N'SUC-03', N'bebida caliente ', N'220.00', N'SILAO '),
    (N'PED-168', N'CLI-006', N'2026-08-11 15:10:00', N'SUC-04', N' Bebida  Caliente', N'95.00', N'Guanajuato'),
    (N'PED-166', N'CLI-034', N'2026-08-11 15:50:00', N'SUC-03', N'Bebida Caliente', N'220.00', N'Silao'),
    (N'PED-167', N'CLI-006', N'2026-08-11 17:30:00', N'SUC-04', N'Bebida Caliente', N'135.00', N'Guanajuato'),
    (N'PED-164', N'CLI-014', N'2026-08-11 18:50:00', N'SUC-02', N'REPOSTERIA', N'175.00', N'Leon'),
    (N'PED-162', N'CLI-021', N'2026-08-11 20:40:00', N'SUC-01', N'Bebida Caliente', N'165.00', N'Leon'),
    (N'PED-163', N'CLI-015', N'2026-08-11 20:40:00', N'SUC-02', N'Bebida Caliente', N'90.00', N'Leon'),
    (N'PED-174', N'CLI-037', N'2026-08-12 12:30:00', N'SUC-04', N'Bebida Fria', N'230.00', N'Guanajuato'),
    (N'PED-171', N'CLI-016', N'2026-08-12 13:50:00', N'SUC-02', N'Bebida Fría', N'125.00', N'Leon'),
    (N'PED-173', N'CLI-001', N'2026-08-12 14:10:00', N'SUC-03', N'Bebida Fría', N'205.00', N'Silao'),
    (N'PED-169', N'CLI-002', N'2026-08-12 15:40:00', N'SUC-01', N'Repostería', N'140.00', N'León'),
    (N'PED-175', N'CLI-025', N'2026-08-12 15:50:00', N'SUC-04', N'REPOSTERIA', N'120.00', N'Guanajuato'),
    (N'PED-170', N'CLI-002', N'2026-08-12 16:15:00', N'SUC-01', N'Bebida Fría', N'240.00', N'Leon'),
    (N'PED-172', N'CLI-015', N'2026-08-12 19:20:00', N'SUC-03', N' Bebida  Caliente', N'115.00', N'Silao'),
    (N'PED-178', N'CLI-021', N'2026-08-13 07:20:00', N'SUC-02', N'Bebida Fría', N'230.00', N'Leon'),
    (N'PED-179', N'CLI-001', N'2026-08-13 09:20:00', N'SUC-03', N'Repostería', N'85.00', N'Silao'),
    (N'PED-180', N'CLI-019', N'2026-08-13 14:10:00', N'SUC-04', N'Bebida Fría', N'115.00', N'Guanajuato'),
    (N'PED-176', N'CLI-030', N'2026-08-13 18:10:00', N'SUC-01', N'Bebida Fría', N'180.00', N'Leon'),
    (N'PED-181', N'CLI-024', N'2026-08-13 19:10:00', N'SUC-04  ', N'Bebida Fría', N'100.00', N'Guanajuato'),
    (N'PED-177', N'CLI-015', N'2026-08-13 20:00:00', N'SUC-02', N'Bebida Fría', N'220.00', N' leon'),
    (N'PED-184', N'CLI-035', N'2026-08-14 08:45:00', N'SUC-02', N'Bebida Fría', N'-180.00', N'Leon'),
    (N'PED-185', N'CLI-017', N'2026-08-14 09:30:00', N'SUC-02', N'Bebida Fría', N'160.00', N'Leon'),
    (N'PED-183', N'CLI-021', N'2026-08-14 11:15:00', N' suc-01', N'Repostería', N'60.00', N'Leon'),
    (N'PED-186', N'CLI-032', N'2026-08-14 14:00:00', N'SUC-03', N'Bebida Fría', N'100.00', N'Silao'),
    (N'PED-182', N'CLI-013', N'2026-08-14 16:45:00', N'SUC-01', N'Bebida Caliente', N'185.00', N'Leon'),
    (N'PED-187', N'CLI-024', N'2026-08-14 20:20:00', N'SUC-04', N'bebida caliente ', N'175.00', N'Guanajuato'),
    (N'PED-190', N'CLI-020', N'2026-08-15 10:15:00', N'SUC-02', N'Repostería', N'85.00', N'Leon'),
    (N'PED-193', N'CLI-019', N'2026-08-15 10:20:00', N'SUC-04', N'Repostería', N'170.00', N'Guanajuato'),
    (N'PED-191', N'CLI-023', N'2026-08-15 12:10:00', N'SUC-03', N'Repostería', N'90.00', N'Silao'),
    (N'PED-189', N'CLI-035', N'2026-08-15 13:40:00', N'SUC-01', N'Repostería', N'70.00', N'Leon'),
    (N'PED-192', N'CLI-008', N'2026-08-15 13:40:00', N'SUC-03', N'Bebida Fría', N'230.00', N'Silao'),
    (N'PED-188', N'CLI-029', N'2026-08-15 15:15:00', N'SUC-01', N'Repostería', N'85.00', N'Leon'),
    (N'PED-197', N'CLI-032', N'2026-08-16 13:15:00', N'SUC-03', N'Bebida Caliente', N'185.00', N'Silao'),
    (N'PED-194', N'CLI-020', N'2026-08-16 15:45:00', N'SUC-01', N'Bebida Fría', N'240.00', N'Leon'),
    (N'PED-198', N'CLI-025', N'2026-08-16 17:20:00', N'SUC-04', N'Bebida Caliente', N'105.00', N'GTO'),
    (N'PED-196', N'CLI-029', N'2026-08-16 18:10:00', N'SUC-02', N'Reposteria', N'115.00', N'Leon'),
    (N'PED-195', N'CLI-017', N'2026-08-16 18:15:00', N'SUC-01', N'Bebida Caliente', N'$115.00', N'Leon'),
    (N'PED-199', N'CLI-026', N'2026-08-17 07:45:00', N'SUC-01', N'Bebida Fría', N'155.00', N'León'),
    (N'PED-200', N'CLI-020', N'2026-08-17 11:30:00', N'SUC-01  ', N'Bebida Fría', N'235.00', N'Leon');
INSERT INTO stg.Ventas_Raw (ID_Pedido, ID_Cliente, Fecha_Hora, ID_Sucursal, Tipo_Producto, Monto_Total, Sucursal_Ciudad) VALUES
    (N'PED-202', N'CLI-018', N'2026-08-17 14:40:00', N'SUC-02', N'bebida fría', N'150.00', N'Leon'),
    (N'PED-204', N'CLI-008', N'2026-08-17 17:05:00', N'SUC-03', N'Bebida Caliente', N'$125.00', N'Silao'),
    (N'PED-203', N'CLI-016', N'2026-08-17 18:50:00', N'SUC-03', N'Bebida Fría', N'100.00', N'Silao'),
    (N'PED-201', N'CLI-018', N'2026-08-17 19:10:00', N'SUC-02', N'Repostería', N'75.00', N'LEON'),
    (N'PED-205', N'CLI-004', N'2026-08-17 20:50:00', N'SUC-04', N'Bebida Fría', N'180.00', N'Guanajuato'),
    (N'PED-211', N'CLI-024', N'2026-08-18 07:00:00', N'SUC-04', N'Bebida Fría', N'135.00', N'Guanajuato'),
    (N'PED-209', N'CLI-029', N'2026-08-18 07:10:00', N'SUC-02', N'Bebida Fría', N'180.00', N'Leon'),
    (N'PED-207', N'CLI-011', N'2026-08-18 08:50:00', N'SUC-01', N'Bebida Caliente', N'90.00', N'Leon'),
    (N'PED-206', N'CLI-012', N'2026-08-18 11:00:00', N'SUC-01', N'Repostería', N'100.00', N'Leon'),
    (N'PED-210', N'CLI-032', N'2026-08-18 13:05:00', N'SUC-03', N'Bebida Caliente', N'100.00', N'SILAO '),
    (N'PED-208', N'CLI-009', N'2026-08-18 19:45:00', N' suc-02', N'Bebida Fría', N'155.00', N'Leon'),
    (N'PED-216', N'CLI-023', N'2026-08-19 10:10:00', N'SUC-03', N'Bebida Caliente', N'160.00', N'Silao'),
    (N'PED-215', N'CLI-029', N'2026-08-19 10:50:00', N'SUC-02', N'Bebida Fría', N'155.00', N'Leon'),
    (N'PED-213', N'CLI-026', N'2026-08-19 12:10:00', N'SUC-01', N'Bebida Caliente', N'220.00', N'Leon'),
    (N'PED-214', N'CLI-007', N'2026-08-19 12:45:00', N'SUC-02  ', N'Repostería', N'95.00', N'Leon'),
    (N'PED-217', N'CLI-031', N'2026-08-19 16:45:00', N'SUC-04  ', N'Bebida Caliente', N'100.00', N'Guanajuato'),
    (N'PED-212', N'CLI-002', N'2026-08-19 16:50:00', N'SUC-01', N'Repostería', N'180.00', N'Leon'),
    (N'PED-218', N'CLI-007', N'2026-08-20 07:45:00', N'SUC-01', N'bebida caliente ', N'165.00', N'Leon'),
    (N'PED-223', N'CLI-033', N'2026-08-20 08:30:00', N'SUC-03', N'Bebida Caliente', N'165.00', N'Silao'),
    (N'PED-224', N'CLI-037', N'2026-08-20 09:45:00', N'SUC-04', N'Bebida Caliente', N'170.00', N'Guanajuato'),
    (N'PED-220', N'CLI-009', N'2026-08-20 11:15:00', N'SUC-02', N'Bebida Caliente', N'105.00', N'Leon'),
    (N'PED-221', N'CLI-012', N'2026-08-20 11:40:00', N'SUC-02', N'Repostería', N'110.00', N'Leon'),
    (N'PED-222', NULL, N'2026-08-20 16:50:00', N'SUC-03', N'Bebida Fría', N'-150.00', N'Silao'),
    (N'PED-219', N'CLI-022', N'2026-08-20 18:00:00', N'SUC-01', N'Repostería', N'120.00', N'Leon'),
    (N'PED-227', N'CLI-009', N'2026-08-21 09:50:00', N'SUC-02', N'Bebida Caliente', N'210.00', N'LEON'),
    (N'PED-226', N'CLI-013', N'2026-08-21 10:15:00', N'SUC-01', N'Bebida Fría', N'95.00', N'Leon'),
    (N'PED-228', N'CLI-023', N'2026-08-21 11:10:00', N'SUC-03', N'repostería ', N'70.00', N'SILAO '),
    (N'PED-229', NULL, N'2026-08-21 17:50:00', N'SUC-04', N'Bebida Caliente', N'215.00', N'Guanajuato'),
    (N'PED-225', N'CLI-036', N'2026-08-21 19:40:00', N'SUC-01', N'repostería ', N'75.00', N'Leon'),
    (N'PED-187', N'CLI-024', N'2026-08-14 20:20:00', N'SUC-04', N'bebida caliente ', N'175.00', N'Guanajuato'),
    (N'PED-124', N'CLI-007', N'2026-08-04 09:05:00', N'SUC-04', N'Bebida Fría', N'130.00', N'Guanajuato'),
    (N'PED-191', N'CLI-023', N'2026-08-15 12:10:00', N'SUC-03', N'Repostería', N'90.00', N'Silao'),
    (N'PED-147', N'CLI-002', N'2026-08-08 13:45:00', N'SUC-02', N'Bebida Fría', N'-190.00', N'Leon'),
    (N'PED-160', N'CLI-032', N'2026-08-10 09:00:00', N'SUC-03', N'Bebida Caliente', N'160.00', N'Silao'),
    (N'PED-190', N'CLI-020', N'2026-08-15 10:15:00', N'SUC-02', N'Repostería', N'85.00', N'Leon');
GO

/* ---------- ORIGEN 2: API_Clima_Historico.json ----------
   Se lee la respuesta JSON de la API con OPENJSON. Todos los campos se
   extraen como texto para poder DIAGNOSTICAR tipos inconsistentes
   (ej. una temperatura que llega como "texto" en lugar de número).

   OPCIÓN B (leer el archivo directamente del disco del servidor):
     DECLARE @json NVARCHAR(MAX);
     SELECT @json = BulkColumn
     FROM OPENROWSET(BULK 'C:\Cafecito\API_Clima_Historico.json', SINGLE_CLOB) AS j;
     -- (SINGLE_CLOB puede deformar acentos; por eso aquí se usa la opción A)
*/
DECLARE @json NVARCHAR(MAX) = N'[
 {
  "Fecha_Consulta": "2026-08-01",
  "Ciudad": "Leon",
  "Temperatura_C": 14.2,
  "Condicion_Climatica": "Lluvia Intensa",
  "Humedad_Pct": 85
 },
 {
  "Fecha_Consulta": "2026-08-01",
  "Ciudad": "Silao",
  "Temperatura_C": 14.7,
  "Condicion_Climatica": "Lluvia Intensa",
  "Humedad_Pct": 83
 },
 {
  "Fecha_Consulta": "2026-08-01",
  "Ciudad": "Guanajuato",
  "Temperatura_C": 13.9,
  "Condicion_Climatica": "Lluvia Intensa",
  "Humedad_Pct": 89
 },
 {
  "Fecha_Consulta": "2026-08-02",
  "Ciudad": "Leon",
  "Temperatura_C": 29.8,
  "Condicion_Climatica": "Caluroso",
  "Humedad_Pct": 35
 },
 {
  "Fecha_Consulta": "2026-08-02",
  "Ciudad": "Silao",
  "Temperatura_C": 18.2,
  "Condicion_Climatica": "Nublado",
  "Humedad_Pct": 56
 },
 {
  "Fecha_Consulta": "2026-08-02",
  "Ciudad": "Guanajuato",
  "Temperatura_C": 30.8,
  "Condicion_Climatica": "Caluroso",
  "Humedad_Pct": 31
 },
 {
  "Fecha_Consulta": "2026-08-03",
  "Ciudad": "Leon",
  "Temperatura_C": 21.0,
  "Condicion_Climatica": "Nublado",
  "Humedad_Pct": 60
 },
 {
  "Fecha_Consulta": "2026-08-03",
  "Ciudad": "Silao",
  "Temperatura_C": 21.1,
  "Condicion_Climatica": "Nublado",
  "Humedad_Pct": 59
 },
 {
  "Fecha_Consulta": "2026-08-03",
  "Ciudad": "Guanajuato",
  "Temperatura_C": 19.6,
  "Condicion_Climatica": "Nublado",
  "Humedad_Pct": 68
 },
 {
  "Fecha_Consulta": "2026-08-04",
  "Ciudad": "Leon",
  "Temperatura_C": 23.9,
  "Condicion_Climatica": "Templado",
  "Humedad_Pct": 42
 },
 {
  "Fecha_Consulta": "2026-08-04",
  "Ciudad": "Silao",
  "Temperatura_C": 22.7,
  "Condicion_Climatica": "Templado",
  "Humedad_Pct": 45
 },
 {
  "Fecha_Consulta": "2026-08-04",
  "Ciudad": "Guanajuato",
  "Temperatura_C": 32.0,
  "Condicion_Climatica": "Caluroso",
  "Humedad_Pct": -5
 },
 {
  "Fecha_Consulta": "2026-08-05",
  "Ciudad": "León",
  "Temperatura_C": 14.2,
  "Condicion_Climatica": "Lluvia Intensa",
  "Humedad_Pct": 80
 },
 {
  "Fecha_Consulta": "2026-08-05",
  "Ciudad": "Silao",
  "Temperatura_C": 14.9,
  "Condicion_Climatica": "Lluvia Intensa",
  "Humedad_Pct": 79
 },
 {
  "Fecha_Consulta": "2026-08-05",
  "Ciudad": "Guanajuato",
  "Temperatura_C": 15.1,
  "Condicion_Climatica": "Lluvia Intensa",
  "Humedad_Pct": 82
 },
 {
  "Fecha_Consulta": "2026-08-06",
  "Ciudad": "Leon",
  "Temperatura_C": 21.3,
  "Condicion_Climatica": "Nublado",
  "Humedad_Pct": 61
 },
 {
  "Fecha_Consulta": "2026-08-06",
  "Ciudad": "Silao",
  "Temperatura_C": "16.5",
  "Condicion_Climatica": "Lluvia Intensa",
  "Humedad_Pct": 88
 },
 {
  "Fecha_Consulta": "2026-08-06",
  "Ciudad": "Guanajuato",
  "Temperatura_C": 20.2,
  "Condicion_Climatica": "Nublado",
  "Humedad_Pct": 60
 },
 {
  "Fecha_Consulta": "2026-08-07",
  "Ciudad": "Leon",
  "Temperatura_C": 31.8,
  "Condicion_Climatica": "Caluroso",
  "Humedad_Pct": 36
 },
 {
  "Fecha_Consulta": "2026-08-07",
  "Ciudad": "Silao",
  "Temperatura_C": 28.8,
  "Condicion_Climatica": "Caluroso",
  "Humedad_Pct": 31
 },
 {
  "Fecha_Consulta": "2026-08-07",
  "Ciudad": "GTO",
  "Temperatura_C": 23.9,
  "Condicion_Climatica": "Templado",
  "Humedad_Pct": 46
 },
 {
  "Fecha_Consulta": "2026-08-08",
  "Ciudad": "Leon",
  "Temperatura_C": 24.0,
  "Condicion_Climatica": "Templado",
  "Humedad_Pct": 48
 },
 {
  "Fecha_Consulta": "2026-08-08",
  "Ciudad": "Silao",
  "Temperatura_C": 22.5,
  "Condicion_Climatica": "Templado",
  "Humedad_Pct": 48
 },
 {
  "Fecha_Consulta": "2026-08-08",
  "Ciudad": "Guanajuato",
  "Temperatura_C": 27.9,
  "Condicion_Climatica": "Caluroso",
  "Humedad_Pct": 26
 },
 {
  "Fecha_Consulta": "2026-08-09",
  "Ciudad": "Leon",
  "Temperatura_C": 16.0,
  "Condicion_Climatica": "Lluvia Intensa",
  "Humedad_Pct": 89
 },
 {
  "Fecha_Consulta": "2026-08-09",
  "Ciudad": " silao ",
  "Temperatura_C": 15.6,
  "Condicion_Climatica": "Lluvia Intensa",
  "Humedad_Pct": 79
 },
 {
  "Fecha_Consulta": "2026-08-09",
  "Ciudad": "Guanajuato",
  "Temperatura_C": 14.1,
  "Condicion_Climatica": "Lluvia Intensa",
  "Humedad_Pct": 91
 },
 {
  "Fecha_Consulta": "2026-08-10",
  "Ciudad": "Leon",
  "Temperatura_C": null,
  "Condicion_Climatica": "Lluvia Intensa",
  "Humedad_Pct": 92
 },
 {
  "Fecha_Consulta": "2026-08-10",
  "Ciudad": "Silao",
  "Temperatura_C": 14.0,
  "Condicion_Climatica": "Lluvia Intensa",
  "Humedad_Pct": 79
 },
 {
  "Fecha_Consulta": "2026-08-10",
  "Ciudad": "Guanajuato",
  "Temperatura_C": 23.5,
  "Condicion_Climatica": "Templado",
  "Humedad_Pct": 40
 },
 {
  "Fecha_Consulta": "2026-08-11",
  "Ciudad": "Leon",
  "Temperatura_C": 18.2,
  "Condicion_Climatica": "Nublado",
  "Humedad_Pct": 62
 },
 {
  "Fecha_Consulta": "2026-08-11",
  "Ciudad": "Silao",
  "Temperatura_C": 13.4,
  "Condicion_Climatica": "Lluvia Intensa",
  "Humedad_Pct": 120
 },
 {
  "Fecha_Consulta": "2026-08-11",
  "Ciudad": "Guanajuato",
  "Temperatura_C": 21.7,
  "Condicion_Climatica": "Nublado",
  "Humedad_Pct": 66
 },
 {
  "Fecha_Consulta": "2026-08-12",
  "Ciudad": "León",
  "Temperatura_C": 28.6,
  "Condicion_Climatica": "Caluroso",
  "Humedad_Pct": 39
 },
 {
  "Fecha_Consulta": "2026-08-12",
  "Ciudad": "Silao",
  "Temperatura_C": 30.3,
  "Condicion_Climatica": "Caluroso",
  "Humedad_Pct": 26
 },
 {
  "Fecha_Consulta": "2026-08-12",
  "Ciudad": "Guanajuato",
  "Temperatura_C": 28.6,
  "Condicion_Climatica": "Caluroso",
  "Humedad_Pct": 31
 },
 {
  "Fecha_Consulta": "2026-08-13",
  "Ciudad": "Leon",
  "Temperatura_C": 30.0,
  "Condicion_Climatica": "Caluroso",
  "Humedad_Pct": 38
 },
 {
  "Fecha_Consulta": "2026-08-13",
  "Ciudad": "Silao",
  "Temperatura_C": 31.4,
  "Condicion_Climatica": "Caluroso",
  "Humedad_Pct": 36
 },
 {
  "Fecha_Consulta": "2026-08-13",
  "Ciudad": "Guanajuato",
  "Temperatura_C": 30.4,
  "Condicion_Climatica": "Caluroso",
  "Humedad_Pct": 33
 },
 {
  "Fecha_Consulta": "2026-08-14",
  "Ciudad": "Leon",
  "Temperatura_C": 23.4,
  "Condicion_Climatica": "Templado",
  "Humedad_Pct": 51
 },
 {
  "Fecha_Consulta": "2026-08-14",
  "Ciudad": "Silao",
  "Temperatura_C": 31.4,
  "Condicion_Climatica": "Caluroso",
  "Humedad_Pct": 34
 },
 {
  "Fecha_Consulta": "2026-08-14",
  "Ciudad": "GTO",
  "Temperatura_C": 23.0,
  "Condicion_Climatica": "Templado",
  "Humedad_Pct": 43
 },
 {
  "Fecha_Consulta": "2026-08-15",
  "Ciudad": "Leon",
  "Temperatura_C": 19.2,
  "Condicion_Climatica": "Nublado",
  "Humedad_Pct": 68
 },
 {
  "Fecha_Consulta": "2026-08-15",
  "Ciudad": "Silao",
  "Temperatura_C": 21.6,
  "Condicion_Climatica": "Nublado",
  "Humedad_Pct": 65
 },
 {
  "Fecha_Consulta": "2026-08-15",
  "Ciudad": "Guanajuato",
  "Temperatura_C": 15.9,
  "Condicion_Climatica": "Lluvia Intensa",
  "Humedad_Pct": 79
 },
 {
  "Fecha_Consulta": "2026-08-16",
  "Ciudad": "Leon",
  "Temperatura_C": 13.6,
  "Condicion_Climatica": "Lluvia Intensa",
  "Humedad_Pct": 79
 },
 {
  "Fecha_Consulta": "2026-08-16",
  "Ciudad": "Silao",
  "Temperatura_C": 20.1,
  "Condicion_Climatica": "Nublado",
  "Humedad_Pct": 64
 },
 {
  "Fecha_Consulta": "2026-08-16",
  "Ciudad": "Guanajuato",
  "Temperatura_C": null,
  "Condicion_Climatica": "Nublado",
  "Humedad_Pct": 67
 },
 {
  "Fecha_Consulta": "2026-08-17",
  "Ciudad": "Leon",
  "Temperatura_C": 23.3,
  "Condicion_Climatica": "Templado",
  "Humedad_Pct": 53
 },
 {
  "Fecha_Consulta": "2026-08-17",
  "Ciudad": "Silao",
  "Temperatura_C": 24.7,
  "Condicion_Climatica": "Templado",
  "Humedad_Pct": 45
 },
 {
  "Fecha_Consulta": "2026-08-17",
  "Ciudad": "Guanajuato",
  "Temperatura_C": 24.3,
  "Condicion_Climatica": "Templado",
  "Humedad_Pct": 52
 },
 {
  "Fecha_Consulta": "2026-08-18",
  "Ciudad": "León",
  "Temperatura_C": 31.4,
  "Condicion_Climatica": "Caluroso",
  "Humedad_Pct": 29
 },
 {
  "Fecha_Consulta": "2026-08-18",
  "Ciudad": "Silao",
  "Temperatura_C": 14.1,
  "Condicion_Climatica": "Lluvia Intensa",
  "Humedad_Pct": 85
 },
 {
  "Fecha_Consulta": "2026-08-18",
  "Ciudad": "Guanajuato",
  "Temperatura_C": 31.8,
  "Condicion_Climatica": "Caluroso",
  "Humedad_Pct": 29
 },
 {
  "Fecha_Consulta": "2026-08-19",
  "Ciudad": "Leon",
  "Temperatura_C": 21.8,
  "Condicion_Climatica": "Nublado",
  "Humedad_Pct": 57
 },
 {
  "Fecha_Consulta": "2026-08-19",
  "Ciudad": "Silao",
  "Temperatura_C": 20.2,
  "Condicion_Climatica": "Nublado",
  "Humedad_Pct": 63
 },
 {
  "Fecha_Consulta": "2026-08-19",
  "Ciudad": "Guanajuato",
  "Temperatura_C": 20.1,
  "Condicion_Climatica": "Nublado",
  "Humedad_Pct": 65
 },
 {
  "Fecha_Consulta": "2026-08-20",
  "Ciudad": "Leon",
  "Temperatura_C": 13.2,
  "Condicion_Climatica": "Lluvia Intensa",
  "Humedad_Pct": 91
 },
 {
  "Fecha_Consulta": "2026-08-20",
  "Ciudad": "Silao",
  "Temperatura_C": 19.9,
  "Condicion_Climatica": "Nublado",
  "Humedad_Pct": 62
 },
 {
  "Fecha_Consulta": "2026-08-20",
  "Ciudad": "Guanajuato",
  "Temperatura_C": 16.4,
  "Condicion_Climatica": "Lluvia Intensa",
  "Humedad_Pct": 92
 },
 {
  "Fecha_Consulta": "2026-08-21",
  "Ciudad": "Leon",
  "Temperatura_C": 24.6,
  "Condicion_Climatica": "Templado",
  "Humedad_Pct": 52
 },
 {
  "Fecha_Consulta": "2026-08-21",
  "Ciudad": "Silao",
  "Temperatura_C": 23.3,
  "Condicion_Climatica": "Templado",
  "Humedad_Pct": 47
 },
 {
  "Fecha_Consulta": "2026-08-21",
  "Ciudad": "Guanajuato",
  "Temperatura_C": 23.0,
  "Condicion_Climatica": "Templado",
  "Humedad_Pct": 46
 },
 {
  "Fecha_Consulta": "2026-08-08",
  "Ciudad": "Leon",
  "Temperatura_C": 24.0,
  "Condicion_Climatica": "Templado",
  "Humedad_Pct": 48
 },
 {
  "Fecha_Consulta": "2026-08-15",
  "Ciudad": "Silao",
  "Temperatura_C": 21.6,
  "Condicion_Climatica": "Nublado",
  "Humedad_Pct": 65
 }
]';

IF ISJSON(@json) = 0
    THROW 50001, 'El contenido recibido de la API no es un JSON válido.', 1;

-- (a) se guarda la respuesta completa
INSERT INTO stg.Clima_JSON_Raw (Respuesta_JSON) VALUES (@json);

-- (b) se aplana en filas con OPENJSON ... WITH
INSERT INTO stg.Clima_Raw (Fecha_Consulta, Ciudad, Temperatura_C, Condicion_Climatica, Humedad_Pct)
SELECT Fecha_Consulta, Ciudad, Temperatura_C, Condicion_Climatica, Humedad_Pct
FROM OPENJSON(@json)
WITH (
    Fecha_Consulta      NVARCHAR(30) '$.Fecha_Consulta',
    Ciudad              NVARCHAR(60) '$.Ciudad',
    Temperatura_C       NVARCHAR(20) '$.Temperatura_C',
    Condicion_Climatica NVARCHAR(60) '$.Condicion_Climatica',
    Humedad_Pct         NVARCHAR(20) '$.Humedad_Pct'
);
GO

/* ---------- ORIGEN 3: CSV_Entregas_ECommerce.csv ----------
   Cada INSERT corresponde a una fila del CSV (campos vacíos = '' como en el archivo).

   OPCIÓN B (cargar el archivo .csv del disco del servidor con BULK INSERT):
     CREATE TABLE stg.Entregas_CSV (ID_Envio NVARCHAR(20), ID_Pedido NVARCHAR(20),
         Fecha_Entrega NVARCHAR(30), Minutos_Demora NVARCHAR(20), Calificacion_Cliente NVARCHAR(20));
     BULK INSERT stg.Entregas_CSV
     FROM 'C:\Cafecito\CSV_Entregas_ECommerce.csv'
     WITH (FORMAT = 'CSV', FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '0x0a', CODEPAGE = '65001');
     INSERT INTO stg.Entregas_Raw (ID_Envio, ID_Pedido, Fecha_Entrega, Minutos_Demora, Calificacion_Cliente)
     SELECT * FROM stg.Entregas_CSV;
*/
INSERT INTO stg.Entregas_Raw (ID_Envio, ID_Pedido, Fecha_Entrega, Minutos_Demora, Calificacion_Cliente) VALUES
    (N'ENV-501', N'PED-101', N'01/08/2026', N'45', N'2'),
    (N'ENV-502', N'PED-102', N'01-08-2026', N'20', N'5'),
    (N'ENV-503', N'PED-103', N'2026/08/02', N'', N'4'),
    (N'ENV-504', N'PED-104', N'02/08/2026', N'55', N'1'),
    (N'ENV-505', N'PED-105', N'03-08-2026', N'25', N''),
    (N'ENV-506', N'PED-108', N'2026-08-01', N'54', N'2'),
    (N'ENV-507', N'PED-106', N'2026-08-01', N'51', N'2'),
    (N'ENV-508', N'PED-107', N'2026-08-01', N'50', N'2'),
    (N'ENV-509', N'PED-109', N'2026-08-01', N'51', N'2'),
    (N'ENV-510', N'PED-113', N'2026-08-02', N'28', N'4'),
    (N'ENV-511', N'PED-110', N'02/08/2026', N'34', N'3'),
    (N'ENV-512', N'PED-112', N'02/08/2026', N'33', N'4'),
    (N'ENV-513', N'PED-111', N'2026/08/02', N'', N'0'),
    (N'ENV-514', N'PED-114', N'02/08/2026', N'28', N'4'),
    (N'ENV-515', N'PED-116', N'03-08-2026', N'26', N'4'),
    (N'ENV-516', N'PED-118', N'2026-08-03', N'35', N'4'),
    (N'ENV-517', N'PED-117', N'03/08/2026', N'40', N'4'),
    (N'ENV-518', N'PED-115', N'03-08-2026', N'', N'4'),
    (N'ENV-519', N'PED-121', N'04/08/2026', N'-17', N'5'),
    (N'ENV-520', N'PED-123', N'04-08-2026', N'16', N'5'),
    (N'ENV-521', N'PED-122', N'2026/08/04', N'16', N''),
    (N'ENV-522', N'PED-126', N'2026-08-05', N'', N'1'),
    (N'ENV-523', N'PED-128', N'2026/08/05', N'44', N''),
    (N'ENV-524', N'PED-132', N'2026-08-05', N'59', N'2'),
    (N'ENV-525', N'PED-129', N'2026-08-05', N'54', N'2'),
    (N'ENV-526', N'PED-125', N'06-08-2026', N'60', N'1'),
    (N'ENV-527', N'PED-137', N'06/08/2026', N'64', N'1'),
    (N'ENV-528', N'PED-138', N'2026-08-06', N'32', N'3'),
    (N'ENV-529', N'PED-134', N'2026/08/06', N'30', N'4'),
    (N'ENV-530', N'PED-135', N'06/08/2026', N'', N'4'),
    (N'ENV-531', N' PED-136', N'06/08/2026', N'', N'4'),
    (N'ENV-532', N'PED-133', N'06/08/2026', N'26', N'4'),
    (N'ENV-533', N'PED-140', N'2026/08/07', N'22', N'4'),
    (N'ENV-534', N'PED-139', N'2026/08/07', N'30', N'4'),
    (N'ENV-535', N'PED-141', N'07/08/2026', N'23', N'4'),
    (N'ENV-536', N'PED-143', N'07-08-2026', N'31', N'4'),
    (N'ENV-537', N'PED-144', N'2026/08/07', N'24', N'4'),
    (N'ENV-538', N' PED-142', N'2026-08-07', N'28', N'4'),
    (N'ENV-539', N'PED-145', N'07-08-2026', N'28', N'4'),
    (N'ENV-540', N'PED-149', N'08-08-2026', N'30', N'3'),
    (N'ENV-541', N'PED-150', N'08-08-2026', N'31', N'3'),
    (N'ENV-542', N'PED-154', N'09/08/2026', N'60', N'1'),
    (N'ENV-543', N'PED-151', N'2026-08-09', N'54', N'2'),
    (N'ENV-544', N'PED-156', N'09/08/2026', N'49', N'2'),
    (N'ENV-545', N'PED-155', N'2026/08/09', N'50', N'2'),
    (N'ENV-546', N'PED-160', N'10/08/2026', N'62', N'9'),
    (N'ENV-547', N'PED-157', N'10/08/2026', N'53', N'3'),
    (N'ENV-548', N'PED-158', N'10/08/2026', N'57', N'1'),
    (N'ENV-549', N'PED-161', N'2026/08/11', N'26', N'4'),
    (N'ENV-550', N'PED-165', N'2026-08-11', N'56', N'2');
INSERT INTO stg.Entregas_Raw (ID_Envio, ID_Pedido, Fecha_Entrega, Minutos_Demora, Calificacion_Cliente) VALUES
    (N'ENV-551', N'PED-168', N'11/08/2026', N'31', N'4'),
    (N'ENV-552', N'PED-167', N'2026-08-11', N'39', N'3'),
    (N'ENV-553', N'PED-164', N'2026/08/11', N'34', N''),
    (N'ENV-554', N'PED-162', N'2026/08/12', N'32', N'4'),
    (N'ENV-555', N'PED-163', N'12/08/2026', N'26', N'4'),
    (N'ENV-556', N'PED-174', N'12/08/2026', N'21', N'5'),
    (N'ENV-557', N'PED-171', N'2026-08-12', N'35', N'4'),
    (N'ENV-558', N'PED-173', N'12/08/2026', N'31', N'4'),
    (N'ENV-559', N'PED-169', N'12-08-2026', N'33', N''),
    (N'ENV-560', N'PED-175', N'2026-08-12', N'26', N'3'),
    (N'ENV-561', N'PED-170', N'2026-08-12', N'21', N'5'),
    (N'ENV-562', N'PED-172', N'12-08-2026', N'24', N'4'),
    (N'ENV-563', N'PED-178', N'2026/08/13', N'25', N'5'),
    (N'ENV-564', N'PED-179', N'2026-08-13', N'33', N'4'),
    (N'ENV-565', N'PED-180 ', N'2026/08/13', N'32', N'4'),
    (N'ENV-566', N'PED-176', N'2026/08/13', N'35', N'4'),
    (N'ENV-567', N'PED-177', N'14/08/2026', N'30', N'4'),
    (N'ENV-568', N'PED-184', N'14/08/2026', N'', N'5'),
    (N'ENV-569', N'PED-185', N'14-08-2026', N'27', N'4'),
    (N'ENV-570', N'PED-183', N'2026-08-14', N'23', N'5'),
    (N'ENV-571', N'PED-187', N'2026/08/15', N'29', N''),
    (N'ENV-572', N'PED-190', N'2026/08/15', N'25', N'5'),
    (N'ENV-573', N'PED-193', N'15/08/2026', N'65', N'1'),
    (N'ENV-574', N'PED-189', N'2026-08-15', N'34', N'4'),
    (N'ENV-575', N'PED-192', N'15/08/2026', N'32', N'3'),
    (N'ENV-576', N'ped-188', N'15-08-2026', N'28', N'4'),
    (N'ENV-577', N'PED-196', N'2026/08/16', N'61', N''),
    (N'ENV-578', N'PED-195', N'2026/08/16', N'45', N'2'),
    (N'ENV-579', N'PED-199', N'17/08/2026', N'24', N'4'),
    (N'ENV-580', N'PED-200', N'2026/08/17', N'28', N''),
    (N'ENV-581', N'PED-202', N'17/08/2026', N'22', N'4'),
    (N'ENV-582', N'PED-204', N'17/08/2026', N'-28', N''),
    (N'ENV-583', N'PED-203', N'17/08/2026', N'17', N'5'),
    (N'ENV-584', N'PED-205', N'18-08-2026', N'21', N'5'),
    (N'ENV-585', N'PED-211', N'18/08/2026', N'21', N'4'),
    (N'ENV-586', N'PED-207', N'18-08-2026', N'21', N'4'),
    (N'ENV-587', N'PED-206', N'18-08-2026', N'26', N'4'),
    (N'ENV-588', N'PED-210', N'18-08-2026', N'41', N'3'),
    (N'ENV-589', N'PED-208', N'2026-08-18', N'36', N'4'),
    (N'ENV-590', N'PED-216', N'2026-08-19', N'27', N'3'),
    (N'ENV-591', N'PED-215', N'19/08/2026', N'26', N'4'),
    (N'ENV-592', N'PED-213', N'19/08/2026', N'35', N'4'),
    (N'ENV-593', N'PED-214', N'19-08-2026', N'', N'4'),
    (N'ENV-594', N'PED-217', N'19/08/2026', N'25', N'5'),
    (N'ENV-595', N'PED-212', N'19/08/2026', N'30', N'4'),
    (N'ENV-596', N'PED-218', N'20-08-2026', N'52', N'2'),
    (N'ENV-597', N'PED-220', N'2026/08/20', N'50', N'3'),
    (N'ENV-598', N'PED-222', N'20/08/2026', N'25', N'5'),
    (N'ENV-599', N'PED-219', N'20/08/2026', N'41', N'3'),
    (N'ENV-600', N'PED-227', N'2026-08-21', N'29', N'4');
INSERT INTO stg.Entregas_Raw (ID_Envio, ID_Pedido, Fecha_Entrega, Minutos_Demora, Calificacion_Cliente) VALUES
    (N'ENV-601', N'PED-226', N'2026-08-21', N'21', N'4'),
    (N'ENV-602', N'PED-228', N'21-08-2026', N'25', N'5'),
    (N'ENV-603', N'PED-229', N'21/08/2026', N'24', N'4'),
    (N'ENV-999', N'PED-999', N'05/08/2026', N'30', N'4'),
    (N'ENV-521', N'PED-122', N'2026/08/04', N'16', N''),
    (N'ENV-564', N'PED-179', N'2026-08-13', N'33', N'4'),
    (N'ENV-593', N'PED-214', N'19-08-2026', N'', N'4');
GO

-- Verificación de la extracción (resultado esperado: 42 | 135 | 65 | 107)
SELECT 'stg.Clientes_Raw' AS Tabla, COUNT(*) AS Registros FROM stg.Clientes_Raw
UNION ALL SELECT 'stg.Ventas_Raw',   COUNT(*) FROM stg.Ventas_Raw
UNION ALL SELECT 'stg.Clima_Raw',    COUNT(*) FROM stg.Clima_Raw
UNION ALL SELECT 'stg.Entregas_Raw', COUNT(*) FROM stg.Entregas_Raw;
GO
