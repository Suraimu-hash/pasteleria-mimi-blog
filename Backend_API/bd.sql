

CREATE DATABASE IF NOT EXISTS bd_aplicacion_movil
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE bd_aplicacion_movil;

DROP TABLE IF EXISTS mensaje;
DROP TABLE IF EXISTS pedido_detalle;
DROP TABLE IF EXISTS pedido;
DROP TABLE IF EXISTS carrito;
DROP TABLE IF EXISTS producto;
DROP TABLE IF EXISTS reaccion_comentario;
DROP TABLE IF EXISTS valoracion;
DROP TABLE IF EXISTS comentarios;
DROP TABLE IF EXISTS blog;
DROP TABLE IF EXISTS usuario;

-- ---------- Usuarios ----------
-- tip_usu: 1 = administrador (Pastelería), 2 = cliente / usuario general
-- pass guarda el HASH Argon2 de la contraseña, nunca la contraseña.
CREATE TABLE usuario (
    id_usr   INT AUTO_INCREMENT PRIMARY KEY,
    nom_usr  VARCHAR(100) NOT NULL,
    mail     VARCHAR(150) NOT NULL UNIQUE,
    pass     VARCHAR(255) NOT NULL,
    dir_usr  VARCHAR(200),
    tip_usu  INT NOT NULL DEFAULT 2
) ENGINE=InnoDB;

-- ---------- Publicaciones del blog (pasteles) ----------
CREATE TABLE blog (
    id_blog INT AUTO_INCREMENT PRIMARY KEY,
    titulo  VARCHAR(150) NOT NULL,
    `desc`  TEXT,
    img     VARCHAR(500),
    tags    VARCHAR(255),
    fecha   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    usr_id  INT NOT NULL,                       -- autor de la publicación

    CONSTRAINT fk_blog_usuario
        FOREIGN KEY (usr_id) REFERENCES usuario(id_usr)
        ON DELETE CASCADE,
    INDEX idx_blog_fecha (fecha)
) ENGINE=InnoDB;

-- ---------- Comentarios ----------
CREATE TABLE comentarios (
    id_com     INT AUTO_INCREMENT PRIMARY KEY,
    comentario TEXT NOT NULL,
    sticker    VARCHAR(30),                     -- código de sticker (opcional)
    fecha      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    estatus    INT NOT NULL DEFAULT 1,
    usr_id     INT NOT NULL,
    blog_id    INT NOT NULL,

    CONSTRAINT fk_comentario_usuario
        FOREIGN KEY (usr_id) REFERENCES usuario(id_usr)
        ON DELETE CASCADE,
    CONSTRAINT fk_comentario_blog
        FOREIGN KEY (blog_id) REFERENCES blog(id_blog)
        ON DELETE CASCADE,
    INDEX idx_comentarios_blog (blog_id)
) ENGINE=InnoDB;

-- =====================================================================
--  MÓDULOS OPCIONALES (alcance extendido)
-- =====================================================================

