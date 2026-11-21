from sqlalchemy import (
    Boolean, Column, DateTime, ForeignKey, Integer, Numeric, String, Text,
    UniqueConstraint, func,
)
from sqlalchemy.orm import relationship

from database import Base


class Usuario(Base):
    __tablename__ = "usuario"

    id_usr = Column(Integer, primary_key=True, index=True)
    nom_usr = Column(String(100), nullable=False)
    mail = Column(String(150), unique=True, nullable=False)
    pass_hash = Column("pass", String(255), nullable=False)
    dir_usr = Column(String(200), nullable=True)
    tip_usu = Column(Integer, nullable=False, default=2)  # 1 = admin, 2 = cliente

    publicaciones = relationship(
        "Blog", back_populates="autor",
        cascade="all, delete-orphan", passive_deletes=True,
    )
    comentarios = relationship(
        "Comentario", back_populates="usuario",
        cascade="all, delete-orphan", passive_deletes=True,
    )


class Blog(Base):
    __tablename__ = "blog"

    id_blog = Column(Integer, primary_key=True, index=True)
    titulo = Column(String(150), nullable=False)
    descripcion = Column("desc", Text, nullable=True)
    img = Column(String(500), nullable=True)
    tags = Column(String(255), nullable=True)
    fecha = Column(
        DateTime, nullable=False, server_default=func.current_timestamp()
    )
    usr_id = Column(
        Integer, ForeignKey("usuario.id_usr", ondelete="CASCADE"), nullable=False
    )

    autor = relationship("Usuario", back_populates="publicaciones")
    comentarios = relationship(
        "Comentario", back_populates="blog",
        cascade="all, delete-orphan", passive_deletes=True,
    )
    valoraciones = relationship(
        "Valoracion", cascade="all, delete-orphan", passive_deletes=True,
    )


class Comentario(Base):
    __tablename__ = "comentarios"

    id_com = Column(Integer, primary_key=True, index=True)
    comentario = Column(Text, nullable=False)
    sticker = Column(String(30), nullable=True)  # código de sticker (opcional)
    fecha = Column(
        DateTime, nullable=False, server_default=func.current_timestamp()
    )
    estatus = Column(Integer, nullable=False, default=1)
    usr_id = Column(
        Integer, ForeignKey("usuario.id_usr", ondelete="CASCADE"), nullable=False
    )
    blog_id = Column(
        Integer, ForeignKey("blog.id_blog", ondelete="CASCADE"), nullable=False
    )

    usuario = relationship("Usuario", back_populates="comentarios")
    blog = relationship("Blog", back_populates="comentarios")
    reacciones = relationship(
        "ReaccionComentario", cascade="all, delete-orphan", passive_deletes=True,
    )


# ======================================================================
# Módulo: Sistema de puntuación / valoración (estrellas 1–5)
# ======================================================================
class Valoracion(Base):
    __tablename__ = "valoracion"
    __table_args__ = (UniqueConstraint("blog_id", "usr_id", name="uq_valoracion"),)

    id_val = Column(Integer, primary_key=True, index=True)
    estrellas = Column(Integer, nullable=False)
    fecha = Column(
        DateTime, nullable=False, server_default=func.current_timestamp()
    )
    blog_id = Column(
        Integer, ForeignKey("blog.id_blog", ondelete="CASCADE"), nullable=False
    )
    usr_id = Column(
        Integer, ForeignKey("usuario.id_usr", ondelete="CASCADE"), nullable=False
    )


# ======================================================================
# Módulo: Comentarios interactivos (reacciones con emoji)
# ======================================================================
class ReaccionComentario(Base):
    __tablename__ = "reaccion_comentario"
    __table_args__ = (
        UniqueConstraint("com_id", "usr_id", "tipo", name="uq_reaccion"),
    )

    id_reac = Column(Integer, primary_key=True, index=True)
    tipo = Column(String(20), nullable=False)  # código: me_encanta, risa, ...
    com_id = Column(
        Integer, ForeignKey("comentarios.id_com", ondelete="CASCADE"), nullable=False
    )
    usr_id = Column(
        Integer, ForeignKey("usuario.id_usr", ondelete="CASCADE"), nullable=False
    )


