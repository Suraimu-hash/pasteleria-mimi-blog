from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field

CORREO_REGEX = r"^[^@\s]+@[^@\s]+\.[^@\s]+$"


# ---------- Usuarios ----------
class UsuarioCrear(BaseModel):
    nom_usr: str = Field(min_length=2, max_length=100)
    mail: str = Field(min_length=5, max_length=150, pattern=CORREO_REGEX)
    password: str = Field(min_length=8, max_length=128)
    dir_usr: str | None = Field(default=None, max_length=200)
    tip_usu: int = Field(default=2, ge=1, le=2)


class UsuarioActualizar(BaseModel):
    nom_usr: str = Field(min_length=2, max_length=100)
    mail: str = Field(min_length=5, max_length=150, pattern=CORREO_REGEX)
    dir_usr: str | None = Field(default=None, max_length=200)
    tip_usu: int = Field(default=2, ge=1, le=2)


class UsuarioRespuesta(BaseModel):
    id_usr: int
    nom_usr: str
    mail: str
    dir_usr: str | None
    tip_usu: int

    model_config = ConfigDict(from_attributes=True)


# ---------- Sesión ----------
class LoginRequest(BaseModel):
    mail: str = Field(min_length=5, max_length=150)
    password: str = Field(min_length=1, max_length=128)


class LoginRespuesta(BaseModel):
    access_token: str
    token_type: str = "bearer"
    usuario: UsuarioRespuesta


# ---------- Blog de pasteles ----------
class BlogCrear(BaseModel):
    titulo: str = Field(min_length=2, max_length=150)
    descripcion: str = Field(min_length=1, max_length=10000)
    img: str | None = Field(default=None, max_length=500)
    tags: str | None = Field(default=None, max_length=255)


class BlogRespuesta(BaseModel):
    id_blog: int
    titulo: str
    descripcion: str | None = None
    img: str | None = None
    tags: str | None = None
    fecha: datetime
    usr_id: int
    autor: str
    num_comentarios: int
    # Valoraciones
    promedio_estrellas: float = 0
    num_valoraciones: int = 0
    mi_valoracion: int | None = None


# ---------- Valoraciones ----------
class ValoracionCrear(BaseModel):
    estrellas: int = Field(ge=1, le=5)


# ---------- Comentarios ----------
class ComentarioCrear(BaseModel):
    # El texto puede ir vacío si el comentario lleva un sticker.
    comentario: str = Field(default="", max_length=1000)
    sticker: str | None = Field(default=None, max_length=30)


class ReaccionResumen(BaseModel):
    tipo: str
    total: int
    mia: bool


class ReaccionCrear(BaseModel):
    tipo: str = Field(min_length=1, max_length=20)


class ComentarioRespuesta(BaseModel):
    id_com: int
    comentario: str
    sticker: str | None = None
    fecha: datetime
    usr_id: int
    blog_id: int
    nombre_usuario: str
    reacciones: list[ReaccionResumen] = []


# ---------- Tienda: productos ----------
class ProductoGuardar(BaseModel):
    nombre: str = Field(min_length=2, max_length=150)
    descripcion: str | None = Field(default=None, max_length=5000)
    precio: float = Field(gt=0, le=1_000_000)
    img: str | None = Field(default=None, max_length=500)
    categoria: str | None = Field(default=None, max_length=80)
    stock: int = Field(default=0, ge=0, le=100_000)
    activo: bool = True


class ProductoRespuesta(BaseModel):
    id_prod: int
    nombre: str
    descripcion: str | None = None
    precio: float
    img: str | None = None
    categoria: str | None = None
    stock: int
    activo: bool


# ---------- Tienda: carrito ----------
class CarritoAgregar(BaseModel):
    prod_id: int
    cantidad: int = Field(default=1, ge=1, le=99)


class CarritoCantidad(BaseModel):
    cantidad: int = Field(ge=1, le=99)


class CarritoItemRespuesta(BaseModel):
    prod_id: int
    nombre: str
    img: str | None = None
    precio: float
    cantidad: int
    subtotal: float
    stock: int


class CarritoRespuesta(BaseModel):
    items: list[CarritoItemRespuesta]
    total: float
    num_articulos: int


# ---------- Tienda: pago y pedidos ----------
class PagoTarjeta(BaseModel):
    titular: str = Field(min_length=3, max_length=100)
    numero: str = Field(min_length=12, max_length=23)
    vencimiento: str = Field(min_length=4, max_length=7)  # MM/AA
    cvv: str = Field(min_length=3, max_length=4)


class CheckoutRequest(BaseModel):
    direccion_envio: str = Field(min_length=5, max_length=250)
    telefono: str | None = Field(default=None, max_length=20)
    metodo_pago: str = Field(pattern=r"^(tarjeta|efectivo)$")
    tarjeta: PagoTarjeta | None = None


class PedidoDetalleRespuesta(BaseModel):
    prod_id: int | None
    nombre: str
    precio_unitario: float
    cantidad: int
    subtotal: float


class PedidoRespuesta(BaseModel):
    id_ped: int
    fecha: datetime
    total: float
    estatus: str
    direccion_envio: str
    telefono: str | None = None
    metodo_pago: str
    referencia_pago: str
    tarjeta_ultimos4: str | None = None
    usr_id: int
    cliente: str
    detalles: list[PedidoDetalleRespuesta]


class PedidoEstatus(BaseModel):
    estatus: str = Field(
        pattern=r"^(pagado|pendiente_pago|en_preparacion|enviado|entregado|cancelado)$"
    )


# ---------- Mensajería ----------
class MensajeCrear(BaseModel):
    texto: str = Field(min_length=1, max_length=2000)


class MensajeRespuesta(BaseModel):
    id_msg: int
    texto: str
    fecha: datetime
    leido: bool
    remitente_id: int
    destinatario_id: int


class ConversacionRespuesta(BaseModel):
    usuario_id: int
    nombre: str
    es_admin: bool
    ultimo_mensaje: str
    fecha: datetime
    no_leidos: int


class ContactoRespuesta(BaseModel):
    id_usr: int
    nom_usr: str
    tip_usu: int
