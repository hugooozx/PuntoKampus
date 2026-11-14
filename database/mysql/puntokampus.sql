-- PuntoKampus | Modelo relacional del tramo 1 | 14-11-2026
-- Destino: MySQL Community Server 8.4 LTS (no MySQL 5.7 ni MariaDB).
-- Seleccionar y ejecutar TODO el archivo en una conexion MySQL.
-- Requiere permisos CREATE, CREATE VIEW, DROP (reemplazo de vistas),
-- REFERENCES y SELECT sobre puntokampus. No requiere privilegios globales.
-- No incluye registros, contrasenas, usuarios del servidor ni datos de prueba.
-- Repetir este mismo archivo conserva los datos: no hay DROP TABLE ni TRUNCATE.
-- IF NOT EXISTS no actualiza una estructura antigua: los cambios posteriores
-- se aplican mediante migraciones versionadas, no reejecutando otro esquema.
-- El DDL de MySQL confirma cada sentencia; el archivo no es una transaccion.

SET @pk_modo_anterior = @@SESSION.sql_mode;
SET @pk_zona_anterior = @@SESSION.time_zone;
SET SESSION sql_mode = 'STRICT_ALL_TABLES,ONLY_FULL_GROUP_BY,NO_ZERO_DATE,NO_ZERO_IN_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';
SET SESSION time_zone = '+00:00';
SET NAMES utf8mb4 COLLATE utf8mb4_0900_ai_ci;

CREATE DATABASE IF NOT EXISTS puntokampus
    CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE puntokampus;

