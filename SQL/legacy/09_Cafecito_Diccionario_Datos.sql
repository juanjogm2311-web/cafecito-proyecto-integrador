--JUAN JOSÉ GÓMEZ MONTÚFAR
--196549-9
--21/10/2026

USE BD_Cafecito;
GO
SET NOCOUNT ON;
GO

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id = ep.major_id
           JOIN sys.schemas s ON s.schema_id = t.schema_id
           WHERE ep.name=N'MS_Description' AND s.name=N'dbo' AND t.name=N'Ciudad' AND ep.minor_id=0)
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Catálogo geográfico de las ciudades y estados donde opera Cafecito.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Ciudad';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Catálogo geográfico de las ciudades y estados donde opera Cafecito.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Ciudad';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id = ep.major_id
           JOIN sys.schemas s ON s.schema_id = t.schema_id
           JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ep.minor_id
           WHERE ep.name=N'MS_Description' AND s.name=N'dbo' AND t.name=N'Ciudad' AND c.name=N'ID_Ciudad')
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Identificador único de la ciudad utilizado como llave primaria y referencia geográfica.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Ciudad',
         @level2type=N'COLUMN', @level2name=N'ID_Ciudad';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Identificador único de la ciudad utilizado como llave primaria y referencia geográfica.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Ciudad',
         @level2type=N'COLUMN', @level2name=N'ID_Ciudad';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id = ep.major_id
           JOIN sys.schemas s ON s.schema_id = t.schema_id
           JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ep.minor_id
           WHERE ep.name=N'MS_Description' AND s.name=N'dbo' AND t.name=N'Ciudad' AND c.name=N'Nombre_Ciudad')
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Nombre normalizado de la ciudad donde se ubica una sucursal o cliente.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Ciudad',
         @level2type=N'COLUMN', @level2name=N'Nombre_Ciudad';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Nombre normalizado de la ciudad donde se ubica una sucursal o cliente.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Ciudad',
         @level2type=N'COLUMN', @level2name=N'Nombre_Ciudad';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id = ep.major_id
           JOIN sys.schemas s ON s.schema_id = t.schema_id
           JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ep.minor_id
           WHERE ep.name=N'MS_Description' AND s.name=N'dbo' AND t.name=N'Ciudad' AND c.name=N'Estado')
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Nombre del estado de la República Mexicana al que pertenece la ciudad.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Ciudad',
         @level2type=N'COLUMN', @level2name=N'Estado';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Nombre del estado de la República Mexicana al que pertenece la ciudad.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Ciudad',
         @level2type=N'COLUMN', @level2name=N'Estado';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id = ep.major_id
           JOIN sys.schemas s ON s.schema_id = t.schema_id
           WHERE ep.name=N'MS_Description' AND s.name=N'dbo' AND t.name=N'Sucursal' AND ep.minor_id=0)
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Catálogo de sucursales físicas de Cafecito y su ubicación geográfica.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Sucursal';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Catálogo de sucursales físicas de Cafecito y su ubicación geográfica.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Sucursal';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id = ep.major_id
           JOIN sys.schemas s ON s.schema_id = t.schema_id
           JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ep.minor_id
           WHERE ep.name=N'MS_Description' AND s.name=N'dbo' AND t.name=N'Sucursal' AND c.name=N'ID_Sucursal')
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Identificador único de la sucursal, usado para relacionar pedidos con el punto de venta.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Sucursal',
         @level2type=N'COLUMN', @level2name=N'ID_Sucursal';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Identificador único de la sucursal, usado para relacionar pedidos con el punto de venta.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Sucursal',
         @level2type=N'COLUMN', @level2name=N'ID_Sucursal';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id = ep.major_id
           JOIN sys.schemas s ON s.schema_id = t.schema_id
           JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ep.minor_id
           WHERE ep.name=N'MS_Description' AND s.name=N'dbo' AND t.name=N'Sucursal' AND c.name=N'Nombre_Sucursal')
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Nombre comercial de la sucursal de Cafecito.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Sucursal',
         @level2type=N'COLUMN', @level2name=N'Nombre_Sucursal';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Nombre comercial de la sucursal de Cafecito.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Sucursal',
         @level2type=N'COLUMN', @level2name=N'Nombre_Sucursal';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id = ep.major_id
           JOIN sys.schemas s ON s.schema_id = t.schema_id
           JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ep.minor_id
           WHERE ep.name=N'MS_Description' AND s.name=N'dbo' AND t.name=N'Sucursal' AND c.name=N'ID_Ciudad')
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Identificador de la ciudad donde se encuentra la sucursal; referencia al catálogo Ciudad.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Sucursal',
         @level2type=N'COLUMN', @level2name=N'ID_Ciudad';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Identificador de la ciudad donde se encuentra la sucursal; referencia al catálogo Ciudad.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Sucursal',
         @level2type=N'COLUMN', @level2name=N'ID_Ciudad';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id = ep.major_id
           JOIN sys.schemas s ON s.schema_id = t.schema_id
           WHERE ep.name=N'MS_Description' AND s.name=N'dbo' AND t.name=N'Categoria_Producto' AND ep.minor_id=0)
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Catálogo de categorías de productos ofrecidos por Cafecito y su temperatura de servicio.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Categoria_Producto';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Catálogo de categorías de productos ofrecidos por Cafecito y su temperatura de servicio.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Categoria_Producto';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id = ep.major_id
           JOIN sys.schemas s ON s.schema_id = t.schema_id
           JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ep.minor_id
           WHERE ep.name=N'MS_Description' AND s.name=N'dbo' AND t.name=N'Categoria_Producto' AND c.name=N'ID_Categoria')
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Identificador único de la categoría de producto.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Categoria_Producto',
         @level2type=N'COLUMN', @level2name=N'ID_Categoria';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Identificador único de la categoría de producto.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Categoria_Producto',
         @level2type=N'COLUMN', @level2name=N'ID_Categoria';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id = ep.major_id
           JOIN sys.schemas s ON s.schema_id = t.schema_id
           JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ep.minor_id
           WHERE ep.name=N'MS_Description' AND s.name=N'dbo' AND t.name=N'Categoria_Producto' AND c.name=N'Nombre_Categoria')
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Nombre comercial de la categoría de producto.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Categoria_Producto',
         @level2type=N'COLUMN', @level2name=N'Nombre_Categoria';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Nombre comercial de la categoría de producto.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Categoria_Producto',
         @level2type=N'COLUMN', @level2name=N'Nombre_Categoria';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id = ep.major_id
           JOIN sys.schemas s ON s.schema_id = t.schema_id
           JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ep.minor_id
           WHERE ep.name=N'MS_Description' AND s.name=N'dbo' AND t.name=N'Categoria_Producto' AND c.name=N'Temperatura_Servicio')
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Clasificación de la temperatura de servicio de la categoría: caliente, fría o no aplica.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Categoria_Producto',
         @level2type=N'COLUMN', @level2name=N'Temperatura_Servicio';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Clasificación de la temperatura de servicio de la categoría: caliente, fría o no aplica.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Categoria_Producto',
         @level2type=N'COLUMN', @level2name=N'Temperatura_Servicio';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id = ep.major_id
           JOIN sys.schemas s ON s.schema_id = t.schema_id
           WHERE ep.name=N'MS_Description' AND s.name=N'dbo' AND t.name=N'Cliente' AND ep.minor_id=0)
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Entidad maestra con los datos de identificación y contacto de los clientes de Cafecito.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Cliente';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Entidad maestra con los datos de identificación y contacto de los clientes de Cafecito.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Cliente';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id = ep.major_id
           JOIN sys.schemas s ON s.schema_id = t.schema_id
           JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ep.minor_id
           WHERE ep.name=N'MS_Description' AND s.name=N'dbo' AND t.name=N'Cliente' AND c.name=N'ID_Cliente')
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Identificador único del cliente dentro del modelo integrado.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Cliente',
         @level2type=N'COLUMN', @level2name=N'ID_Cliente';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Identificador único del cliente dentro del modelo integrado.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Cliente',
         @level2type=N'COLUMN', @level2name=N'ID_Cliente';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id = ep.major_id
           JOIN sys.schemas s ON s.schema_id = t.schema_id
           JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ep.minor_id
           WHERE ep.name=N'MS_Description' AND s.name=N'dbo' AND t.name=N'Cliente' AND c.name=N'Nombre_Completo')
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Nombre completo del cliente, normalizado para su identificación comercial.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Cliente',
         @level2type=N'COLUMN', @level2name=N'Nombre_Completo';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Nombre completo del cliente, normalizado para su identificación comercial.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Cliente',
         @level2type=N'COLUMN', @level2name=N'Nombre_Completo';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id = ep.major_id
           JOIN sys.schemas s ON s.schema_id = t.schema_id
           JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ep.minor_id
           WHERE ep.name=N'MS_Description' AND s.name=N'dbo' AND t.name=N'Cliente' AND c.name=N'Email')
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Correo electrónico del cliente; se utiliza como dato de contacto y control de unicidad.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Cliente',
         @level2type=N'COLUMN', @level2name=N'Email';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Correo electrónico del cliente; se utiliza como dato de contacto y control de unicidad.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Cliente',
         @level2type=N'COLUMN', @level2name=N'Email';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id = ep.major_id
           JOIN sys.schemas s ON s.schema_id = t.schema_id
           JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ep.minor_id
           WHERE ep.name=N'MS_Description' AND s.name=N'dbo' AND t.name=N'Cliente' AND c.name=N'Telefono')
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Número telefónico de contacto del cliente; puede no estar disponible.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Cliente',
         @level2type=N'COLUMN', @level2name=N'Telefono';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Número telefónico de contacto del cliente; puede no estar disponible.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Cliente',
         @level2type=N'COLUMN', @level2name=N'Telefono';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id = ep.major_id
           JOIN sys.schemas s ON s.schema_id = t.schema_id
           JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ep.minor_id
           WHERE ep.name=N'MS_Description' AND s.name=N'dbo' AND t.name=N'Cliente' AND c.name=N'ID_Ciudad')
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Identificador de la ciudad asociada al cliente; referencia al catálogo Ciudad.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Cliente',
         @level2type=N'COLUMN', @level2name=N'ID_Ciudad';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Identificador de la ciudad asociada al cliente; referencia al catálogo Ciudad.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Cliente',
         @level2type=N'COLUMN', @level2name=N'ID_Ciudad';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id = ep.major_id
           JOIN sys.schemas s ON s.schema_id = t.schema_id
           JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ep.minor_id
           WHERE ep.name=N'MS_Description' AND s.name=N'dbo' AND t.name=N'Cliente' AND c.name=N'Fecha_Registro')
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Fecha en que el cliente fue registrado en el sistema.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Cliente',
         @level2type=N'COLUMN', @level2name=N'Fecha_Registro';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Fecha en que el cliente fue registrado en el sistema.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Cliente',
         @level2type=N'COLUMN', @level2name=N'Fecha_Registro';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id = ep.major_id
           JOIN sys.schemas s ON s.schema_id = t.schema_id
           WHERE ep.name=N'MS_Description' AND s.name=N'dbo' AND t.name=N'Pedido' AND ep.minor_id=0)
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Tabla transaccional que registra los pedidos, su cliente, sucursal, categoría, fecha y monto.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Pedido';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Tabla transaccional que registra los pedidos, su cliente, sucursal, categoría, fecha y monto.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Pedido';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id = ep.major_id
           JOIN sys.schemas s ON s.schema_id = t.schema_id
           JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ep.minor_id
           WHERE ep.name=N'MS_Description' AND s.name=N'dbo' AND t.name=N'Pedido' AND c.name=N'ID_Pedido')
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Identificador único del pedido de Cafecito.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Pedido',
         @level2type=N'COLUMN', @level2name=N'ID_Pedido';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Identificador único del pedido de Cafecito.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Pedido',
         @level2type=N'COLUMN', @level2name=N'ID_Pedido';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id = ep.major_id
           JOIN sys.schemas s ON s.schema_id = t.schema_id
           JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ep.minor_id
           WHERE ep.name=N'MS_Description' AND s.name=N'dbo' AND t.name=N'Pedido' AND c.name=N'ID_Cliente')
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Identificador del cliente que realizó el pedido; referencia a Cliente.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Pedido',
         @level2type=N'COLUMN', @level2name=N'ID_Cliente';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Identificador del cliente que realizó el pedido; referencia a Cliente.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Pedido',
         @level2type=N'COLUMN', @level2name=N'ID_Cliente';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id = ep.major_id
           JOIN sys.schemas s ON s.schema_id = t.schema_id
           JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ep.minor_id
           WHERE ep.name=N'MS_Description' AND s.name=N'dbo' AND t.name=N'Pedido' AND c.name=N'ID_Sucursal')
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Identificador de la sucursal que atendió el pedido; referencia a Sucursal.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Pedido',
         @level2type=N'COLUMN', @level2name=N'ID_Sucursal';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Identificador de la sucursal que atendió el pedido; referencia a Sucursal.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Pedido',
         @level2type=N'COLUMN', @level2name=N'ID_Sucursal';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id = ep.major_id
           JOIN sys.schemas s ON s.schema_id = t.schema_id
           JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ep.minor_id
           WHERE ep.name=N'MS_Description' AND s.name=N'dbo' AND t.name=N'Pedido' AND c.name=N'ID_Categoria')
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Identificador de la categoría del producto pedido; referencia a Categoria_Producto.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Pedido',
         @level2type=N'COLUMN', @level2name=N'ID_Categoria';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Identificador de la categoría del producto pedido; referencia a Categoria_Producto.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Pedido',
         @level2type=N'COLUMN', @level2name=N'ID_Categoria';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id = ep.major_id
           JOIN sys.schemas s ON s.schema_id = t.schema_id
           JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ep.minor_id
           WHERE ep.name=N'MS_Description' AND s.name=N'dbo' AND t.name=N'Pedido' AND c.name=N'Fecha_Hora')
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Fecha y hora en que se registró el pedido.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Pedido',
         @level2type=N'COLUMN', @level2name=N'Fecha_Hora';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Fecha y hora en que se registró el pedido.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Pedido',
         @level2type=N'COLUMN', @level2name=N'Fecha_Hora';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id = ep.major_id
           JOIN sys.schemas s ON s.schema_id = t.schema_id
           JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ep.minor_id
           WHERE ep.name=N'MS_Description' AND s.name=N'dbo' AND t.name=N'Pedido' AND c.name=N'Fecha')
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Fecha derivada de Fecha_Hora para análisis temporal y cruce con la información climática.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Pedido',
         @level2type=N'COLUMN', @level2name=N'Fecha';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Fecha derivada de Fecha_Hora para análisis temporal y cruce con la información climática.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Pedido',
         @level2type=N'COLUMN', @level2name=N'Fecha';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id = ep.major_id
           JOIN sys.schemas s ON s.schema_id = t.schema_id
           JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ep.minor_id
           WHERE ep.name=N'MS_Description' AND s.name=N'dbo' AND t.name=N'Pedido' AND c.name=N'Monto_Total')
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Importe total del pedido expresado en pesos mexicanos (MXN).',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Pedido',
         @level2type=N'COLUMN', @level2name=N'Monto_Total';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Importe total del pedido expresado en pesos mexicanos (MXN).',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Pedido',
         @level2type=N'COLUMN', @level2name=N'Monto_Total';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id = ep.major_id
           JOIN sys.schemas s ON s.schema_id = t.schema_id
           WHERE ep.name=N'MS_Description' AND s.name=N'dbo' AND t.name=N'Clima_Diario' AND ep.minor_id=0)
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Tabla de contexto climático diario por ciudad, utilizada para analizar ventas y entregas según el clima.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Clima_Diario';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Tabla de contexto climático diario por ciudad, utilizada para analizar ventas y entregas según el clima.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Clima_Diario';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id = ep.major_id
           JOIN sys.schemas s ON s.schema_id = t.schema_id
           JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ep.minor_id
           WHERE ep.name=N'MS_Description' AND s.name=N'dbo' AND t.name=N'Clima_Diario' AND c.name=N'ID_Clima')
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Identificador único del registro climático.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Clima_Diario',
         @level2type=N'COLUMN', @level2name=N'ID_Clima';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Identificador único del registro climático.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Clima_Diario',
         @level2type=N'COLUMN', @level2name=N'ID_Clima';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id = ep.major_id
           JOIN sys.schemas s ON s.schema_id = t.schema_id
           JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ep.minor_id
           WHERE ep.name=N'MS_Description' AND s.name=N'dbo' AND t.name=N'Clima_Diario' AND c.name=N'Fecha')
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Fecha a la que corresponden las condiciones climáticas.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Clima_Diario',
         @level2type=N'COLUMN', @level2name=N'Fecha';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Fecha a la que corresponden las condiciones climáticas.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Clima_Diario',
         @level2type=N'COLUMN', @level2name=N'Fecha';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id = ep.major_id
           JOIN sys.schemas s ON s.schema_id = t.schema_id
           JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ep.minor_id
           WHERE ep.name=N'MS_Description' AND s.name=N'dbo' AND t.name=N'Clima_Diario' AND c.name=N'ID_Ciudad')
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Identificador de la ciudad observada; referencia al catálogo Ciudad.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Clima_Diario',
         @level2type=N'COLUMN', @level2name=N'ID_Ciudad';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Identificador de la ciudad observada; referencia al catálogo Ciudad.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Clima_Diario',
         @level2type=N'COLUMN', @level2name=N'ID_Ciudad';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id = ep.major_id
           JOIN sys.schemas s ON s.schema_id = t.schema_id
           JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ep.minor_id
           WHERE ep.name=N'MS_Description' AND s.name=N'dbo' AND t.name=N'Clima_Diario' AND c.name=N'Temperatura_C')
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Temperatura registrada en grados Celsius.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Clima_Diario',
         @level2type=N'COLUMN', @level2name=N'Temperatura_C';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Temperatura registrada en grados Celsius.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Clima_Diario',
         @level2type=N'COLUMN', @level2name=N'Temperatura_C';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id = ep.major_id
           JOIN sys.schemas s ON s.schema_id = t.schema_id
           JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ep.minor_id
           WHERE ep.name=N'MS_Description' AND s.name=N'dbo' AND t.name=N'Clima_Diario' AND c.name=N'Condicion_Climatica')
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Categoría descriptiva de las condiciones climáticas del día.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Clima_Diario',
         @level2type=N'COLUMN', @level2name=N'Condicion_Climatica';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Categoría descriptiva de las condiciones climáticas del día.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Clima_Diario',
         @level2type=N'COLUMN', @level2name=N'Condicion_Climatica';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id = ep.major_id
           JOIN sys.schemas s ON s.schema_id = t.schema_id
           JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ep.minor_id
           WHERE ep.name=N'MS_Description' AND s.name=N'dbo' AND t.name=N'Clima_Diario' AND c.name=N'Humedad_Pct')
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Porcentaje de humedad relativa; puede ser nulo cuando no se cuenta con el dato.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Clima_Diario',
         @level2type=N'COLUMN', @level2name=N'Humedad_Pct';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Porcentaje de humedad relativa; puede ser nulo cuando no se cuenta con el dato.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Clima_Diario',
         @level2type=N'COLUMN', @level2name=N'Humedad_Pct';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id = ep.major_id
           JOIN sys.schemas s ON s.schema_id = t.schema_id
           JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ep.minor_id
           WHERE ep.name=N'MS_Description' AND s.name=N'dbo' AND t.name=N'Clima_Diario' AND c.name=N'Temperatura_Imputada')
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Indicador que señala si la temperatura fue completada mediante imputación de datos.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Clima_Diario',
         @level2type=N'COLUMN', @level2name=N'Temperatura_Imputada';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Indicador que señala si la temperatura fue completada mediante imputación de datos.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Clima_Diario',
         @level2type=N'COLUMN', @level2name=N'Temperatura_Imputada';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id = ep.major_id
           JOIN sys.schemas s ON s.schema_id = t.schema_id
           WHERE ep.name=N'MS_Description' AND s.name=N'dbo' AND t.name=N'Entrega' AND ep.minor_id=0)
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Tabla transaccional de entregas vinculadas a pedidos, con demora y evaluación del cliente.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Entrega';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Tabla transaccional de entregas vinculadas a pedidos, con demora y evaluación del cliente.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Entrega';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id = ep.major_id
           JOIN sys.schemas s ON s.schema_id = t.schema_id
           JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ep.minor_id
           WHERE ep.name=N'MS_Description' AND s.name=N'dbo' AND t.name=N'Entrega' AND c.name=N'ID_Envio')
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Identificador único del envío o entrega.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Entrega',
         @level2type=N'COLUMN', @level2name=N'ID_Envio';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Identificador único del envío o entrega.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Entrega',
         @level2type=N'COLUMN', @level2name=N'ID_Envio';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id = ep.major_id
           JOIN sys.schemas s ON s.schema_id = t.schema_id
           JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ep.minor_id
           WHERE ep.name=N'MS_Description' AND s.name=N'dbo' AND t.name=N'Entrega' AND c.name=N'ID_Pedido')
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Identificador del pedido asociado a la entrega; referencia a Pedido.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Entrega',
         @level2type=N'COLUMN', @level2name=N'ID_Pedido';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Identificador del pedido asociado a la entrega; referencia a Pedido.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Entrega',
         @level2type=N'COLUMN', @level2name=N'ID_Pedido';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id = ep.major_id
           JOIN sys.schemas s ON s.schema_id = t.schema_id
           JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ep.minor_id
           WHERE ep.name=N'MS_Description' AND s.name=N'dbo' AND t.name=N'Entrega' AND c.name=N'Fecha_Entrega')
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Fecha en que se realizó la entrega.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Entrega',
         @level2type=N'COLUMN', @level2name=N'Fecha_Entrega';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Fecha en que se realizó la entrega.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Entrega',
         @level2type=N'COLUMN', @level2name=N'Fecha_Entrega';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id = ep.major_id
           JOIN sys.schemas s ON s.schema_id = t.schema_id
           JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ep.minor_id
           WHERE ep.name=N'MS_Description' AND s.name=N'dbo' AND t.name=N'Entrega' AND c.name=N'Minutos_Demora')
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Cantidad de minutos de demora registrados para la entrega.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Entrega',
         @level2type=N'COLUMN', @level2name=N'Minutos_Demora';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Cantidad de minutos de demora registrados para la entrega.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Entrega',
         @level2type=N'COLUMN', @level2name=N'Minutos_Demora';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id = ep.major_id
           JOIN sys.schemas s ON s.schema_id = t.schema_id
           JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ep.minor_id
           WHERE ep.name=N'MS_Description' AND s.name=N'dbo' AND t.name=N'Entrega' AND c.name=N'Calificacion_Cliente')
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Calificación otorgada por el cliente en una escala de 1 a 5.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Entrega',
         @level2type=N'COLUMN', @level2name=N'Calificacion_Cliente';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Calificación otorgada por el cliente en una escala de 1 a 5.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Entrega',
         @level2type=N'COLUMN', @level2name=N'Calificacion_Cliente';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id = ep.major_id
           JOIN sys.schemas s ON s.schema_id = t.schema_id
           JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ep.minor_id
           WHERE ep.name=N'MS_Description' AND s.name=N'dbo' AND t.name=N'Entrega' AND c.name=N'Demora_Imputada')
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Indicador que señala si los minutos de demora fueron imputados.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Entrega',
         @level2type=N'COLUMN', @level2name=N'Demora_Imputada';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Indicador que señala si los minutos de demora fueron imputados.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Entrega',
         @level2type=N'COLUMN', @level2name=N'Demora_Imputada';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id = ep.major_id
           JOIN sys.schemas s ON s.schema_id = t.schema_id
           JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ep.minor_id
           WHERE ep.name=N'MS_Description' AND s.name=N'dbo' AND t.name=N'Entrega' AND c.name=N'Calificacion_Imputada')
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Indicador que señala si la calificación del cliente fue imputada.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Entrega',
         @level2type=N'COLUMN', @level2name=N'Calificacion_Imputada';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Indicador que señala si la calificación del cliente fue imputada.',
         @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Entrega',
         @level2type=N'COLUMN', @level2name=N'Calificacion_Imputada';

