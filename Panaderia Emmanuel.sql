
-- =============================================
-- SISTEMA DE VENTAS Y FACTURACION
-- PANADERIA EMMANUEL
-- BASE DE DATOS COMPLETA
-- =============================================

CREATE DATABASE PanaderiaEmmanuel;
GO

USE PanaderiaEmmanuel;
GO

-- =============================================
-- 1. TABLA DE ROLES
-- =============================================

CREATE TABLE dbo.Roles (
    IdRol INT IDENTITY(1,1) PRIMARY KEY,
    NombreRol VARCHAR(30) NOT NULL UNIQUE,
    Descripcion VARCHAR(150)
);
GO

-- =============================================
-- 2. TABLA DE USUARIOS
-- =============================================

CREATE TABLE dbo.Usuarios (
    IdUsuario INT IDENTITY(1,1) PRIMARY KEY,
    NombreCompleto VARCHAR(100) NOT NULL,
    NombreUsuario VARCHAR(50) NOT NULL UNIQUE,
    ContrasenaHash VARCHAR(255) NOT NULL,
    IdRol INT NOT NULL,
    Estado BIT NOT NULL DEFAULT 1,
    FechaCreacion DATETIME2 NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT FK_Usuarios_Roles
        FOREIGN KEY (IdRol)
        REFERENCES dbo.Roles(IdRol)
);
GO

----------------
--INSERT INTO dbo.Usuarios
--    (NombreCompleto, NombreUsuario, ContrasenaHash, IdRol)
--VALUES
--    (
--        'Administrador',
--        'admin',
--        '$2b$12$zMvggwPN16cnMkvrdpxybO94Dd3cPMCUb/7qatf.mltopWWUQeeD.',
--        (SELECT IdRol
--         FROM dbo.Roles
--         WHERE NombreRol = 'Administrador')
--    );

-- =============================================
-- 3. TABLA DE PRODUCTOS
-- Guarda los datos generales del producto.
-- Las fechas de los lotes se guardan aparte.
-- =============================================

CREATE TABLE dbo.Productos (
    IdProducto INT IDENTITY(1,1) PRIMARY KEY,
    NombreProducto VARCHAR(100) NOT NULL,
    Descripcion VARCHAR(200),
    Precio DECIMAL(10,2) NOT NULL,
    Estado BIT NOT NULL DEFAULT 1,

    CONSTRAINT CK_Productos_Precio
        CHECK (Precio >= 0)
);
GO

-- =============================================
-- 4. TABLA DE INVENTARIO
-- Guarda el total de unidades por producto.
-- =============================================

CREATE TABLE dbo.Inventario (
    IdInventario INT IDENTITY(1,1) PRIMARY KEY,
    IdProducto INT NOT NULL UNIQUE,
    Existencia INT NOT NULL DEFAULT 0,
    StockMinimo INT NOT NULL DEFAULT 5,
    FechaActualizacion DATETIME2 NOT NULL
        DEFAULT SYSDATETIME(),

    CONSTRAINT FK_Inventario_Productos
        FOREIGN KEY (IdProducto)
        REFERENCES dbo.Productos(IdProducto),

    CONSTRAINT CK_Inventario_Existencia
        CHECK (Existencia >= 0),

    CONSTRAINT CK_Inventario_StockMinimo
        CHECK (StockMinimo >= 0)
);
GO

-- =============================================
-- 5. TABLA DE LOTES DE INVENTARIO
-- Cada lote tiene fecha de ingreso y vencimiento.
-- =============================================

CREATE TABLE dbo.LotesInventario (
    IdLote INT IDENTITY(1,1) PRIMARY KEY,
    IdProducto INT NOT NULL,
    CantidadInicial INT NOT NULL,
    CantidadDisponible INT NOT NULL,
    FechaIngreso DATE NOT NULL,
    FechaVencimiento DATE NOT NULL,

    CONSTRAINT FK_LotesInventario_Productos
        FOREIGN KEY (IdProducto)
        REFERENCES dbo.Productos(IdProducto),

    CONSTRAINT CK_Lotes_Cantidades
        CHECK (
            CantidadInicial > 0
            AND CantidadDisponible >= 0
            AND CantidadDisponible <= CantidadInicial
        ),

    CONSTRAINT CK_Lotes_Fechas
        CHECK (FechaVencimiento >= FechaIngreso)
);
GO

CREATE INDEX IX_LotesInventario_IdProducto
ON dbo.LotesInventario(IdProducto);
GO

CREATE INDEX IX_LotesInventario_FechaVencimiento
ON dbo.LotesInventario(FechaVencimiento);
GO

-- =============================================
-- 6. TABLA DE VENTAS
-- =============================================

CREATE TABLE dbo.Ventas (
    IdVenta INT IDENTITY(1,1) PRIMARY KEY,
    IdUsuario INT NOT NULL,
    FechaVenta DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    MetodoPago VARCHAR(30) NOT NULL,
    CanalVenta VARCHAR(30) NOT NULL DEFAULT 'Presencial',
    Total DECIMAL(12,2) NOT NULL DEFAULT 0,
    Estado VARCHAR(20) NOT NULL DEFAULT 'Completada',

    CONSTRAINT FK_Ventas_Usuarios
        FOREIGN KEY (IdUsuario)
        REFERENCES dbo.Usuarios(IdUsuario),

    CONSTRAINT CK_Ventas_Total
        CHECK (Total >= 0),

    CONSTRAINT CK_Ventas_MetodoPago
        CHECK (
            MetodoPago IN (
                'Efectivo',
                'Tarjeta',
                'Transferencia'
            )
        ),

    CONSTRAINT CK_Ventas_Canal
        CHECK (CanalVenta IN ('Presencial', 'Pedido'))
);
GO