-- 1. Catalogos academicos: una carrera pertenece a una facultad.
CREATE TABLE IF NOT EXISTS facultades (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    nombre VARCHAR(150) NOT NULL,
    activa BOOLEAN NOT NULL DEFAULT TRUE,
    creado_en DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    actualizado_en DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    CONSTRAINT uq_facultades_nombre UNIQUE (nombre),
    CONSTRAINT ck_facultades_nombre CHECK (CHAR_LENGTH(TRIM(nombre)) > 0),
    CONSTRAINT ck_facultades_activa CHECK (activa IN (0, 1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS carreras (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    facultad_id BIGINT UNSIGNED NOT NULL,
    nombre VARCHAR(150) NOT NULL,
    activa BOOLEAN NOT NULL DEFAULT TRUE,
    creado_en DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    actualizado_en DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    CONSTRAINT uq_carreras_facultad_nombre UNIQUE (facultad_id, nombre),
    CONSTRAINT fk_carreras_facultades FOREIGN KEY (facultad_id) REFERENCES facultades (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT ck_carreras_nombre CHECK (CHAR_LENGTH(TRIM(nombre)) > 0),
    CONSTRAINT ck_carreras_activa CHECK (activa IN (0, 1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS periodos_academicos (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    nombre VARCHAR(80) NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    creado_en DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    actualizado_en DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    CONSTRAINT uq_periodos_academicos_nombre UNIQUE (nombre),
    CONSTRAINT ck_periodos_academicos_nombre CHECK (CHAR_LENGTH(TRIM(nombre)) > 0),
    CONSTRAINT ck_periodos_academicos_fechas CHECK (fecha_fin >= fecha_inicio)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 2. Identidad. No se almacenan contrasenas: el PRD utiliza codigos por correo.
-- Nombres y consentimiento pueden estar ambos vacios SOLO durante el alta.
-- Laravel bloquea las operaciones protegidas hasta completar ambos campos.
CREATE TABLE IF NOT EXISTS usuarios (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    correo VARCHAR(254) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    nombres VARCHAR(150) NULL,
    es_admin BOOLEAN NOT NULL DEFAULT FALSE,
    acepto_privacidad_en DATETIME(6) NULL,
    estado ENUM('activa', 'desactivada') NOT NULL DEFAULT 'activa',
    creado_en DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    actualizado_en DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    CONSTRAINT uq_usuarios_correo UNIQUE (correo),
    CONSTRAINT ck_usuarios_correo CHECK (
        REGEXP_LIKE(correo, '^[a-z0-9.!#$%&''*+/=?^_`{|}~-]+@([a-z0-9]([a-z0-9-]*[a-z0-9])?[.])*utb[.]edu[.]ec$', 'c')
    ),
    CONSTRAINT ck_usuarios_alta CHECK (
        (nombres IS NULL AND acepto_privacidad_en IS NULL)
        OR (nombres IS NOT NULL AND CHAR_LENGTH(TRIM(nombres)) > 0 AND acepto_privacidad_en IS NOT NULL)
    ),
    CONSTRAINT ck_usuarios_admin CHECK (es_admin IN (0, 1)),
    CONSTRAINT ck_usuarios_estado CHECK (estado <> '')
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS perfiles_vendedores (
    usuario_id BIGINT UNSIGNED NOT NULL,
    carrera_id BIGINT UNSIGNED NOT NULL,
    codigo_estudiante VARCHAR(40) NOT NULL,
    semestre TINYINT UNSIGNED NOT NULL,
    whatsapp VARCHAR(15) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    mostrar_whatsapp BOOLEAN NOT NULL DEFAULT FALSE,
    creado_en DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    actualizado_en DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (usuario_id),
    KEY ix_perfiles_vendedores_carrera (carrera_id),
    CONSTRAINT fk_perfiles_vendedores_usuarios FOREIGN KEY (usuario_id) REFERENCES usuarios (id) ON DELETE CASCADE ON UPDATE RESTRICT,
    CONSTRAINT fk_perfiles_vendedores_carreras FOREIGN KEY (carrera_id) REFERENCES carreras (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT ck_perfiles_vendedores_codigo CHECK (CHAR_LENGTH(TRIM(codigo_estudiante)) > 0),
    CONSTRAINT ck_perfiles_vendedores_semestre CHECK (semestre BETWEEN 1 AND 10),
    CONSTRAINT ck_perfiles_vendedores_whatsapp CHECK (REGEXP_LIKE(whatsapp, '^[1-9][0-9]{7,14}$', 'c')),
    CONSTRAINT ck_perfiles_vendedores_mostrar CHECK (mostrar_whatsapp IN (0, 1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Sin FK por correo: un codigo puede preceder a la creacion de la cuenta.
CREATE TABLE IF NOT EXISTS codigos_acceso (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    correo VARCHAR(254) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    proposito ENUM('acceso', 'eliminar_cuenta') NOT NULL DEFAULT 'acceso',
    codigo_hash VARCHAR(255) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    intentos TINYINT UNSIGNED NOT NULL DEFAULT 0,
    creado_en DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    expira_en DATETIME(6) NOT NULL,
    usado_en DATETIME(6) NULL,
    invalidado_en DATETIME(6) NULL,
    PRIMARY KEY (id),
    KEY ix_codigos_acceso_correo_fecha (correo, creado_en),
    KEY ix_codigos_acceso_correo_proposito (correo, proposito, creado_en),
    KEY ix_codigos_acceso_expiracion (expira_en),
    CONSTRAINT ck_codigos_acceso_correo CHECK (
        REGEXP_LIKE(correo, '^[a-z0-9.!#$%&''*+/=?^_`{|}~-]+@([a-z0-9]([a-z0-9-]*[a-z0-9])?[.])*utb[.]edu[.]ec$', 'c')
    ),
    CONSTRAINT ck_codigos_acceso_proposito CHECK (proposito <> ''),
    CONSTRAINT ck_codigos_acceso_hash CHECK (CHAR_LENGTH(codigo_hash) >= 60),
    CONSTRAINT ck_codigos_acceso_intentos CHECK (intentos BETWEEN 0 AND 5),
    CONSTRAINT ck_codigos_acceso_vigencia CHECK (expira_en = creado_en + INTERVAL 10 MINUTE),
    CONSTRAINT ck_codigos_acceso_uso CHECK (usado_en IS NULL OR (usado_en >= creado_en AND usado_en < expira_en AND intentos < 5)),
    CONSTRAINT ck_codigos_acceso_invalidacion CHECK (invalidado_en IS NULL OR invalidado_en >= creado_en)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Modelo de tokens de sesion; requiere adaptar el modelo Sanctum a estos nombres.
CREATE TABLE IF NOT EXISTS sesiones_acceso (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    usuario_id BIGINT UNSIGNED NOT NULL,
    nombre_dispositivo VARCHAR(120) NOT NULL,
    token_hash CHAR(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    creado_en DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    expira_en DATETIME(6) NOT NULL,
    ultima_actividad_en DATETIME(6) NULL,
    PRIMARY KEY (id),
    CONSTRAINT uq_sesiones_acceso_token UNIQUE (token_hash),
    KEY ix_sesiones_acceso_usuario (usuario_id),
    KEY ix_sesiones_acceso_expiracion (expira_en),
    CONSTRAINT fk_sesiones_acceso_usuarios FOREIGN KEY (usuario_id) REFERENCES usuarios (id) ON DELETE CASCADE ON UPDATE RESTRICT,
    CONSTRAINT ck_sesiones_acceso_dispositivo CHECK (CHAR_LENGTH(TRIM(nombre_dispositivo)) > 0),
    CONSTRAINT ck_sesiones_acceso_hash CHECK (REGEXP_LIKE(token_hash, '^[0-9a-f]{64}$', 'c')),
    CONSTRAINT ck_sesiones_acceso_fechas CHECK (expira_en > creado_en),
    CONSTRAINT ck_sesiones_acceso_actividad CHECK (ultima_actividad_en IS NULL OR ultima_actividad_en >= creado_en)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 3. Vitrina. Premium no interviene en los indices de ordenacion.
CREATE TABLE IF NOT EXISTS categorias (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    nombre VARCHAR(80) NOT NULL,
    activa BOOLEAN NOT NULL DEFAULT TRUE,
    orden SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    creado_en DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    actualizado_en DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    CONSTRAINT uq_categorias_nombre UNIQUE (nombre),
    KEY ix_categorias_orden (activa, orden, id),
    CONSTRAINT ck_categorias_nombre CHECK (CHAR_LENGTH(TRIM(nombre)) > 0),
    CONSTRAINT ck_categorias_activa CHECK (activa IN (0, 1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS puntos_entrega (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    nombre VARCHAR(120) NOT NULL,
    descripcion VARCHAR(300) NULL,
    activa BOOLEAN NOT NULL DEFAULT TRUE,
    orden SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    creado_en DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    actualizado_en DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    CONSTRAINT uq_puntos_entrega_nombre UNIQUE (nombre),
    KEY ix_puntos_entrega_orden (activa, orden, id),
    CONSTRAINT ck_puntos_entrega_nombre CHECK (CHAR_LENGTH(TRIM(nombre)) > 0),
    CONSTRAINT ck_puntos_entrega_activa CHECK (activa IN (0, 1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS tiendas (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    usuario_id BIGINT UNSIGNED NOT NULL,
    nombre VARCHAR(40) NOT NULL,
    slug VARCHAR(160) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    descripcion VARCHAR(300) NULL,
    logo_url VARCHAR(2048) NULL,
    portada_url VARCHAR(2048) NULL,
    horario VARCHAR(100) NULL,
    punto_entrega_id BIGINT UNSIGNED NOT NULL,
    estado ENUM('activa', 'dada_de_baja') NOT NULL DEFAULT 'activa',
    motivo_baja VARCHAR(500) NULL,
    dada_de_baja_en DATETIME(6) NULL,
    creado_en DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    actualizado_en DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    CONSTRAINT uq_tiendas_usuario UNIQUE (usuario_id),
    CONSTRAINT uq_tiendas_slug UNIQUE (slug),
    KEY ix_tiendas_vitrina (estado, creado_en, id),
    KEY ix_tiendas_punto_entrega (punto_entrega_id),
    CONSTRAINT fk_tiendas_perfiles_vendedores FOREIGN KEY (usuario_id) REFERENCES perfiles_vendedores (usuario_id) ON DELETE CASCADE ON UPDATE RESTRICT,
    CONSTRAINT fk_tiendas_puntos_entrega FOREIGN KEY (punto_entrega_id) REFERENCES puntos_entrega (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT ck_tiendas_nombre CHECK (CHAR_LENGTH(TRIM(nombre)) BETWEEN 3 AND 40),
    CONSTRAINT ck_tiendas_slug CHECK (REGEXP_LIKE(slug, '^[a-z0-9]+(-[a-z0-9]+)*$', 'c')),
    CONSTRAINT ck_tiendas_baja CHECK (
        (estado = 'activa' AND motivo_baja IS NULL AND dada_de_baja_en IS NULL)
        OR (estado = 'dada_de_baja' AND motivo_baja IS NOT NULL AND CHAR_LENGTH(TRIM(motivo_baja)) > 0 AND dada_de_baja_en IS NOT NULL)
    )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Dos posiciones posibles y ninguna categoria repetida. La primera es obligatoria
-- al publicar: Laravel crea tienda y categorias dentro de la misma transaccion.
CREATE TABLE IF NOT EXISTS tiendas_categorias (
    tienda_id BIGINT UNSIGNED NOT NULL,
    categoria_id BIGINT UNSIGNED NOT NULL,
    orden TINYINT UNSIGNED NOT NULL,
    PRIMARY KEY (tienda_id, categoria_id),
    CONSTRAINT uq_tiendas_categorias_orden UNIQUE (tienda_id, orden),
    KEY ix_tiendas_categorias_categoria (categoria_id, tienda_id),
    CONSTRAINT fk_tiendas_categorias_tiendas FOREIGN KEY (tienda_id) REFERENCES tiendas (id) ON DELETE CASCADE ON UPDATE RESTRICT,
    CONSTRAINT fk_tiendas_categorias_categorias FOREIGN KEY (categoria_id) REFERENCES categorias (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT ck_tiendas_categorias_orden CHECK (orden BETWEEN 1 AND 2)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS productos (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    tienda_id BIGINT UNSIGNED NOT NULL,
    nombre VARCHAR(60) NOT NULL,
    descripcion VARCHAR(300) NULL,
    precio DECIMAL(8,2) NOT NULL,
    disponible BOOLEAN NOT NULL DEFAULT TRUE,
    eliminado_en DATETIME(6) NULL,
    creado_en DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    actualizado_en DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    KEY ix_productos_tienda (tienda_id, eliminado_en, creado_en, id),
    CONSTRAINT fk_productos_tiendas FOREIGN KEY (tienda_id) REFERENCES tiendas (id) ON DELETE CASCADE ON UPDATE RESTRICT,
    CONSTRAINT ck_productos_nombre CHECK (CHAR_LENGTH(TRIM(nombre)) BETWEEN 3 AND 60),
    CONSTRAINT ck_productos_precio CHECK (precio > 0 AND precio <= 500),
    CONSTRAINT ck_productos_disponible CHECK (disponible IN (0, 1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS fotos_productos (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    producto_id BIGINT UNSIGNED NOT NULL,
    url VARCHAR(2048) NOT NULL,
    orden TINYINT UNSIGNED NOT NULL,
    creado_en DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    CONSTRAINT uq_fotos_productos_orden UNIQUE (producto_id, orden),
    CONSTRAINT fk_fotos_productos_productos FOREIGN KEY (producto_id) REFERENCES productos (id) ON DELETE CASCADE ON UPDATE RESTRICT,
    CONSTRAINT ck_fotos_productos_orden CHECK (orden BETWEEN 1 AND 3),
    CONSTRAINT ck_fotos_productos_url CHECK (CHAR_LENGTH(TRIM(url)) > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 4. Pedidos. Las referencias anulables conservan el historial al borrar cuentas.
-- No se copian nombres, correos ni telefonos de personas en este historial.
CREATE TABLE IF NOT EXISTS pedidos (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    codigo VARCHAR(24) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    comprador_id BIGINT UNSIGNED NULL,
    tienda_id BIGINT UNSIGNED NULL,
    punto_entrega_id BIGINT UNSIGNED NOT NULL,
    hora_entrega DATETIME(6) NOT NULL,
    forma_pago ENUM('efectivo', 'transferencia', 'deuna') NOT NULL,
    nota VARCHAR(200) NULL,
    estado ENUM('pendiente', 'entregado', 'cancelado', 'vencido') NOT NULL DEFAULT 'pendiente',
    cancelado_por ENUM('comprador', 'vendedor', 'sistema') NULL,
    estado_cambiado_en DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    creado_en DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    actualizado_en DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    CONSTRAINT uq_pedidos_codigo UNIQUE (codigo),
    KEY ix_pedidos_comprador (comprador_id, creado_en, id),
    KEY ix_pedidos_comprador_estado (comprador_id, estado, creado_en, id),
    KEY ix_pedidos_tienda (tienda_id, creado_en, id),
    KEY ix_pedidos_tienda_estado (tienda_id, estado, creado_en, id),
    KEY ix_pedidos_vencimiento (estado, hora_entrega),
    KEY ix_pedidos_punto_entrega (punto_entrega_id),
    CONSTRAINT fk_pedidos_usuarios FOREIGN KEY (comprador_id) REFERENCES usuarios (id) ON DELETE SET NULL ON UPDATE RESTRICT,
    CONSTRAINT fk_pedidos_tiendas FOREIGN KEY (tienda_id) REFERENCES tiendas (id) ON DELETE SET NULL ON UPDATE RESTRICT,
    CONSTRAINT fk_pedidos_puntos_entrega FOREIGN KEY (punto_entrega_id) REFERENCES puntos_entrega (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT ck_pedidos_codigo CHECK (REGEXP_LIKE(codigo, '^PK-[0-9]{6,20}$', 'c')),
    CONSTRAINT ck_pedidos_pago CHECK (forma_pago <> ''),
    CONSTRAINT ck_pedidos_estado CHECK (estado <> ''),
    CONSTRAINT ck_pedidos_entrega CHECK (hora_entrega >= creado_en + INTERVAL 30 MINUTE AND hora_entrega <= creado_en + INTERVAL 7 DAY),
    CONSTRAINT ck_pedidos_cambio CHECK (estado_cambiado_en >= creado_en),
    CONSTRAINT ck_pedidos_cancelacion CHECK (
        (estado = 'cancelado' AND cancelado_por IS NOT NULL AND cancelado_por <> '')
        OR (estado <> 'cancelado' AND cancelado_por IS NULL)
    )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Nombre y precio son hechos historicos de la venta, no el catalogo actual.
-- No hay subtotal persistido: cantidad * precio_unitario se calcula en una vista.
CREATE TABLE IF NOT EXISTS detalles_pedidos (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    pedido_id BIGINT UNSIGNED NOT NULL,
    producto_id BIGINT UNSIGNED NULL,
    nombre_producto VARCHAR(60) NOT NULL,
    precio_unitario DECIMAL(8,2) NOT NULL,
    cantidad TINYINT UNSIGNED NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT uq_detalles_pedidos_producto UNIQUE (pedido_id, producto_id),
    KEY ix_detalles_pedidos_producto (producto_id),
    CONSTRAINT fk_detalles_pedidos_pedidos FOREIGN KEY (pedido_id) REFERENCES pedidos (id) ON DELETE CASCADE ON UPDATE RESTRICT,
    CONSTRAINT fk_detalles_pedidos_productos FOREIGN KEY (producto_id) REFERENCES productos (id) ON DELETE SET NULL ON UPDATE RESTRICT,
    CONSTRAINT ck_detalles_pedidos_nombre CHECK (CHAR_LENGTH(TRIM(nombre_producto)) BETWEEN 3 AND 60),
    CONSTRAINT ck_detalles_pedidos_precio CHECK (precio_unitario > 0 AND precio_unitario <= 500),
    CONSTRAINT ck_detalles_pedidos_cantidad CHECK (cantidad BETWEEN 1 AND 20)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 5. Moderacion. La API comprueba que quien revisa es administrador.
CREATE TABLE IF NOT EXISTS reportes (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    tienda_id BIGINT UNSIGNED NOT NULL,
    reportado_por BIGINT UNSIGNED NULL,
    motivo ENUM('prohibido', 'no_entrego', 'informacion_falsa', 'trato_inadecuado', 'otro') NOT NULL,
    detalle VARCHAR(300) NULL,
    estado ENUM('nuevo', 'sin_accion', 'tienda_dada_de_baja') NOT NULL DEFAULT 'nuevo',
    revisado_por BIGINT UNSIGNED NULL,
    revisado_en DATETIME(6) NULL,
    nota_admin VARCHAR(500) NULL,
    creado_en DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    actualizado_en DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    KEY ix_reportes_tienda_usuario_fecha (tienda_id, reportado_por, creado_en),
    KEY ix_reportes_reportante (reportado_por),
    KEY ix_reportes_revision (estado, creado_en, id),
    KEY ix_reportes_revisor (revisado_por),
    CONSTRAINT fk_reportes_tiendas FOREIGN KEY (tienda_id) REFERENCES tiendas (id) ON DELETE CASCADE ON UPDATE RESTRICT,
    CONSTRAINT fk_reportes_reportantes FOREIGN KEY (reportado_por) REFERENCES usuarios (id) ON DELETE SET NULL ON UPDATE RESTRICT,
    CONSTRAINT fk_reportes_revisores FOREIGN KEY (revisado_por) REFERENCES usuarios (id) ON DELETE SET NULL ON UPDATE RESTRICT,
    CONSTRAINT ck_reportes_motivo CHECK (motivo <> ''),
    CONSTRAINT ck_reportes_detalle CHECK (motivo <> 'otro' OR (detalle IS NOT NULL AND CHAR_LENGTH(TRIM(detalle)) > 0)),
    CONSTRAINT ck_reportes_revision CHECK (
        (estado = 'nuevo' AND revisado_en IS NULL AND nota_admin IS NULL)
        OR (estado = 'sin_accion' AND revisado_en IS NOT NULL AND nota_admin IS NOT NULL AND CHAR_LENGTH(TRIM(nota_admin)) > 0)
        OR (estado = 'tienda_dada_de_baja' AND revisado_en IS NOT NULL)
    ),
    CONSTRAINT ck_reportes_fecha CHECK (revisado_en IS NULL OR revisado_en >= creado_en)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 6. Configuracion de cobro de la plataforma (NO cuentas bancarias de alumnos).
CREATE TABLE IF NOT EXISTS cuentas_bancarias (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    banco VARCHAR(120) NOT NULL,
    tipo_cuenta ENUM('ahorros', 'corriente') NOT NULL,
    numero VARCHAR(40) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    titular VARCHAR(150) NOT NULL,
    creado_en DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    actualizado_en DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    CONSTRAINT uq_cuentas_bancarias_numero UNIQUE (banco, tipo_cuenta, numero),
    CONSTRAINT ck_cuentas_bancarias_banco CHECK (CHAR_LENGTH(TRIM(banco)) > 0),
    CONSTRAINT ck_cuentas_bancarias_tipo CHECK (tipo_cuenta <> ''),
    CONSTRAINT ck_cuentas_bancarias_numero CHECK (CHAR_LENGTH(TRIM(numero)) > 0),
    CONSTRAINT ck_cuentas_bancarias_titular CHECK (CHAR_LENGTH(TRIM(titular)) > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS configuraciones (
    id TINYINT UNSIGNED NOT NULL DEFAULT 1,
    precio_premium DECIMAL(8,2) NOT NULL,
    cuenta_bancaria_id BIGINT UNSIGNED NOT NULL,
    usuario_deuna VARCHAR(120) NULL,
    periodo_actual_id BIGINT UNSIGNED NOT NULL,
    dias_conservacion_comprobantes SMALLINT UNSIGNED NOT NULL,
    limite_pedidos_gratis INT UNSIGNED NULL DEFAULT NULL,
    creado_en DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    actualizado_en DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    KEY ix_configuraciones_cuenta (cuenta_bancaria_id),
    KEY ix_configuraciones_periodo (periodo_actual_id),
    CONSTRAINT fk_configuraciones_cuentas FOREIGN KEY (cuenta_bancaria_id) REFERENCES cuentas_bancarias (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_configuraciones_periodos FOREIGN KEY (periodo_actual_id) REFERENCES periodos_academicos (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT ck_configuraciones_fila CHECK (id = 1),
    CONSTRAINT ck_configuraciones_precio CHECK (precio_premium > 0),
    CONSTRAINT ck_configuraciones_deuna CHECK (usuario_deuna IS NULL OR CHAR_LENGTH(TRIM(usuario_deuna)) > 0),
    CONSTRAINT ck_configuraciones_retencion CHECK (dias_conservacion_comprobantes > 0),
    CONSTRAINT ck_configuraciones_sin_limite CHECK (limite_pedidos_gratis IS NULL)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- El periodo se asigna AL APROBAR, desde configuraciones.periodo_actual_id.
-- Se conserva numero/monto del pago al borrar una tienda; su foto se elimina
-- desde Laravel y la referencia a la tienda pasa a NULL. No permite reutilizar
-- comprobantes aprobados despues de borrar una cuenta.
CREATE TABLE IF NOT EXISTS solicitudes_premium (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    tienda_id BIGINT UNSIGNED NULL,
    numero_comprobante VARCHAR(100) COLLATE utf8mb4_0900_as_ci NOT NULL,
    monto DECIMAL(8,2) NOT NULL,
    foto_comprobante VARCHAR(512) NULL COMMENT 'Ruta PRIVADA; nunca una URL publica',
    estado ENUM('pendiente', 'aprobada', 'rechazada') NOT NULL DEFAULT 'pendiente',
    periodo_academico_id BIGINT UNSIGNED NULL,
    motivo_rechazo VARCHAR(300) NULL,
    revisado_por BIGINT UNSIGNED NULL,
    revisado_en DATETIME(6) NULL,
    foto_borrada_en DATETIME(6) NULL,
    creado_en DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    actualizado_en DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    KEY ix_solicitudes_premium_tienda (tienda_id, creado_en, id),
    KEY ix_solicitudes_premium_revision (estado, creado_en, id),
    KEY ix_solicitudes_premium_periodo (periodo_academico_id),
    KEY ix_solicitudes_premium_revisor (revisado_por),
    -- Indices funcionales: unicidad condicional sin columnas de negocio duplicadas.
    UNIQUE KEY uq_solicitudes_premium_pendiente ((CASE WHEN estado = 'pendiente' THEN tienda_id ELSE NULL END)),
    UNIQUE KEY uq_solicitudes_premium_comprobante ((CASE WHEN estado = 'aprobada' THEN numero_comprobante ELSE NULL END)),
    CONSTRAINT fk_solicitudes_premium_tiendas FOREIGN KEY (tienda_id) REFERENCES tiendas (id) ON DELETE SET NULL ON UPDATE RESTRICT,
    CONSTRAINT fk_solicitudes_premium_periodos FOREIGN KEY (periodo_academico_id) REFERENCES periodos_academicos (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_solicitudes_premium_revisores FOREIGN KEY (revisado_por) REFERENCES usuarios (id) ON DELETE SET NULL ON UPDATE RESTRICT,
    CONSTRAINT ck_solicitudes_premium_comprobante CHECK (CHAR_LENGTH(TRIM(numero_comprobante)) > 0 AND OCTET_LENGTH(numero_comprobante) = OCTET_LENGTH(TRIM(numero_comprobante))),
    CONSTRAINT ck_solicitudes_premium_monto CHECK (monto > 0),
    CONSTRAINT ck_solicitudes_premium_revision CHECK (
        (estado = 'pendiente' AND revisado_en IS NULL AND motivo_rechazo IS NULL)
        OR (estado = 'aprobada' AND revisado_en IS NOT NULL AND motivo_rechazo IS NULL)
        OR (estado = 'rechazada' AND revisado_en IS NOT NULL AND motivo_rechazo IS NOT NULL AND CHAR_LENGTH(TRIM(motivo_rechazo)) > 0)
    ),
    CONSTRAINT ck_solicitudes_premium_periodo CHECK (
        (estado = 'aprobada' AND periodo_academico_id IS NOT NULL)
        OR (estado <> 'aprobada' AND periodo_academico_id IS NULL)
    ),
    CONSTRAINT ck_solicitudes_premium_foto CHECK (
        (foto_comprobante IS NOT NULL AND CHAR_LENGTH(TRIM(foto_comprobante)) > 0 AND foto_borrada_en IS NULL)
        OR (foto_comprobante IS NULL AND foto_borrada_en IS NOT NULL)
    ),
    CONSTRAINT ck_solicitudes_premium_fechas CHECK (
        (revisado_en IS NULL OR revisado_en >= creado_en)
        AND (foto_borrada_en IS NULL OR foto_borrada_en >= creado_en)
    )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 7. Proyecciones de lectura: no almacenan registros ni duplican importes.
CREATE OR REPLACE SQL SECURITY INVOKER VIEW vistas_detalles_pedidos AS
SELECT id, pedido_id, producto_id, nombre_producto, precio_unitario, cantidad,
       CAST(precio_unitario * cantidad AS DECIMAL(10,2)) AS subtotal
FROM detalles_pedidos;

CREATE OR REPLACE SQL SECURITY INVOKER VIEW vistas_totales_pedidos AS
SELECT p.id AS pedido_id,
       CAST(COALESCE(SUM(d.precio_unitario * d.cantidad), 0) AS DECIMAL(18,2)) AS total
FROM pedidos AS p
LEFT JOIN detalles_pedidos AS d ON d.pedido_id = p.id
GROUP BY p.id;

-- Premium vigente en fecha de Ecuador continental (UTC-05:00), sin requerir
-- cargar las tablas de zonas horarias de MySQL. La expiracion no depende de cron.
-- Un periodo utilizado para aprobaciones se trata como inmutable en Laravel.
CREATE OR REPLACE SQL SECURITY INVOKER VIEW vistas_planes_tiendas AS
SELECT t.id AS tienda_id,
       CASE WHEN vigencias.premium_hasta IS NULL THEN 'gratis' ELSE 'premium' END AS plan,
       vigencias.premium_hasta
FROM tiendas AS t
LEFT JOIN (
    SELECT s.tienda_id, MAX(p.fecha_fin) AS premium_hasta
    FROM solicitudes_premium AS s
    INNER JOIN periodos_academicos AS p ON p.id = s.periodo_academico_id
    WHERE s.estado = 'aprobada'
      AND s.revisado_en <= UTC_TIMESTAMP(6)
      AND p.fecha_fin >= DATE(UTC_TIMESTAMP() - INTERVAL 5 HOUR)
    GROUP BY s.tienda_id
) AS vigencias ON vigencias.tienda_id = t.id;

SET SESSION sql_mode = @pk_modo_anterior;
SET SESSION time_zone = @pk_zona_anterior;

SELECT 'Ejecucion completada; no se insertaron ni borraron datos.' AS resultado;
