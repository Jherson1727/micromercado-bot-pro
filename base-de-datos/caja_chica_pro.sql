DROP DATABASE IF EXISTS caja_chica_pro;
CREATE DATABASE caja_chica_pro CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci;
USE caja_chica_pro;

-- 1. USUARIOS
CREATE TABLE usuario (
    id_usuario INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    usuario VARCHAR(50) NOT NULL UNIQUE,
    contrasena VARCHAR(255) NOT NULL,
    rol ENUM('admin', 'cajero') NOT NULL DEFAULT 'cajero',
    estado TINYINT(1) DEFAULT 1
) ENGINE=InnoDB;

-- 2. CATEGORÍAS
CREATE TABLE categoria_producto (
    id_categoria INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    descripcion VARCHAR(200)
) ENGINE=InnoDB;

CREATE TABLE categoria_gasto (
    id_categoria_gasto INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    descripcion VARCHAR(200)
) ENGINE=InnoDB;

-- 3. PROVEEDORES
CREATE TABLE proveedor (
    id_proveedor INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    id_categoria INT,
    contacto VARCHAR(50),
    telefono VARCHAR(50),
    email VARCHAR(100),
    direccion VARCHAR(200),
    CONSTRAINT fk_prov_cat_rel FOREIGN KEY (id_categoria) REFERENCES categoria_producto(id_categoria)
) ENGINE=InnoDB;

-- 4. INVENTARIO (PRODUCTOS MEJORADOS)
CREATE TABLE producto (
    id_producto INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    codigo_barras VARCHAR(50) UNIQUE,
    precio_compra DECIMAL(10,2) NOT NULL DEFAULT 0.00 CHECK (precio_compra >= 0),
    precio_venta DECIMAL(10,2) NOT NULL DEFAULT 0.00 CHECK (precio_venta >= 0),
    stock_actual INT NOT NULL DEFAULT 0 CHECK (stock_actual >= 0),
    stock_minimo INT NOT NULL DEFAULT 5 CHECK (stock_minimo >= 0),
    fecha_vencimiento DATE NULL, -- NUEVO: Control de perecederos
    id_categoria INT,
    id_proveedor INT,
    estado TINYINT(1) DEFAULT 1,
    CONSTRAINT fk_prod_cat FOREIGN KEY (id_categoria) REFERENCES categoria_producto(id_categoria),
    CONSTRAINT fk_prod_prov FOREIGN KEY (id_proveedor) REFERENCES proveedor(id_proveedor)
) ENGINE=InnoDB;

-- 5. CAJA CHICA Y GASTOS
CREATE TABLE arqueo_caja (
    id_arqueo INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT NOT NULL,
    fecha_apertura DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_cierre DATETIME NULL,
    monto_inicial DECIMAL(10,2) NOT NULL CHECK (monto_inicial >= 0),
    monto_final_sistema DECIMAL(10,2) NULL CHECK (monto_final_sistema >= 0),
    monto_final_fisico DECIMAL(10,2) NULL CHECK (monto_final_fisico >= 0),
    diferencia DECIMAL(10,2) NULL,
    estado ENUM('abierta', 'cerrada') NOT NULL DEFAULT 'abierta',
    CONSTRAINT fk_arqueo_usu FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario)
) ENGINE=InnoDB;

CREATE TABLE gasto (
    id_gasto INT AUTO_INCREMENT PRIMARY KEY,
    id_arqueo INT NOT NULL,
    id_usuario INT NOT NULL,
    id_categoria_gasto INT NOT NULL,
    descripcion VARCHAR(200) NOT NULL,
    monto DECIMAL(10,2) NOT NULL CHECK (monto > 0),
    fecha DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_gasto_arq FOREIGN KEY (id_arqueo) REFERENCES arqueo_caja(id_arqueo),
    CONSTRAINT fk_gasto_usu FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario),
    CONSTRAINT fk_gasto_cat FOREIGN KEY (id_categoria_gasto) REFERENCES categoria_gasto(id_categoria_gasto)
) ENGINE=InnoDB;

