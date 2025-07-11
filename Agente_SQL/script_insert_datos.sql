-- ============================================
-- Script completo de inserción:
--  • 10 clientes
--  • 100 productos con nombres mejorados
--  • 20 pedidos de esos clientes
--  • Líneas de pedido (1–4 ítems) para cada pedido
-- ============================================

BEGIN;

-- 1. Inserción de 10 clientes (si aún no existen)
INSERT INTO clientes (nombre, email, direccion, fecha_alta)
SELECT
  nombre,
  lower(regexp_replace(nombre, '\s+', '.', 'g')) || '@ejemplo.com' AS email,
  'Dirección ' || row_num || ', Ciudad, País'               AS direccion,
  NOW() - ((random() * 30)::int || ' days')::interval       AS fecha_alta
FROM (
  SELECT
    unnest(ARRAY[
      'Antonio Lopez','Josema Fernandez','Claudia Giraldez',
      'Raul Lopez','Pepe Garcia','Maria Morillo',
      'Carmen Fernandez','Marisa Castelló',
      'Gustavo López','Daniel Garcia'
    ]) AS nombre,
    generate_series(1,10) AS row_num
) AS t
ON CONFLICT (email) DO NOTHING;  -- evita duplicados si ya existen clientes

-- 2. Inserción de 100 productos con nombres naturales y descripciones realistas
INSERT INTO productos (
    nombre, descripcion, sku,
    precio_unit, stock, activo,
    imagen_url, atributos
)
SELECT
  INITCAP(s.articulo) || ' ' || s.estilo || ' de ' || s.material || ' ' || s.color AS nombre,
  'El ' || s.articulo || ' ' || s.color || ' en estilo ' || s.estilo ||
    ' está confeccionado en ' || s.material || ' de alta calidad. ' ||
    'Perfecto para tus looks más ' ||
    CASE WHEN s.estilo IN ('elegante','minimalista') THEN 'sofisticados.' ELSE 'casuales.' END
    AS descripcion,
  'SKU' || lpad(s.gs::text, 6, '0')                            AS sku,
  round((random() * 90 + 10)::numeric, 2)                      AS precio_unit,
  (random() * 200)::int                                        AS stock,
  (random() < 0.9)                                             AS activo,
  'https://cdn.ejemplo.com/images/' || s.gs || '.jpg'          AS imagen_url,
  jsonb_build_object(
    'color', (ARRAY['rojo','azul','verde','negro','blanco'])[(floor(random()*5+1))::int],
    'talla', (ARRAY['S','M','L','XL','XXL'])[(floor(random()*5+1))::int]
  )                                                            AS atributos
FROM (
  SELECT
    gs,
    (ARRAY['algodón','lino','cuero','denim','seda','lana','poliéster'])[((gs-1)%7)+1]         AS material,
    (ARRAY['slim fit','oversize','cropped','vintage','retro','minimalista','bohemio','sport','casual','elegante'])[((gs-1)%10)+1] AS estilo,
    (ARRAY['camiseta','pantalón','chaqueta','vestido','falda','zapatillas','calcetines','sudadera','jersey','blusa','camisa','abrigo','jeans','shorts','cardigan','bomber','parka'])[((gs-1)%17)+1] AS articulo,
    (ARRAY['blanco','negro','azul marino','gris','rojo','verde oliva','beige','rosa','mostaza','marrón'])[((gs-1)%10)+1]         AS color
  FROM generate_series(1,100) AS gs
) AS s
ON CONFLICT (sku) DO NOTHING;  -- evita duplicar si ya existen

-- 3. Inserción de 20 pedidos de clientes existentes
INSERT INTO pedidos (
    cliente_id,
    fecha_pedido,
    estado,
    total
)
SELECT
  c.cliente_id,
  NOW() - ((random() * 30)::int || ' days')::interval       AS fecha_pedido,
  (ARRAY['pendiente','procesando','enviado','cancelado'])[(floor(random()*4+1))::int] AS estado,
  0.00                                                       AS total
FROM (
  SELECT cliente_id FROM clientes ORDER BY random() LIMIT 20
) AS c;

-- 4. Inserción de líneas en pedido_items para esos 20 pedidos
WITH last20 AS (
  SELECT pedido_id
  FROM pedidos
  ORDER BY pedido_id DESC
  LIMIT 20
), detalles AS (
  SELECT
    p.pedido_id,
    prod.producto_id,
    (floor(random()*5 + 1))::int                             AS cantidad,
    prod.precio_unit
  FROM last20 p
  JOIN productos prod ON TRUE
  ORDER BY random()
  LIMIT  -- generar entre 20 * 1 = 20 y 20 * 4 = 80 líneas
    ( (SELECT count(*) FROM last20) * (floor(random()*3 + 1)) )
)
INSERT INTO pedido_items (
  pedido_id, producto_id, cantidad, precio_unit
)
SELECT
  pedido_id,
  producto_id,
  cantidad,
  precio_unit
FROM detalles;

-- 5. Actualizar totales en pedidos sumando sus líneas
UPDATE pedidos p
SET total = sub.sum_total
FROM (
  SELECT
    pedido_id,
    SUM(cantidad * precio_unit)::numeric(10,2) AS sum_total
  FROM pedido_items
  GROUP BY pedido_id
) AS sub
WHERE p.pedido_id = sub.pedido_id;

COMMIT;