/* 2. Descripciones de las tablas de staging y de todas sus columnas */

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id=ep.major_id JOIN sys.schemas s ON s.schema_id=t.schema_id
           WHERE ep.name=N'MS_Description' AND s.name=N'stg' AND t.name=N'Clientes_Raw' AND ep.minor_id=0)
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Capa de aterrizaje con datos de clientes recibidos desde el sistema de origen, antes de la limpieza.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Clientes_Raw';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Capa de aterrizaje con datos de clientes recibidos desde el sistema de origen, antes de la limpieza.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Clientes_Raw';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id=ep.major_id JOIN sys.schemas s ON s.schema_id=t.schema_id
           JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ep.minor_id
           WHERE ep.name=N'MS_Description' AND s.name=N'stg' AND t.name=N'Clientes_Raw' AND c.name=N'ID_Carga')
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Identificador secuencial del registro recibido en staging.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Clientes_Raw',
         @level2type=N'COLUMN', @level2name=N'ID_Carga';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Identificador secuencial del registro recibido en staging.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Clientes_Raw',
         @level2type=N'COLUMN', @level2name=N'ID_Carga';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id=ep.major_id JOIN sys.schemas s ON s.schema_id=t.schema_id
           JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ep.minor_id
           WHERE ep.name=N'MS_Description' AND s.name=N'stg' AND t.name=N'Clientes_Raw' AND c.name=N'ID_Cliente')
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Identificador del cliente tal como fue recibido desde el origen.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Clientes_Raw',
         @level2type=N'COLUMN', @level2name=N'ID_Cliente';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Identificador del cliente tal como fue recibido desde el origen.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Clientes_Raw',
         @level2type=N'COLUMN', @level2name=N'ID_Cliente';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id=ep.major_id JOIN sys.schemas s ON s.schema_id=t.schema_id
           JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ep.minor_id
           WHERE ep.name=N'MS_Description' AND s.name=N'stg' AND t.name=N'Clientes_Raw' AND c.name=N'Nombre')
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Nombre del cliente tal como fue recibido desde el origen.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Clientes_Raw',
         @level2type=N'COLUMN', @level2name=N'Nombre';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Nombre del cliente tal como fue recibido desde el origen.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Clientes_Raw',
         @level2type=N'COLUMN', @level2name=N'Nombre';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id=ep.major_id JOIN sys.schemas s ON s.schema_id=t.schema_id
           JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ep.minor_id
           WHERE ep.name=N'MS_Description' AND s.name=N'stg' AND t.name=N'Clientes_Raw' AND c.name=N'Email')
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Correo electrónico del cliente tal como fue recibido desde el origen.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Clientes_Raw',
         @level2type=N'COLUMN', @level2name=N'Email';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Correo electrónico del cliente tal como fue recibido desde el origen.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Clientes_Raw',
         @level2type=N'COLUMN', @level2name=N'Email';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id=ep.major_id JOIN sys.schemas s ON s.schema_id=t.schema_id
           JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ep.minor_id
           WHERE ep.name=N'MS_Description' AND s.name=N'stg' AND t.name=N'Clientes_Raw' AND c.name=N'Telefono')
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Teléfono del cliente tal como fue recibido desde el origen.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Clientes_Raw',
         @level2type=N'COLUMN', @level2name=N'Telefono';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Teléfono del cliente tal como fue recibido desde el origen.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Clientes_Raw',
         @level2type=N'COLUMN', @level2name=N'Telefono';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id=ep.major_id JOIN sys.schemas s ON s.schema_id=t.schema_id
           JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ep.minor_id
           WHERE ep.name=N'MS_Description' AND s.name=N'stg' AND t.name=N'Clientes_Raw' AND c.name=N'Ciudad')
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Ciudad del cliente tal como fue recibida desde el origen.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Clientes_Raw',
         @level2type=N'COLUMN', @level2name=N'Ciudad';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Ciudad del cliente tal como fue recibida desde el origen.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Clientes_Raw',
         @level2type=N'COLUMN', @level2name=N'Ciudad';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id=ep.major_id JOIN sys.schemas s ON s.schema_id=t.schema_id
           JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ep.minor_id
           WHERE ep.name=N'MS_Description' AND s.name=N'stg' AND t.name=N'Clientes_Raw' AND c.name=N'Fecha_Registro')
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Fecha de registro en el formato original recibido.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Clientes_Raw',
         @level2type=N'COLUMN', @level2name=N'Fecha_Registro';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Fecha de registro en el formato original recibido.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Clientes_Raw',
         @level2type=N'COLUMN', @level2name=N'Fecha_Registro';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id=ep.major_id JOIN sys.schemas s ON s.schema_id=t.schema_id
           JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ep.minor_id
           WHERE ep.name=N'MS_Description' AND s.name=N'stg' AND t.name=N'Clientes_Raw' AND c.name=N'Fecha_Carga')
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Fecha y hora en que el registro fue cargado a staging.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Clientes_Raw',
         @level2type=N'COLUMN', @level2name=N'Fecha_Carga';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Fecha y hora en que el registro fue cargado a staging.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Clientes_Raw',
         @level2type=N'COLUMN', @level2name=N'Fecha_Carga';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id=ep.major_id JOIN sys.schemas s ON s.schema_id=t.schema_id
           WHERE ep.name=N'MS_Description' AND s.name=N'stg' AND t.name=N'Ventas_Raw' AND ep.minor_id=0)
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Capa de aterrizaje con pedidos recibidos del sistema de ventas, conservando los valores originales como texto.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Ventas_Raw';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Capa de aterrizaje con pedidos recibidos del sistema de ventas, conservando los valores originales como texto.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Ventas_Raw';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id=ep.major_id JOIN sys.schemas s ON s.schema_id=t.schema_id
           JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ep.minor_id
           WHERE ep.name=N'MS_Description' AND s.name=N'stg' AND t.name=N'Ventas_Raw' AND c.name=N'ID_Carga')
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Identificador secuencial del registro recibido en staging.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Ventas_Raw',
         @level2type=N'COLUMN', @level2name=N'ID_Carga';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Identificador secuencial del registro recibido en staging.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Ventas_Raw',
         @level2type=N'COLUMN', @level2name=N'ID_Carga';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id=ep.major_id JOIN sys.schemas s ON s.schema_id=t.schema_id
           JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ep.minor_id
           WHERE ep.name=N'MS_Description' AND s.name=N'stg' AND t.name=N'Ventas_Raw' AND c.name=N'ID_Pedido')
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Identificador del pedido tal como fue recibido desde el origen.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Ventas_Raw',
         @level2type=N'COLUMN', @level2name=N'ID_Pedido';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Identificador del pedido tal como fue recibido desde el origen.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Ventas_Raw',
         @level2type=N'COLUMN', @level2name=N'ID_Pedido';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id=ep.major_id JOIN sys.schemas s ON s.schema_id=t.schema_id
           JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ep.minor_id
           WHERE ep.name=N'MS_Description' AND s.name=N'stg' AND t.name=N'Ventas_Raw' AND c.name=N'ID_Cliente')
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Identificador del cliente asociado tal como fue recibido.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Ventas_Raw',
         @level2type=N'COLUMN', @level2name=N'ID_Cliente';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Identificador del cliente asociado tal como fue recibido.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Ventas_Raw',
         @level2type=N'COLUMN', @level2name=N'ID_Cliente';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id=ep.major_id JOIN sys.schemas s ON s.schema_id=t.schema_id
           JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ep.minor_id
           WHERE ep.name=N'MS_Description' AND s.name=N'stg' AND t.name=N'Ventas_Raw' AND c.name=N'Fecha_Hora')
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Fecha y hora del pedido en su formato original.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Ventas_Raw',
         @level2type=N'COLUMN', @level2name=N'Fecha_Hora';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Fecha y hora del pedido en su formato original.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Ventas_Raw',
         @level2type=N'COLUMN', @level2name=N'Fecha_Hora';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id=ep.major_id JOIN sys.schemas s ON s.schema_id=t.schema_id
           JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ep.minor_id
           WHERE ep.name=N'MS_Description' AND s.name=N'stg' AND t.name=N'Ventas_Raw' AND c.name=N'ID_Sucursal')
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Identificador de sucursal tal como fue recibido.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Ventas_Raw',
         @level2type=N'COLUMN', @level2name=N'ID_Sucursal';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Identificador de sucursal tal como fue recibido.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Ventas_Raw',
         @level2type=N'COLUMN', @level2name=N'ID_Sucursal';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id=ep.major_id JOIN sys.schemas s ON s.schema_id=t.schema_id
           JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ep.minor_id
           WHERE ep.name=N'MS_Description' AND s.name=N'stg' AND t.name=N'Ventas_Raw' AND c.name=N'Tipo_Producto')
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Tipo de producto reportado por el sistema de ventas.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Ventas_Raw',
         @level2type=N'COLUMN', @level2name=N'Tipo_Producto';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Tipo de producto reportado por el sistema de ventas.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Ventas_Raw',
         @level2type=N'COLUMN', @level2name=N'Tipo_Producto';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id=ep.major_id JOIN sys.schemas s ON s.schema_id=t.schema_id
           JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ep.minor_id
           WHERE ep.name=N'MS_Description' AND s.name=N'stg' AND t.name=N'Ventas_Raw' AND c.name=N'Monto_Total')
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Importe total del pedido en su formato original.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Ventas_Raw',
         @level2type=N'COLUMN', @level2name=N'Monto_Total';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Importe total del pedido en su formato original.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Ventas_Raw',
         @level2type=N'COLUMN', @level2name=N'Monto_Total';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id=ep.major_id JOIN sys.schemas s ON s.schema_id=t.schema_id
           JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ep.minor_id
           WHERE ep.name=N'MS_Description' AND s.name=N'stg' AND t.name=N'Ventas_Raw' AND c.name=N'Sucursal_Ciudad')
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Ciudad de la sucursal tal como fue recibida.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Ventas_Raw',
         @level2type=N'COLUMN', @level2name=N'Sucursal_Ciudad';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Ciudad de la sucursal tal como fue recibida.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Ventas_Raw',
         @level2type=N'COLUMN', @level2name=N'Sucursal_Ciudad';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id=ep.major_id JOIN sys.schemas s ON s.schema_id=t.schema_id
           JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ep.minor_id
           WHERE ep.name=N'MS_Description' AND s.name=N'stg' AND t.name=N'Ventas_Raw' AND c.name=N'Fecha_Carga')
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Fecha y hora en que el registro fue cargado a staging.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Ventas_Raw',
         @level2type=N'COLUMN', @level2name=N'Fecha_Carga';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Fecha y hora en que el registro fue cargado a staging.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Ventas_Raw',
         @level2type=N'COLUMN', @level2name=N'Fecha_Carga';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id=ep.major_id JOIN sys.schemas s ON s.schema_id=t.schema_id
           WHERE ep.name=N'MS_Description' AND s.name=N'stg' AND t.name=N'Clima_JSON_Raw' AND ep.minor_id=0)
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Almacena la respuesta JSON original de la API climática para conservar evidencia del origen.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Clima_JSON_Raw';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Almacena la respuesta JSON original de la API climática para conservar evidencia del origen.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Clima_JSON_Raw';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id=ep.major_id JOIN sys.schemas s ON s.schema_id=t.schema_id
           JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ep.minor_id
           WHERE ep.name=N'MS_Description' AND s.name=N'stg' AND t.name=N'Clima_JSON_Raw' AND c.name=N'ID_Respuesta')
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Identificador secuencial de la respuesta JSON almacenada.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Clima_JSON_Raw',
         @level2type=N'COLUMN', @level2name=N'ID_Respuesta';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Identificador secuencial de la respuesta JSON almacenada.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Clima_JSON_Raw',
         @level2type=N'COLUMN', @level2name=N'ID_Respuesta';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id=ep.major_id JOIN sys.schemas s ON s.schema_id=t.schema_id
           JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ep.minor_id
           WHERE ep.name=N'MS_Description' AND s.name=N'stg' AND t.name=N'Clima_JSON_Raw' AND c.name=N'Respuesta_JSON')
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Contenido JSON original recibido de la API de clima.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Clima_JSON_Raw',
         @level2type=N'COLUMN', @level2name=N'Respuesta_JSON';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Contenido JSON original recibido de la API de clima.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Clima_JSON_Raw',
         @level2type=N'COLUMN', @level2name=N'Respuesta_JSON';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id=ep.major_id JOIN sys.schemas s ON s.schema_id=t.schema_id
           JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ep.minor_id
           WHERE ep.name=N'MS_Description' AND s.name=N'stg' AND t.name=N'Clima_JSON_Raw' AND c.name=N'Fecha_Carga')
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Fecha y hora en que se almacenó la respuesta JSON.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Clima_JSON_Raw',
         @level2type=N'COLUMN', @level2name=N'Fecha_Carga';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Fecha y hora en que se almacenó la respuesta JSON.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Clima_JSON_Raw',
         @level2type=N'COLUMN', @level2name=N'Fecha_Carga';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id=ep.major_id JOIN sys.schemas s ON s.schema_id=t.schema_id
           WHERE ep.name=N'MS_Description' AND s.name=N'stg' AND t.name=N'Clima_Raw' AND ep.minor_id=0)
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Capa de aterrizaje con datos climáticos aplanados por fecha y ciudad antes de su normalización.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Clima_Raw';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Capa de aterrizaje con datos climáticos aplanados por fecha y ciudad antes de su normalización.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Clima_Raw';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id=ep.major_id JOIN sys.schemas s ON s.schema_id=t.schema_id
           JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ep.minor_id
           WHERE ep.name=N'MS_Description' AND s.name=N'stg' AND t.name=N'Clima_Raw' AND c.name=N'ID_Carga')
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Identificador secuencial del registro recibido en staging.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Clima_Raw',
         @level2type=N'COLUMN', @level2name=N'ID_Carga';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Identificador secuencial del registro recibido en staging.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Clima_Raw',
         @level2type=N'COLUMN', @level2name=N'ID_Carga';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id=ep.major_id JOIN sys.schemas s ON s.schema_id=t.schema_id
           JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ep.minor_id
           WHERE ep.name=N'MS_Description' AND s.name=N'stg' AND t.name=N'Clima_Raw' AND c.name=N'Fecha_Consulta')
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Fecha de observación climática en el formato original.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Clima_Raw',
         @level2type=N'COLUMN', @level2name=N'Fecha_Consulta';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Fecha de observación climática en el formato original.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Clima_Raw',
         @level2type=N'COLUMN', @level2name=N'Fecha_Consulta';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id=ep.major_id JOIN sys.schemas s ON s.schema_id=t.schema_id
           JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ep.minor_id
           WHERE ep.name=N'MS_Description' AND s.name=N'stg' AND t.name=N'Clima_Raw' AND c.name=N'Ciudad')
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Nombre de ciudad tal como fue recibido.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Clima_Raw',
         @level2type=N'COLUMN', @level2name=N'Ciudad';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Nombre de ciudad tal como fue recibido.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Clima_Raw',
         @level2type=N'COLUMN', @level2name=N'Ciudad';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id=ep.major_id JOIN sys.schemas s ON s.schema_id=t.schema_id
           JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ep.minor_id
           WHERE ep.name=N'MS_Description' AND s.name=N'stg' AND t.name=N'Clima_Raw' AND c.name=N'Temperatura_C')
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Temperatura en grados Celsius tal como fue recibida.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Clima_Raw',
         @level2type=N'COLUMN', @level2name=N'Temperatura_C';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Temperatura en grados Celsius tal como fue recibida.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Clima_Raw',
         @level2type=N'COLUMN', @level2name=N'Temperatura_C';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id=ep.major_id JOIN sys.schemas s ON s.schema_id=t.schema_id
           JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ep.minor_id
           WHERE ep.name=N'MS_Description' AND s.name=N'stg' AND t.name=N'Clima_Raw' AND c.name=N'Condicion_Climatica')
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Descripción climática original recibida.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Clima_Raw',
         @level2type=N'COLUMN', @level2name=N'Condicion_Climatica';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Descripción climática original recibida.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Clima_Raw',
         @level2type=N'COLUMN', @level2name=N'Condicion_Climatica';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id=ep.major_id JOIN sys.schemas s ON s.schema_id=t.schema_id
           JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ep.minor_id
           WHERE ep.name=N'MS_Description' AND s.name=N'stg' AND t.name=N'Clima_Raw' AND c.name=N'Humedad_Pct')
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Porcentaje de humedad tal como fue recibido.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Clima_Raw',
         @level2type=N'COLUMN', @level2name=N'Humedad_Pct';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Porcentaje de humedad tal como fue recibido.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Clima_Raw',
         @level2type=N'COLUMN', @level2name=N'Humedad_Pct';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id=ep.major_id JOIN sys.schemas s ON s.schema_id=t.schema_id
           JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ep.minor_id
           WHERE ep.name=N'MS_Description' AND s.name=N'stg' AND t.name=N'Clima_Raw' AND c.name=N'Fecha_Carga')
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Fecha y hora en que el registro fue cargado a staging.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Clima_Raw',
         @level2type=N'COLUMN', @level2name=N'Fecha_Carga';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Fecha y hora en que el registro fue cargado a staging.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Clima_Raw',
         @level2type=N'COLUMN', @level2name=N'Fecha_Carga';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id=ep.major_id JOIN sys.schemas s ON s.schema_id=t.schema_id
           WHERE ep.name=N'MS_Description' AND s.name=N'stg' AND t.name=N'Entregas_Raw' AND ep.minor_id=0)
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Capa de aterrizaje con información original de entregas recibida del archivo de origen.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Entregas_Raw';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Capa de aterrizaje con información original de entregas recibida del archivo de origen.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Entregas_Raw';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id=ep.major_id JOIN sys.schemas s ON s.schema_id=t.schema_id
           JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ep.minor_id
           WHERE ep.name=N'MS_Description' AND s.name=N'stg' AND t.name=N'Entregas_Raw' AND c.name=N'ID_Carga')
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Identificador secuencial del registro recibido en staging.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Entregas_Raw',
         @level2type=N'COLUMN', @level2name=N'ID_Carga';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Identificador secuencial del registro recibido en staging.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Entregas_Raw',
         @level2type=N'COLUMN', @level2name=N'ID_Carga';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id=ep.major_id JOIN sys.schemas s ON s.schema_id=t.schema_id
           JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ep.minor_id
           WHERE ep.name=N'MS_Description' AND s.name=N'stg' AND t.name=N'Entregas_Raw' AND c.name=N'ID_Envio')
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Identificador de envío tal como fue recibido.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Entregas_Raw',
         @level2type=N'COLUMN', @level2name=N'ID_Envio';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Identificador de envío tal como fue recibido.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Entregas_Raw',
         @level2type=N'COLUMN', @level2name=N'ID_Envio';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id=ep.major_id JOIN sys.schemas s ON s.schema_id=t.schema_id
           JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ep.minor_id
           WHERE ep.name=N'MS_Description' AND s.name=N'stg' AND t.name=N'Entregas_Raw' AND c.name=N'ID_Pedido')
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Identificador del pedido relacionado tal como fue recibido.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Entregas_Raw',
         @level2type=N'COLUMN', @level2name=N'ID_Pedido';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Identificador del pedido relacionado tal como fue recibido.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Entregas_Raw',
         @level2type=N'COLUMN', @level2name=N'ID_Pedido';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id=ep.major_id JOIN sys.schemas s ON s.schema_id=t.schema_id
           JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ep.minor_id
           WHERE ep.name=N'MS_Description' AND s.name=N'stg' AND t.name=N'Entregas_Raw' AND c.name=N'Fecha_Entrega')
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Fecha de entrega en el formato original.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Entregas_Raw',
         @level2type=N'COLUMN', @level2name=N'Fecha_Entrega';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Fecha de entrega en el formato original.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Entregas_Raw',
         @level2type=N'COLUMN', @level2name=N'Fecha_Entrega';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id=ep.major_id JOIN sys.schemas s ON s.schema_id=t.schema_id
           JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ep.minor_id
           WHERE ep.name=N'MS_Description' AND s.name=N'stg' AND t.name=N'Entregas_Raw' AND c.name=N'Minutos_Demora')
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Minutos de demora tal como fueron recibidos.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Entregas_Raw',
         @level2type=N'COLUMN', @level2name=N'Minutos_Demora';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Minutos de demora tal como fueron recibidos.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Entregas_Raw',
         @level2type=N'COLUMN', @level2name=N'Minutos_Demora';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id=ep.major_id JOIN sys.schemas s ON s.schema_id=t.schema_id
           JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ep.minor_id
           WHERE ep.name=N'MS_Description' AND s.name=N'stg' AND t.name=N'Entregas_Raw' AND c.name=N'Calificacion_Cliente')
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Calificación del cliente tal como fue recibida.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Entregas_Raw',
         @level2type=N'COLUMN', @level2name=N'Calificacion_Cliente';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Calificación del cliente tal como fue recibida.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Entregas_Raw',
         @level2type=N'COLUMN', @level2name=N'Calificacion_Cliente';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id=ep.major_id JOIN sys.schemas s ON s.schema_id=t.schema_id
           JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ep.minor_id
           WHERE ep.name=N'MS_Description' AND s.name=N'stg' AND t.name=N'Entregas_Raw' AND c.name=N'Fecha_Carga')
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Fecha y hora en que el registro fue cargado a staging.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Entregas_Raw',
         @level2type=N'COLUMN', @level2name=N'Fecha_Carga';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Fecha y hora en que el registro fue cargado a staging.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Entregas_Raw',
         @level2type=N'COLUMN', @level2name=N'Fecha_Carga';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id=ep.major_id JOIN sys.schemas s ON s.schema_id=t.schema_id
           WHERE ep.name=N'MS_Description' AND s.name=N'stg' AND t.name=N'Registros_Rechazados' AND ep.minor_id=0)
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Bitácora de registros descartados durante la integración por incumplir reglas de calidad o integridad.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Registros_Rechazados';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Bitácora de registros descartados durante la integración por incumplir reglas de calidad o integridad.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Registros_Rechazados';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id=ep.major_id JOIN sys.schemas s ON s.schema_id=t.schema_id
           JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ep.minor_id
           WHERE ep.name=N'MS_Description' AND s.name=N'stg' AND t.name=N'Registros_Rechazados' AND c.name=N'ID_Rechazo')
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Identificador único del registro rechazado.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Registros_Rechazados',
         @level2type=N'COLUMN', @level2name=N'ID_Rechazo';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Identificador único del registro rechazado.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Registros_Rechazados',
         @level2type=N'COLUMN', @level2name=N'ID_Rechazo';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id=ep.major_id JOIN sys.schemas s ON s.schema_id=t.schema_id
           JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ep.minor_id
           WHERE ep.name=N'MS_Description' AND s.name=N'stg' AND t.name=N'Registros_Rechazados' AND c.name=N'Origen')
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Sistema o archivo de donde proviene el registro rechazado.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Registros_Rechazados',
         @level2type=N'COLUMN', @level2name=N'Origen';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Sistema o archivo de donde proviene el registro rechazado.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Registros_Rechazados',
         @level2type=N'COLUMN', @level2name=N'Origen';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id=ep.major_id JOIN sys.schemas s ON s.schema_id=t.schema_id
           JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ep.minor_id
           WHERE ep.name=N'MS_Description' AND s.name=N'stg' AND t.name=N'Registros_Rechazados' AND c.name=N'Llave_Registro')
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Identificador del registro rechazado en el sistema de origen.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Registros_Rechazados',
         @level2type=N'COLUMN', @level2name=N'Llave_Registro';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Identificador del registro rechazado en el sistema de origen.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Registros_Rechazados',
         @level2type=N'COLUMN', @level2name=N'Llave_Registro';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id=ep.major_id JOIN sys.schemas s ON s.schema_id=t.schema_id
           JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ep.minor_id
           WHERE ep.name=N'MS_Description' AND s.name=N'stg' AND t.name=N'Registros_Rechazados' AND c.name=N'Motivo')
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Descripción de la regla o motivo por el que el registro fue rechazado.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Registros_Rechazados',
         @level2type=N'COLUMN', @level2name=N'Motivo';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Descripción de la regla o motivo por el que el registro fue rechazado.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Registros_Rechazados',
         @level2type=N'COLUMN', @level2name=N'Motivo';