-- 6. COMPRAS (INGRESOS DE MERCADERÍA)
CREATE TABLE compra (
    id_compra INT AUTO_INCREMENT PRIMARY KEY,
    id_proveedor INT NOT NULL,
    id_usuario INT NOT NULL,
    total DECIMAL(10,2) NOT NULL CHECK (total >= 0),
    fecha DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_comp_prov FOREIGN KEY (id_proveedor) REFERENCES proveedor(id_proveedor),
    CONSTRAINT fk_comp_usu FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario)
) ENGINE=InnoDB;

CREATE TABLE detalle_compra (
    id_detalle INT AUTO_INCREMENT PRIMARY KEY,
    id_compra INT NOT NULL,
    id_producto INT NOT NULL,
    cantidad INT NOT NULL CHECK (cantidad > 0),
    precio_unitario DECIMAL(10,2) NOT NULL CHECK (precio_unitario >= 0),
    subtotal DECIMAL(10,2) NOT NULL CHECK (subtotal >= 0),
    CONSTRAINT fk_detcomp_comp FOREIGN KEY (id_compra) REFERENCES compra(id_compra),
    CONSTRAINT fk_detcomp_prod FOREIGN KEY (id_producto) REFERENCES producto(id_producto)
) ENGINE=InnoDB;

-- 7. CLIENTES Y CUENTAS POR COBRAR (FIADO)
CREATE TABLE cliente (
    id_cliente INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    telefono VARCHAR(50),
    deuda_pendiente DECIMAL(10,2) DEFAULT 0.00 CHECK (deuda_pendiente >= 0)
) ENGINE=InnoDB;

CREATE TABLE abono_cliente (
    id_abono INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente INT NOT NULL,
    id_usuario INT NOT NULL,
    id_arqueo INT NOT NULL,
    monto DECIMAL(10,2) NOT NULL CHECK (monto > 0),
    fecha DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_abono_cli FOREIGN KEY (id_cliente) REFERENCES cliente(id_cliente),
    CONSTRAINT fk_abono_usu FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario),
    CONSTRAINT fk_abono_arq FOREIGN KEY (id_arqueo) REFERENCES arqueo_caja(id_arqueo)
) ENGINE=InnoDB;

-- 8. VENTAS AL PÚBLICO
CREATE TABLE venta (
    id_venta INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT NOT NULL,
    id_arqueo INT NOT NULL,
    id_cliente INT NULL,
    total DECIMAL(10,2) NOT NULL CHECK (total >= 0),
    descuento DECIMAL(10,2) DEFAULT 0.00 CHECK (descuento >= 0), -- NUEVO: Soporte para rebajas
    tipo_pago ENUM('efectivo', 'qr', 'tarjeta', 'fiado') NOT NULL DEFAULT 'efectivo',
    fecha DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_venta_usu FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario),
    CONSTRAINT fk_venta_arq FOREIGN KEY (id_arqueo) REFERENCES arqueo_caja(id_arqueo),
    CONSTRAINT fk_venta_cli FOREIGN KEY (id_cliente) REFERENCES cliente(id_cliente)
) ENGINE=InnoDB;

CREATE TABLE detalle_venta (
    id_detalle INT AUTO_INCREMENT PRIMARY KEY,
    id_venta INT NOT NULL,
    id_producto INT NOT NULL,
    cantidad INT NOT NULL CHECK (cantidad > 0),
    precio_unitario DECIMAL(10,2) NOT NULL CHECK (precio_unitario >= 0),
    descuento DECIMAL(10,2) DEFAULT 0.00 CHECK (descuento >= 0),
    subtotal DECIMAL(10,2) NOT NULL, -- Corrección para Docker
    CONSTRAINT fk_detven_ven FOREIGN KEY (id_venta) REFERENCES venta(id_venta),
    CONSTRAINT fk_detven_prod FOREIGN KEY (id_producto) REFERENCES producto(id_producto)
) ENGINE=InnoDB;

-- 9. KARDEX (HISTORIAL DE MOVIMIENTOS)
CREATE TABLE historial_stock (
    id_historial INT AUTO_INCREMENT PRIMARY KEY,
    id_producto INT NOT NULL,
    tipo_movimiento ENUM('entrada_compra', 'salida_venta', 'ajuste', 'devolucion') NOT NULL,
    cantidad INT NOT NULL,
    fecha DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    referencia VARCHAR(100),
    CONSTRAINT fk_hist_prod FOREIGN KEY (id_producto) REFERENCES producto(id_producto)
) ENGINE=InnoDB;