# ======================================================================
# Módulo: Venta y comercio electrónico
# ======================================================================
class Producto(Base):
    __tablename__ = "producto"

    id_prod = Column(Integer, primary_key=True, index=True)
    nombre = Column(String(150), nullable=False)
    descripcion = Column(Text, nullable=True)
    precio = Column(Numeric(10, 2), nullable=False)
    img = Column(String(500), nullable=True)
    categoria = Column(String(80), nullable=True)
    stock = Column(Integer, nullable=False, default=0)
    activo = Column(Boolean, nullable=False, default=True)


class CarritoItem(Base):
    __tablename__ = "carrito"
    __table_args__ = (UniqueConstraint("usr_id", "prod_id", name="uq_carrito"),)

    id_car = Column(Integer, primary_key=True, index=True)
    cantidad = Column(Integer, nullable=False, default=1)
    usr_id = Column(
        Integer, ForeignKey("usuario.id_usr", ondelete="CASCADE"), nullable=False
    )
    prod_id = Column(
        Integer, ForeignKey("producto.id_prod", ondelete="CASCADE"), nullable=False
    )

    producto = relationship("Producto")


class Pedido(Base):
    __tablename__ = "pedido"

    id_ped = Column(Integer, primary_key=True, index=True)
    fecha = Column(
        DateTime, nullable=False, server_default=func.current_timestamp()
    )
    total = Column(Numeric(10, 2), nullable=False)
    # pagado -> en_preparacion -> enviado -> entregado  |  cancelado
    estatus = Column(String(20), nullable=False, default="pagado")
    direccion_envio = Column(String(250), nullable=False)
    telefono = Column(String(20), nullable=True)
    metodo_pago = Column(String(20), nullable=False)  # tarjeta | efectivo
    referencia_pago = Column(String(40), nullable=False)
    tarjeta_ultimos4 = Column(String(4), nullable=True)  # nunca el número completo
    usr_id = Column(
        Integer, ForeignKey("usuario.id_usr", ondelete="CASCADE"), nullable=False
    )

    usuario = relationship("Usuario")
    detalles = relationship(
        "PedidoDetalle", cascade="all, delete-orphan", passive_deletes=True,
        order_by="PedidoDetalle.id_det",
    )


class PedidoDetalle(Base):
    __tablename__ = "pedido_detalle"

    id_det = Column(Integer, primary_key=True, index=True)
    nombre = Column(String(150), nullable=False)  # copia del nombre al comprar
    precio_unitario = Column(Numeric(10, 2), nullable=False)
    cantidad = Column(Integer, nullable=False)
    ped_id = Column(
        Integer, ForeignKey("pedido.id_ped", ondelete="CASCADE"), nullable=False
    )
    prod_id = Column(
        Integer, ForeignKey("producto.id_prod", ondelete="SET NULL"), nullable=True
    )


# ======================================================================
# Módulo: Mensajería interna (mensajes directos entre usuarios)
# ======================================================================
class Mensaje(Base):
    __tablename__ = "mensaje"

    id_msg = Column(Integer, primary_key=True, index=True)
    texto = Column(Text, nullable=False)
    fecha = Column(
        DateTime, nullable=False, server_default=func.current_timestamp()
    )
    leido = Column(Boolean, nullable=False, default=False)
    remitente_id = Column(
        Integer, ForeignKey("usuario.id_usr", ondelete="CASCADE"), nullable=False,
        index=True,
    )
    destinatario_id = Column(
        Integer, ForeignKey("usuario.id_usr", ondelete="CASCADE"), nullable=False,
        index=True,
    )