-- ---------- Valoraciones: estrellas 1–5 por publicación ----------
CREATE TABLE valoracion (
    id_val    INT AUTO_INCREMENT PRIMARY KEY,
    estrellas INT NOT NULL,
    fecha     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    blog_id   INT NOT NULL,
    usr_id    INT NOT NULL,
    CONSTRAINT chk_estrellas CHECK (estrellas BETWEEN 1 AND 5),
    CONSTRAINT uq_valoracion UNIQUE (blog_id, usr_id),   -- una por usuario
    CONSTRAINT fk_val_blog FOREIGN KEY (blog_id) REFERENCES blog(id_blog) ON DELETE CASCADE,
    CONSTRAINT fk_val_usuario FOREIGN KEY (usr_id) REFERENCES usuario(id_usr) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------- Reacciones (emoji) a comentarios ----------
-- tipo: me_encanta, me_gusta, risa, wow, triste, antojo
CREATE TABLE reaccion_comentario (
    id_reac INT AUTO_INCREMENT PRIMARY KEY,
    tipo    VARCHAR(20) NOT NULL,
    com_id  INT NOT NULL,
    usr_id  INT NOT NULL,
    CONSTRAINT uq_reaccion UNIQUE (com_id, usr_id, tipo),
    CONSTRAINT fk_reac_com FOREIGN KEY (com_id) REFERENCES comentarios(id_com) ON DELETE CASCADE,
    CONSTRAINT fk_reac_usuario FOREIGN KEY (usr_id) REFERENCES usuario(id_usr) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------- Tienda: catálogo ----------
CREATE TABLE producto (
    id_prod     INT AUTO_INCREMENT PRIMARY KEY,
    nombre      VARCHAR(150) NOT NULL,
    descripcion TEXT,
    precio      DECIMAL(10,2) NOT NULL,
    img         VARCHAR(500),
    categoria   VARCHAR(80),
    stock       INT NOT NULL DEFAULT 0,
    activo      BOOLEAN NOT NULL DEFAULT TRUE
) ENGINE=InnoDB;

-- ---------- Tienda: carrito (un renglón por producto y usuario) ----------
CREATE TABLE carrito (
    id_car   INT AUTO_INCREMENT PRIMARY KEY,
    cantidad INT NOT NULL DEFAULT 1,
    usr_id   INT NOT NULL,
    prod_id  INT NOT NULL,
    CONSTRAINT uq_carrito UNIQUE (usr_id, prod_id),
    CONSTRAINT fk_car_usuario FOREIGN KEY (usr_id) REFERENCES usuario(id_usr) ON DELETE CASCADE,
    CONSTRAINT fk_car_producto FOREIGN KEY (prod_id) REFERENCES producto(id_prod) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------- Tienda: pedidos ----------
-- estatus: pagado, pendiente_pago, en_preparacion, enviado, entregado, cancelado
-- Del pago con tarjeta solo se guardan los últimos 4 dígitos.
CREATE TABLE pedido (
    id_ped           INT AUTO_INCREMENT PRIMARY KEY,
    fecha            DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    total            DECIMAL(10,2) NOT NULL,
    estatus          VARCHAR(20) NOT NULL DEFAULT 'pagado',
    direccion_envio  VARCHAR(250) NOT NULL,
    telefono         VARCHAR(20),
    metodo_pago      VARCHAR(20) NOT NULL,
    referencia_pago  VARCHAR(40) NOT NULL,
    tarjeta_ultimos4 CHAR(4),
    usr_id           INT NOT NULL,
    CONSTRAINT fk_ped_usuario FOREIGN KEY (usr_id) REFERENCES usuario(id_usr) ON DELETE CASCADE,
    INDEX idx_pedido_fecha (fecha)
) ENGINE=InnoDB;

CREATE TABLE pedido_detalle (
    id_det          INT AUTO_INCREMENT PRIMARY KEY,
    nombre          VARCHAR(150) NOT NULL,
    precio_unitario DECIMAL(10,2) NOT NULL,
    cantidad        INT NOT NULL,
    ped_id          INT NOT NULL,
    prod_id         INT,
    CONSTRAINT fk_det_pedido FOREIGN KEY (ped_id) REFERENCES pedido(id_ped) ON DELETE CASCADE,
    CONSTRAINT fk_det_producto FOREIGN KEY (prod_id) REFERENCES producto(id_prod) ON DELETE SET NULL
) ENGINE=InnoDB;

-- ---------- Mensajería interna ----------
CREATE TABLE mensaje (
    id_msg          INT AUTO_INCREMENT PRIMARY KEY,
    texto           TEXT NOT NULL,
    fecha           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    leido           BOOLEAN NOT NULL DEFAULT FALSE,
    remitente_id    INT NOT NULL,
    destinatario_id INT NOT NULL,
    CONSTRAINT fk_msg_remitente FOREIGN KEY (remitente_id) REFERENCES usuario(id_usr) ON DELETE CASCADE,
    CONSTRAINT fk_msg_destinatario FOREIGN KEY (destinatario_id) REFERENCES usuario(id_usr) ON DELETE CASCADE,
    INDEX idx_msg_remitente (remitente_id),
    INDEX idx_msg_destinatario (destinatario_id)
) ENGINE=InnoDB;