IF EXISTS (SELECT 1 FROM sys.extended_properties ep
           JOIN sys.tables t ON t.object_id=ep.major_id JOIN sys.schemas s ON s.schema_id=t.schema_id
           JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ep.minor_id
           WHERE ep.name=N'MS_Description' AND s.name=N'stg' AND t.name=N'Registros_Rechazados' AND c.name=N'Fecha_Rechazo')
    EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'Fecha y hora en que se registró el rechazo.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Registros_Rechazados',
         @level2type=N'COLUMN', @level2name=N'Fecha_Rechazo';
ELSE
    EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Fecha y hora en que se registró el rechazo.',
         @level0type=N'SCHEMA', @level0name=N'stg', @level1type=N'TABLE', @level1name=N'Registros_Rechazados',
         @level2type=N'COLUMN', @level2name=N'Fecha_Rechazo';

GO

/* 3. Consulta del diccionario: cambiar @Esquema y @NombreTabla para cada tabla.
   Ejecutar una vez por tabla y guardar captura de Results Grid en SSMS. */
DECLARE @Esquema SYSNAME = N'dbo';
DECLARE @NombreTabla SYSNAME = N'Cliente';

SELECT
    s.name AS esquema,
    t.name AS tabla,
    c.column_id AS orden_columna,
    c.name AS columna,
    ty.name AS tipo_dato,
    CASE
      WHEN ty.name IN (N'nvarchar', N'nchar') AND c.max_length > 0 THEN c.max_length / 2
      WHEN c.max_length = -1 THEN -1
      ELSE c.max_length
    END AS longitud_maxima,
    c.precision AS precision_dato,
    c.scale AS escala,
    CASE WHEN c.is_nullable = 1 THEN N'Sí' ELSE N'No' END AS permite_nulos,
    CASE WHEN pk.column_id IS NOT NULL THEN N'Sí' ELSE N'No' END AS es_llave_primaria,
    COALESCE(CONVERT(NVARCHAR(4000), ep.value), N'Sin documentación') AS descripcion_negocio
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
JOIN sys.columns AS c ON c.object_id = t.object_id
JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
LEFT JOIN sys.extended_properties AS ep
  ON ep.major_id = t.object_id AND ep.minor_id = c.column_id AND ep.name = N'MS_Description'
