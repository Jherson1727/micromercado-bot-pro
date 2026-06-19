require('dotenv').config();
const express = require('express');
const mysql = require('mysql2');
const cors = require('cors');
const app = express();

// Middlewares
app.use(cors());
app.use(express.json());

// Conexión a la base de datos
const db = mysql.createPool({
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'caja_chica_pro',
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0
}).promise();

db.getConnection()
    .then((connection) => {
        console.log('✅ CONEXIÓN EXITOSA: Base de datos CajaChica Pro lista y escuchando.');
        connection.release();
    })
    .catch((err) => console.error('❌ ERROR CRÍTICO:', err.message));

// =====================================================================
// ENDPOINTS DE LA API (ARQUITECTURA ULTRA SEGURA)
// =====================================================================

// 1. Buscar productos (Devuelve un objeto simple)
app.get('/api/productos', async (req, res) => {
    const { buscar } = req.query;
    try {
        let query = 'SELECT id_producto AS id, nombre, precio_venta, stock_actual FROM producto WHERE estado = 1';
        let params = [];
        if (buscar) {
            query += ' AND nombre LIKE ? LIMIT 1';
            params.push(`%${buscar}%`);
        }
        const [results] = await db.query(query, params);
        res.json(results.length > 0 ? results[0] : {});
    } catch (err) {
        res.status(500).json({ error: 'Error al obtener los productos' });
    }
});

// 2. Registrar Venta (🚀 AHORA DESCUENTA STOCK Y VALIDA INVENTARIO)
app.post('/api/ventas', async (req, res) => {
    
    console.log("📦 DATOS DESDE DIFY:", req.body);
    const { id_producto, cantidad } = req.body;
    
    const connection = await db.getConnection();
    try {
        await connection.beginTransaction();

        let id_prod = parseInt(id_producto, 10);
        let cant = parseFloat(cantidad) || 1;

        if (isNaN(id_prod)) {
            throw new Error("Dify no envió un ID de producto válido.");
        }

        // 🔍 Buscamos el precio y el stock actual
        const [prodData] = await connection.query('SELECT precio_venta, stock_actual FROM producto WHERE id_producto = ? AND estado = 1', [id_prod]);

        if (prodData.length === 0) {
            throw new Error("El producto no existe o está inactivo.");
        }

        // 🛡️ Validación de Stock
        let stockDisponible = parseFloat(prodData[0].stock_actual);
        if (stockDisponible < cant) {
            throw new Error(`Stock insuficiente. Solo quedan ${stockDisponible} unidades disponibles.`);
        }

        let prec = parseFloat(prodData[0].precio_venta);
        let subtotal = cant * prec;

        // 1. Inserción de la cabecera (Recibo)
        const [ventaResult] = await connection.query(
            'INSERT INTO venta (id_usuario, id_arqueo, id_cliente, total, tipo_pago) VALUES (1, 1, NULL, ?, "qr")',
            [subtotal]
        );
        const idVenta = ventaResult.insertId;

        // 2. Inserción del detalle (Ítems comprados)
        await connection.query(
            'INSERT INTO detalle_venta (id_venta, id_producto, cantidad, precio_unitario, subtotal) VALUES (?, ?, ?, ?, ?)',
            [idVenta, id_prod, cant, prec, subtotal]
        );

        // 📉 3. TRUCO MAESTRO: Descontar el stock del producto
        await connection.query(
            'UPDATE producto SET stock_actual = stock_actual - ? WHERE id_producto = ?',
            [cant, id_prod]
        );

        await connection.commit();
        res.json({ success: true, id_venta: idVenta, message: 'Venta procesada y stock descontado con éxito' });
    } catch (err) {
        await connection.rollback();
        console.error('❌ Error en venta:', err.message);
        res.status(500).json({ error: 'Error al registrar la venta', detalle: err.message });
    } finally {
        connection.release();
    }
});

// 3. Historial de movimientos
app.get('/api/movimientos/ventas', async (req, res) => {
    const query = `SELECT v.id_venta, v.fecha, v.total, v.tipo_pago, c.nombre AS cliente_nombre, u.nombre AS usuario_nombre FROM venta v LEFT JOIN cliente c ON v.id_cliente = c.id_cliente LEFT JOIN usuario u ON v.id_usuario = u.id_usuario ORDER BY v.fecha DESC`;
    try { const [results] = await db.query(query); res.json(results); } catch (err) { res.status(500).json({ error: 'Error' }); }
});

// 4. Categorías
app.get('/api/categorias', async (req, res) => {
    try { const [results] = await db.query('SELECT * FROM categoria_producto'); res.json(results); } catch (err) { res.status(500).json({ error: 'Error' }); }
});

// 5. Proveedores
app.get('/api/proveedores', async (req, res) => {
    try { const [results] = await db.query('SELECT * FROM proveedor'); res.json(results); } catch (err) { res.status(500).json({ error: 'Error' }); }
});

// Middleware 404
app.use((req, res) => { res.status(404).json({ error: 'Ruta no encontrada' }); });

const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => { console.log(`🚀 API CajaChica Pro corriendo en puerto ${PORT}`); });