-- 10. VISTAS
CREATE VIEW vw_resumen_dia AS
SELECT 
    CURDATE() as fecha,
    (SELECT IFNULL(SUM(total), 0) FROM venta WHERE DATE(fecha) = CURDATE() AND tipo_pago != 'fiado') as ingresos_ventas,
    (SELECT IFNULL(SUM(total), 0) FROM compra WHERE DATE(fecha) = CURDATE()) as total_compras,
    (SELECT IFNULL(SUM(monto), 0) FROM gasto WHERE DATE(fecha) = CURDATE()) as total_gastos,
    (SELECT IFNULL(SUM(monto), 0) FROM abono_cliente WHERE DATE(fecha) = CURDATE()) as total_abonos;

-- 11. TRIGGERS AUTOMÁTICOS
DELIMITER //

-- Trigger: Descontar stock al vender y registrar en Kardex
CREATE TRIGGER tr_actualizar_stock_venta
AFTER INSERT ON detalle_venta
FOR EACH ROW
BEGIN
    UPDATE producto 
    SET stock_actual = stock_actual - NEW.cantidad
    WHERE id_producto = NEW.id_producto;
    
    INSERT INTO historial_stock (id_producto, tipo_movimiento, cantidad, referencia)
    VALUES (NEW.id_producto, 'salida_venta', NEW.cantidad, CONCAT('Venta #', NEW.id_venta));
END //

-- NUEVO Trigger: Aumentar stock al comprar y registrar en Kardex
CREATE TRIGGER tr_actualizar_stock_compra
AFTER INSERT ON detalle_compra
FOR EACH ROW
BEGIN
    UPDATE producto 
    SET stock_actual = stock_actual + NEW.cantidad
    WHERE id_producto = NEW.id_producto;
    
    INSERT INTO historial_stock (id_producto, tipo_movimiento, cantidad, referencia)
    VALUES (NEW.id_producto, 'entrada_compra', NEW.cantidad, CONCAT('Compra #', NEW.id_compra));
END //

-- Trigger: Actualizar deuda al registrar abono
CREATE TRIGGER tr_procesar_abono
AFTER INSERT ON abono_cliente
FOR EACH ROW
BEGIN
    UPDATE cliente 
    SET deuda_pendiente = deuda_pendiente - NEW.monto
    WHERE id_cliente = NEW.id_cliente;
END //

-- Trigger: Aumentar deuda si la venta es fiado
CREATE TRIGGER tr_venta_fiado_deuda
AFTER INSERT ON venta
FOR EACH ROW
BEGIN
    IF NEW.tipo_pago = 'fiado' AND NEW.id_cliente IS NOT NULL THEN
        UPDATE cliente
        SET deuda_pendiente = deuda_pendiente + NEW.total
        WHERE id_cliente = NEW.id_cliente;
    END IF;
END //

DELIMITER ;

-- 12. DATOS POR DEFECTO PARA INICIAR EL SISTEMA
INSERT INTO usuario (nombre, usuario, contrasena, rol) VALUES ('Administrador General', 'admin', 'admin123', 'admin');
INSERT INTO arqueo_caja (id_usuario, monto_inicial) VALUES (1, 0.00);

-- =====================================================================
-- 13. CATÁLOGO INICIAL DEL MICROMERCADO (CATEGORÍAS Y PRODUCTOS)
-- =====================================================================

-- Insertar Categorías del Micromercado
INSERT INTO categoria_producto (nombre, descripcion) VALUES 
('Lácteos y Fiambres', 'Leches, yogures, quesos, mantequillas y embutidos'),
('Panadería', 'Pan fresco, molde, queques y masas'),
('Abarrotes y Despensa', 'Arroz, fideos, aceite, azúcar, sal y condimentos'),
('Snacks y Galletas', 'Papas fritas, pipocas, galletas dulces y saladas'),
('Golosinas', 'Chicles, caramelos, chocolates y dulces'),
('Bebidas', 'Gaseosas, jugos, aguas, maltas y energizantes'),
('Limpieza del Hogar', 'Detergentes, lavavajillas, lavandina y desinfectantes'),
('Aseo Personal', 'Papel higiénico, jaboncillos, shampoo y pasta dental');