LEFT JOIN (
    SELECT ic.object_id, ic.column_id
    FROM sys.indexes i
    JOIN sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
    WHERE i.is_primary_key = 1
) AS pk ON pk.object_id = c.object_id AND pk.column_id = c.column_id
WHERE s.name = @Esquema AND t.name = @NombreTabla
ORDER BY c.column_id;
GO

/* 4. Pruebas de extracción: ejecutar para cada tabla del proyecto.
   Las llamadas se dejan como bloques independientes para obtener una cuadrícula por entidad. */
DECLARE @Esquema SYSNAME, @NombreTabla SYSNAME;
DECLARE diccionario CURSOR LOCAL FAST_FORWARD FOR
SELECT v.esquema, v.tabla
FROM (VALUES
 (N'dbo',N'Ciudad'), (N'dbo',N'Sucursal'), (N'dbo',N'Categoria_Producto'),
 (N'dbo',N'Cliente'), (N'dbo',N'Pedido'), (N'dbo',N'Clima_Diario'), (N'dbo',N'Entrega'),
 (N'stg',N'Clientes_Raw'), (N'stg',N'Ventas_Raw'), (N'stg',N'Clima_JSON_Raw'),
 (N'stg',N'Clima_Raw'), (N'stg',N'Entregas_Raw'), (N'stg',N'Registros_Rechazados')
) AS v(esquema,tabla);
OPEN diccionario;
FETCH NEXT FROM diccionario INTO @Esquema, @NombreTabla;
WHILE @@FETCH_STATUS = 0
BEGIN
    SELECT @Esquema AS esquema_consultado, @NombreTabla AS tabla_consultada;
    SELECT s.name AS esquema, t.name AS tabla, c.name AS columna, ty.name AS tipo_dato,
           c.max_length AS longitud_bytes,
           CASE WHEN c.is_nullable=1 THEN N'Sí' ELSE N'No' END AS permite_nulos,
           COALESCE(CONVERT(NVARCHAR(4000),ep.value),N'Sin documentación') AS descripcion_negocio
    FROM sys.tables t
    JOIN sys.schemas s ON s.schema_id=t.schema_id
    JOIN sys.columns c ON c.object_id=t.object_id
    JOIN sys.types ty ON ty.user_type_id=c.user_type_id
    LEFT JOIN sys.extended_properties ep
      ON ep.major_id=t.object_id AND ep.minor_id=c.column_id AND ep.name=N'MS_Description'
    WHERE s.name=@Esquema AND t.name=@NombreTabla
    ORDER BY c.column_id;
    FETCH NEXT FROM diccionario INTO @Esquema, @NombreTabla;
END
CLOSE diccionario;
DEALLOCATE diccionario;
GO