-- =============================================
-- 7. DETALLE DE VENTA
-- Identifica el lote del que se descuenta
-- cada producto vendido.
-- =============================================

CREATE TABLE dbo.DetalleVenta (
    IdDetalle INT IDENTITY(1,1) PRIMARY KEY,
    IdVenta INT NOT NULL,
    IdProducto INT NOT NULL,
    IdLote INT NOT NULL,
    Cantidad INT NOT NULL,
    PrecioUnitario DECIMAL(10,2) NOT NULL,

    Subtotal AS (Cantidad * PrecioUnitario) PERSISTED,

    CONSTRAINT FK_DetalleVenta_Ventas
        FOREIGN KEY (IdVenta)
        REFERENCES dbo.Ventas(IdVenta),

    CONSTRAINT FK_DetalleVenta_Productos
        FOREIGN KEY (IdProducto)
        REFERENCES dbo.Productos(IdProducto),

    CONSTRAINT FK_DetalleVenta_Lotes
        FOREIGN KEY (IdLote)
        REFERENCES dbo.LotesInventario(IdLote),

    CONSTRAINT CK_DetalleVenta_Cantidad
        CHECK (Cantidad > 0),

    CONSTRAINT CK_DetalleVenta_Precio
        CHECK (PrecioUnitario >= 0)
);
GO

-- =============================================
-- 8. TABLA DE FACTURAS
-- =============================================

CREATE TABLE dbo.Facturas (
    IdFactura INT IDENTITY(1,1) PRIMARY KEY,
    IdVenta INT NOT NULL UNIQUE,
    NumeroFactura VARCHAR(30) NOT NULL UNIQUE,
    FechaEmision DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    NombreCliente VARCHAR(100),
    IdentificacionCliente VARCHAR(30),

    CONSTRAINT FK_Facturas_Ventas
        FOREIGN KEY (IdVenta)
        REFERENCES dbo.Ventas(IdVenta)
);
GO

-- =============================================
-- 9. REGISTRAR ROLES INICIALES
-- =============================================

INSERT INTO dbo.Roles (NombreRol, Descripcion)
VALUES
('Administrador', 'Gestiona el sistema'),
('Vendedor', 'Registra ventas y consulta productos');
GO

-- =============================================
-- 10. PRODUCTOS DE PRUEBA
-- =============================================

INSERT INTO dbo.Productos (
    NombreProducto,
    Descripcion,
    Precio
)
VALUES
('Pan francés', 'Pan tradicional', 5.00),
('Pan dulce', 'Pan dulce de la casa', 10.00),
('Repostería', 'Producto de repostería', 15.00);
GO

-- =============================================
-- 11. EXISTENCIAS INICIALES
-- =============================================

INSERT INTO dbo.Inventario (
    IdProducto,
    Existencia,
    StockMinimo
)
SELECT
    IdProducto,
    50,
    5
FROM dbo.Productos;
GO

-- =============================================
-- 12. LOTES DE PRUEBA
-- Las fechas son ejemplos.
-- Sustituirlas por las fechas reales.
-- =============================================

INSERT INTO dbo.LotesInventario (
    IdProducto,
    CantidadInicial,
    CantidadDisponible,
    FechaIngreso,
    FechaVencimiento
)
SELECT
    IdProducto,
    50,
    50,
    '2026-10-23',
    CASE NombreProducto
        WHEN 'Pan francés' THEN '2026-10-24'
        WHEN 'Pan dulce' THEN '2026-10-26'
        WHEN 'Repostería' THEN '2026-10-25'
    END
FROM dbo.Productos;
GO

-- =============================================
-- 13. CONSULTA PARA VER PRODUCTOS Y LOTES
-- =============================================

SELECT
    P.IdProducto,
    P.NombreProducto,
    P.Precio,
    I.Existencia,
    I.StockMinimo,
    L.IdLote,
    L.CantidadInicial,
    L.CantidadDisponible,
    L.FechaIngreso,
    L.FechaVencimiento
FROM dbo.Productos AS P
INNER JOIN dbo.Inventario AS I
    ON P.IdProducto = I.IdProducto
INNER JOIN dbo.LotesInventario AS L
    ON P.IdProducto = L.IdProducto;
GO


-- Registrar el usuario administrador si todavía no existe
IF NOT EXISTS (
    SELECT 1
    FROM dbo.Usuarios
    WHERE NombreUsuario = 'admin'
)
BEGIN
    INSERT INTO dbo.Usuarios (
        NombreCompleto,
        NombreUsuario,
        ContrasenaHash,
        IdRol,
        Estado
    )
    SELECT
        'Administrador del sistema',
        'admin',
        'PENDIENTE_CONFIGURAR_HASH',
        IdRol,
        1
    FROM dbo.Roles
    WHERE NombreRol = 'Administrador';
END;
GO

-- Comprobar los usuarios registrados
SELECT
    U.IdUsuario,
    U.NombreCompleto,
    U.NombreUsuario,
    R.NombreRol,
    U.Estado
FROM dbo.Usuarios AS U
INNER JOIN dbo.Roles AS R
    ON U.IdRol = R.IdRol;
GO

SELECT
    u.IdUsuario,
    u.NombreCompleto,
    u.NombreUsuario,
    u.Estado,
    u.IdRol,
    r.NombreRol
FROM dbo.Usuarios u
INNER JOIN dbo.Roles r ON u.IdRol = r.IdRol
WHERE u.NombreUsuario = 'admin';


UPDATE dbo.Usuarios
SET ContrasenaHash = '$2b$12$zKXokDIM/8V8VCO7b3ddgeb5FFGiyuQOgmy2cSN.M0X5tpQ32XUom',
    Estado = 1
WHERE NombreUsuario = 'admin';