-- Insertar Productos (Inventario Inicial con precios en BOB)
INSERT INTO producto (nombre, codigo_barras, precio_compra, precio_venta, stock_actual, stock_minimo, id_categoria, fecha_vencimiento) VALUES 
-- 1. Lácteos y Fiambres
('Leche Entera PIL 1L', '77701', 5.50, 6.50, 40, 10, 1, '2026-07-15'),
('Yogurt Frutilla PIL 1L', '77702', 11.00, 13.00, 20, 5, 1, '2026-08-01'),
('Mantequilla PIL 200g', '77703', 8.50, 10.00, 15, 5, 1, '2026-09-10'),
('Queso Río Grande 1kg', '77704', 22.00, 26.00, 10, 3, 1, '2026-07-20'),
('Salchicha Sofía a granel 1kg', '77705', 18.00, 22.00, 12, 4, 1, '2026-07-10'),

-- 2. Panadería
('Pan Batido (Unidad)', 'PAN01', 0.40, 0.50, 150, 30, 2, '2026-06-15'),
('Pan de Molde Integral San Gabriel', '77706', 10.00, 12.00, 15, 4, 2, '2026-06-25'),
('Queque de Vainilla Casero', 'PAN02', 4.00, 5.00, 20, 5, 2, '2026-06-18'),

-- 3. Abarrotes y Despensa
('Arroz Grano de Oro 1kg', '77707', 8.50, 10.00, 50, 15, 3, '2027-01-01'),
('Fideo Lazzaroni Corbata 400g', '77708', 4.50, 6.00, 40, 10, 3, '2027-05-10'),
('Aceite Fino 1L', '77709', 12.00, 14.50, 30, 10, 3, '2027-02-20'),
('Azúcar Guabirá 1kg', '77710', 5.50, 7.00, 60, 20, 3, '2028-01-01'),
('Sal Yodada Universo 1kg', '77711', 1.20, 2.00, 30, 10, 3, NULL),
('Huevo (Maple de 30 un)', '77712', 20.00, 24.00, 15, 5, 3, '2026-07-10'),

-- 4. Snacks y Galletas
('Galletas Mabel Cremositas', '77713', 1.80, 2.50, 50, 15, 4, '2026-12-01'),
('Galletas de Agua Salvado', '77714', 2.20, 3.00, 35, 10, 4, '2026-11-15'),
('Papas Fritas Lays Clásicas', '77715', 5.00, 6.50, 25, 8, 4, '2026-10-20'),
('Pipocas Karicia', '77716', 1.50, 2.50, 40, 10, 4, '2026-09-30'),

-- 5. Golosinas
('Chicles Trident Menta', '77717', 1.00, 1.50, 100, 20, 5, '2027-06-01'),
('Chocolate Sublime', '77718', 2.50, 3.50, 45, 15, 5, '2026-12-10'),
('Gomitas Mogul', '77719', 3.00, 4.00, 30, 10, 5, '2026-11-20'),

-- 6. Bebidas
('Coca Cola Retornable 2L', '77720', 8.50, 10.00, 40, 15, 6, '2026-12-31'),
('Coca Cola Desechable 3L', '77721', 13.00, 15.00, 30, 10, 6, '2026-12-31'),
('Agua Vital sin Gas 2L', '77722', 5.00, 7.00, 0, 15, 6, '2027-06-01'),
('Jugo del Valle Durazno 1L', '77723', 6.00, 8.00, 25, 8, 6, '2026-10-15'),

-- 7. Limpieza del Hogar
('Detergente Omo Multiacción 800g', '77724', 11.00, 13.00, 20, 5, 7, NULL),
('Lavavajillas Ola en pasta', '77725', 6.50, 8.00, 25, 8, 7, NULL),
('Lavandina Daryza 1L', '77726', 4.00, 5.50, 30, 10, 7, NULL),

-- 8. Aseo Personal
('Papel Higiénico Nacional (Paq 4)', '77727', 12.00, 15.00, 35, 10, 8, NULL),
('Jaboncillo Rexona Blanco', '77728', 4.50, 6.00, 40, 12, 8, NULL),
('Pasta Dental Colgate Triple Acción', '77729', 8.50, 11.00, 20, 6, 8, '2028-05-01');