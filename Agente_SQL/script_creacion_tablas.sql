-- ============================================
-- Script de creación de tablas para tienda online
-- ============================================
-- 0
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS vector;
-- 1. Eliminar tablas si ya existen (orden dependencias)
DROP TABLE IF EXISTS pedido_items;
DROP TABLE IF EXISTS pedidos;
DROP TABLE IF EXISTS productos;
DROP TABLE IF EXISTS clientes;

-- 2. Tabla: clientes
CREATE TABLE clientes (
  cliente_id   SERIAL PRIMARY KEY,
  nombre       VARCHAR(100) NOT NULL,
  email        VARCHAR(150) UNIQUE NOT NULL,
  direccion    TEXT,
  fecha_alta   TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- 3. Tabla: productos (con campos extra)
CREATE TABLE productos (
  producto_id     SERIAL PRIMARY KEY,
  nombre          VARCHAR(150) NOT NULL,
  descripcion     TEXT,
  sku             VARCHAR(50) UNIQUE NOT NULL,
  precio_unit     NUMERIC(10,2) NOT NULL CHECK (precio_unit >= 0),
  stock           INT NOT NULL DEFAULT 0 CHECK (stock >= 0),
  activo          BOOLEAN NOT NULL DEFAULT TRUE,
  imagen_url      TEXT,
  atributos       JSONB NOT NULL DEFAULT '{}'::jsonb,
  creado_en       TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  actualizado_en  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Función y trigger para mantener actualizado 'actualizado_en'
CREATE OR REPLACE FUNCTION actualizar_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.actualizado_en := NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_productos_update
BEFORE UPDATE ON productos
FOR EACH ROW
EXECUTE FUNCTION actualizar_timestamp();

-- 4. Tabla: pedidos
CREATE TABLE pedidos (
  pedido_id    SERIAL PRIMARY KEY,
  cliente_id   INT NOT NULL
                REFERENCES clientes(cliente_id)
                ON DELETE RESTRICT,
  fecha_pedido TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  estado       VARCHAR(20) NOT NULL
                CHECK (estado IN ('pendiente','procesando','enviado','cancelado')),
  total        NUMERIC(10,2) NOT NULL DEFAULT 0
);

-- 5. Tabla: pedido_items (relación N–M)
CREATE TABLE pedido_items (
  pedido_id    INT NOT NULL
                REFERENCES pedidos(pedido_id)
                ON DELETE CASCADE,
  producto_id  INT NOT NULL
                REFERENCES productos(producto_id)
                ON DELETE RESTRICT,
  cantidad     INT NOT NULL CHECK (cantidad > 0),
  precio_unit  NUMERIC(10,2) NOT NULL CHECK (precio_unit >= 0),
  PRIMARY KEY (pedido_id, producto_id)
);
