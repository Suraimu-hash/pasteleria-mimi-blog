"""Módulo de venta y comercio electrónico: catálogo, carrito, pago y pedidos.

El pago en línea es una PASARELA SIMULADA (modo de prueba): valida la tarjeta
(algoritmo de Luhn, vencimiento y CVV) y genera una referencia, pero no cobra
dinero real. Nunca se guarda el número completo ni el CVV; solo los últimos 4.

Tarjetas de prueba:
    4242 4242 4242 4242  -> pago aprobado
    4000 0000 0000 0002  -> pago rechazado (fondos insuficientes)
"""
import secrets
from datetime import datetime
from decimal import Decimal

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from database import obtener_sesion
from models import CarritoItem, Pedido, PedidoDetalle, Producto, Usuario
from schemas import (
    CarritoAgregar,
    CarritoCantidad,
    CarritoItemRespuesta,
    CarritoRespuesta,
    CheckoutRequest,
    PagoTarjeta,
    PedidoDetalleRespuesta,
    PedidoEstatus,
    PedidoRespuesta,
    ProductoGuardar,
    ProductoRespuesta,
)
from security import ADMIN, solo_admin, usuario_actual

router = APIRouter(tags=["Tienda"])

TARJETA_RECHAZADA = "4000000000000002"


# ----------------------------------------------------------------------
# Utilidades
# ----------------------------------------------------------------------
def _producto_a_respuesta(p: Producto) -> ProductoRespuesta:
    return ProductoRespuesta(
        id_prod=p.id_prod,
        nombre=p.nombre,
        descripcion=p.descripcion,
        precio=float(p.precio),
        img=p.img,
        categoria=p.categoria,
        stock=p.stock,
        activo=bool(p.activo),
    )


def _producto_o_404(db: Session, prod_id: int) -> Producto:
    producto = db.get(Producto, prod_id)
    if producto is None:
        raise HTTPException(status_code=404, detail="Producto no encontrado")
    return producto


def _carrito(db: Session, usuario: Usuario) -> CarritoRespuesta:
    items = db.scalars(
        select(CarritoItem)
        .where(CarritoItem.usr_id == usuario.id_usr)
        .order_by(CarritoItem.id_car)
    ).all()
    respuesta = []
    total = Decimal("0")
    articulos = 0
    for item in items:
        p = item.producto
        subtotal = p.precio * item.cantidad
        total += subtotal
        articulos += item.cantidad
        respuesta.append(
            CarritoItemRespuesta(
                prod_id=p.id_prod,
                nombre=p.nombre,
                img=p.img,
                precio=float(p.precio),
                cantidad=item.cantidad,
                subtotal=float(subtotal),
                stock=p.stock,
            )
        )
    return CarritoRespuesta(items=respuesta, total=float(total), num_articulos=articulos)


def _pedido_a_respuesta(p: Pedido) -> PedidoRespuesta:
    return PedidoRespuesta(
        id_ped=p.id_ped,
        fecha=p.fecha,
        total=float(p.total),
        estatus=p.estatus,
        direccion_envio=p.direccion_envio,
        telefono=p.telefono,
        metodo_pago=p.metodo_pago,
        referencia_pago=p.referencia_pago,
        tarjeta_ultimos4=p.tarjeta_ultimos4,
        usr_id=p.usr_id,
        cliente=p.usuario.nom_usr,
        detalles=[
            PedidoDetalleRespuesta(
                prod_id=d.prod_id,
                nombre=d.nombre,
                precio_unitario=float(d.precio_unitario),
                cantidad=d.cantidad,
                subtotal=float(d.precio_unitario * d.cantidad),
            )
            for d in p.detalles
        ],
    )


def _luhn_valido(numero: str) -> bool:
    suma = 0
    for i, c in enumerate(reversed(numero)):
        d = int(c)
        if i % 2 == 1:
            d *= 2
            if d > 9:
                d -= 9
        suma += d
    return suma % 10 == 0


def _procesar_pago_simulado(tarjeta: PagoTarjeta) -> str:
    """Valida la tarjeta y devuelve los últimos 4 dígitos. Lanza 402 si se rechaza."""
    numero = tarjeta.numero.replace(" ", "").replace("-", "")
    if not numero.isdigit() or not 13 <= len(numero) <= 19 or not _luhn_valido(numero):
        raise HTTPException(status_code=422, detail="Número de tarjeta no válido")

    try:
        mes_txt, anio_txt = tarjeta.vencimiento.replace(" ", "").split("/")
        mes, anio = int(mes_txt), int(anio_txt)
    except ValueError:
        raise HTTPException(status_code=422, detail="Vencimiento no válido (usa MM/AA)")
    if anio < 100:
        anio += 2000
    if not 1 <= mes <= 12:
        raise HTTPException(status_code=422, detail="Mes de vencimiento no válido")
    hoy = datetime.now()
    if (anio, mes) < (hoy.year, hoy.month):
        raise HTTPException(status_code=422, detail="La tarjeta está vencida")

    if not tarjeta.cvv.isdigit():
        raise HTTPException(status_code=422, detail="CVV no válido")

    if numero == TARJETA_RECHAZADA:
        raise HTTPException(
            status_code=402,
            detail="Pago rechazado por el banco: fondos insuficientes",
        )
    return numero[-4:]


# ----------------------------------------------------------------------
# Catálogo de productos
# ----------------------------------------------------------------------
@router.get("/productos", response_model=list[ProductoRespuesta])
def listar_productos(
    todos: bool = False,
    db: Session = Depends(obtener_sesion),
    usuario: Usuario = Depends(usuario_actual),
):
    """Productos activos. Un administrador puede ver también los inactivos (?todos=true)."""
    consulta = select(Producto)
    if not (todos and usuario.tip_usu == ADMIN):
        consulta = consulta.where(Producto.activo.is_(True))
    consulta = consulta.order_by(Producto.categoria, Producto.nombre)
    return [_producto_a_respuesta(p) for p in db.scalars(consulta).all()]


@router.get("/productos/{prod_id}", response_model=ProductoRespuesta)
def obtener_producto(
    prod_id: int,
    db: Session = Depends(obtener_sesion),
    _usuario: Usuario = Depends(usuario_actual),
):
    return _producto_a_respuesta(_producto_o_404(db, prod_id))


@router.post("/productos", response_model=ProductoRespuesta, status_code=201)
def crear_producto(
    datos: ProductoGuardar,
    db: Session = Depends(obtener_sesion),
    _admin: Usuario = Depends(solo_admin),
):
    producto = Producto(
        nombre=datos.nombre.strip(),
        descripcion=(datos.descripcion or "").strip() or None,
        precio=Decimal(str(round(datos.precio, 2))),
        img=(datos.img or "").strip() or None,
        categoria=(datos.categoria or "").strip() or None,
        stock=datos.stock,
        activo=datos.activo,
    )
    db.add(producto)
    db.commit()
    db.refresh(producto)
    return _producto_a_respuesta(producto)


@router.put("/productos/{prod_id}", response_model=ProductoRespuesta)
def actualizar_producto(
    prod_id: int,
    datos: ProductoGuardar,
    db: Session = Depends(obtener_sesion),
    _admin: Usuario = Depends(solo_admin),
):
    producto = _producto_o_404(db, prod_id)
    producto.nombre = datos.nombre.strip()
    producto.descripcion = (datos.descripcion or "").strip() or None
    producto.precio = Decimal(str(round(datos.precio, 2)))
    producto.img = (datos.img or "").strip() or None
    producto.categoria = (datos.categoria or "").strip() or None
    producto.stock = datos.stock
    producto.activo = datos.activo
    db.commit()
    db.refresh(producto)
    return _producto_a_respuesta(producto)


@router.delete("/productos/{prod_id}")
def eliminar_producto(
    prod_id: int,
    db: Session = Depends(obtener_sesion),
    _admin: Usuario = Depends(solo_admin),
):
    # Los pedidos conservan el nombre y precio (prod_id queda en NULL).
    db.delete(_producto_o_404(db, prod_id))
    db.commit()
    return {"mensaje": "Producto eliminado"}


# ----------------------------------------------------------------------
# Carrito de compras (guardado en la BD, por usuario)
# ----------------------------------------------------------------------
@router.get("/carrito", response_model=CarritoRespuesta)
def ver_carrito(
    db: Session = Depends(obtener_sesion),
    usuario: Usuario = Depends(usuario_actual),
):
    return _carrito(db, usuario)


@router.post("/carrito", response_model=CarritoRespuesta)
def agregar_al_carrito(
    datos: CarritoAgregar,
    db: Session = Depends(obtener_sesion),
    usuario: Usuario = Depends(usuario_actual),
):
    producto = _producto_o_404(db, datos.prod_id)
    if not producto.activo:
        raise HTTPException(status_code=400, detail="Este producto no está disponible")

    item = db.scalar(
        select(CarritoItem).where(
            CarritoItem.usr_id == usuario.id_usr,
            CarritoItem.prod_id == datos.prod_id,
        )
    )
    nueva_cantidad = datos.cantidad + (item.cantidad if item else 0)
    if nueva_cantidad > producto.stock:
        raise HTTPException(
            status_code=400,
            detail=f"Solo hay {producto.stock} disponibles de {producto.nombre}",
        )
    if item is None:
        db.add(CarritoItem(usr_id=usuario.id_usr, prod_id=datos.prod_id, cantidad=nueva_cantidad))
    else:
        item.cantidad = nueva_cantidad
    db.commit()
    return _carrito(db, usuario)


@router.put("/carrito/{prod_id}", response_model=CarritoRespuesta)
def cambiar_cantidad(
    prod_id: int,
    datos: CarritoCantidad,
    db: Session = Depends(obtener_sesion),
    usuario: Usuario = Depends(usuario_actual),
):
    item = db.scalar(
        select(CarritoItem).where(
            CarritoItem.usr_id == usuario.id_usr, CarritoItem.prod_id == prod_id
        )
    )
    if item is None:
        raise HTTPException(status_code=404, detail="El producto no está en tu carrito")
    if datos.cantidad > item.producto.stock:
        raise HTTPException(
            status_code=400,
            detail=f"Solo hay {item.producto.stock} disponibles",
        )
    item.cantidad = datos.cantidad
    db.commit()
    return _carrito(db, usuario)


@router.delete("/carrito/{prod_id}", response_model=CarritoRespuesta)
def quitar_del_carrito(
    prod_id: int,
    db: Session = Depends(obtener_sesion),
    usuario: Usuario = Depends(usuario_actual),
):
    item = db.scalar(
        select(CarritoItem).where(
            CarritoItem.usr_id == usuario.id_usr, CarritoItem.prod_id == prod_id
        )
    )
    if item is not None:
        db.delete(item)
        db.commit()
    return _carrito(db, usuario)


@router.delete("/carrito", response_model=CarritoRespuesta)
def vaciar_carrito(
    db: Session = Depends(obtener_sesion),
    usuario: Usuario = Depends(usuario_actual),
):
    for item in db.scalars(select(CarritoItem).where(CarritoItem.usr_id == usuario.id_usr)):
        db.delete(item)
    db.commit()
    return _carrito(db, usuario)


# ----------------------------------------------------------------------
# Pago (checkout) y pedidos
# ----------------------------------------------------------------------
@router.post("/pedidos/checkout", response_model=PedidoRespuesta, status_code=201)
def pagar(
    datos: CheckoutRequest,
    db: Session = Depends(obtener_sesion),
    usuario: Usuario = Depends(usuario_actual),
):
    items = db.scalars(
        select(CarritoItem).where(CarritoItem.usr_id == usuario.id_usr)
    ).all()
    if not items:
        raise HTTPException(status_code=400, detail="Tu carrito está vacío")

    # 1) Revisar disponibilidad (bloqueando las filas de producto)
    total = Decimal("0")
    for item in items:
        producto = db.scalar(
            select(Producto).where(Producto.id_prod == item.prod_id).with_for_update()
        )
        if not producto.activo:
            raise HTTPException(status_code=400, detail=f"{producto.nombre} ya no está disponible")
        if item.cantidad > producto.stock:
            raise HTTPException(
                status_code=400,
                detail=f"Solo quedan {producto.stock} de {producto.nombre}",
            )
        total += producto.precio * item.cantidad

    # 2) Cobrar (simulado)
    ultimos4 = None
    if datos.metodo_pago == "tarjeta":
        if datos.tarjeta is None:
            raise HTTPException(status_code=422, detail="Faltan los datos de la tarjeta")
        ultimos4 = _procesar_pago_simulado(datos.tarjeta)
        estatus = "pagado"
    else:
        estatus = "pendiente_pago"  # paga en efectivo al recibir / recoger

    # 3) Crear pedido, descontar inventario y vaciar carrito
    pedido = Pedido(
        usr_id=usuario.id_usr,
        total=total,
        estatus=estatus,
        direccion_envio=datos.direccion_envio.strip(),
        telefono=(datos.telefono or "").strip() or None,
        metodo_pago=datos.metodo_pago,
        referencia_pago="MIMI-" + secrets.token_hex(4).upper(),
        tarjeta_ultimos4=ultimos4,
    )
    db.add(pedido)
    db.flush()
    for item in items:
        producto = item.producto
        db.add(
            PedidoDetalle(
                ped_id=pedido.id_ped,
                prod_id=producto.id_prod,
                nombre=producto.nombre,
                precio_unitario=producto.precio,
                cantidad=item.cantidad,
            )
        )
        producto.stock -= item.cantidad
        db.delete(item)
    db.commit()
    db.refresh(pedido)
    return _pedido_a_respuesta(pedido)


@router.get("/pedidos", response_model=list[PedidoRespuesta])
def listar_pedidos(
    todos: bool = False,
    db: Session = Depends(obtener_sesion),
    usuario: Usuario = Depends(usuario_actual),
):
    """Mis pedidos. Un administrador puede ver todos con ?todos=true."""
    consulta = select(Pedido)
    if not (todos and usuario.tip_usu == ADMIN):
        consulta = consulta.where(Pedido.usr_id == usuario.id_usr)
    consulta = consulta.order_by(Pedido.fecha.desc(), Pedido.id_ped.desc())
    return [_pedido_a_respuesta(p) for p in db.scalars(consulta).all()]


@router.get("/pedidos/{ped_id}", response_model=PedidoRespuesta)
def obtener_pedido(
    ped_id: int,
    db: Session = Depends(obtener_sesion),
    usuario: Usuario = Depends(usuario_actual),
):
    pedido = db.get(Pedido, ped_id)
    if pedido is None or (pedido.usr_id != usuario.id_usr and usuario.tip_usu != ADMIN):
        raise HTTPException(status_code=404, detail="Pedido no encontrado")
    return _pedido_a_respuesta(pedido)


@router.put("/pedidos/{ped_id}/estatus", response_model=PedidoRespuesta)
def cambiar_estatus(
    ped_id: int,
    datos: PedidoEstatus,
    db: Session = Depends(obtener_sesion),
    _admin: Usuario = Depends(solo_admin),
):
    pedido = db.get(Pedido, ped_id)
    if pedido is None:
        raise HTTPException(status_code=404, detail="Pedido no encontrado")

    # Si se cancela, el inventario regresa.
    if datos.estatus == "cancelado" and pedido.estatus != "cancelado":
        for d in pedido.detalles:
            if d.prod_id is not None:
                producto = db.get(Producto, d.prod_id)
                if producto is not None:
                    producto.stock += d.cantidad
    pedido.estatus = datos.estatus
    db.commit()
    db.refresh(pedido)
    return _pedido_a_respuesta(pedido)


@router.post("/pedidos/{ped_id}/cancelar", response_model=PedidoRespuesta)
def cancelar_mi_pedido(
    ped_id: int,
    db: Session = Depends(obtener_sesion),
    usuario: Usuario = Depends(usuario_actual),
):
    """El cliente puede cancelar mientras el pedido no se haya enviado."""
    pedido = db.get(Pedido, ped_id)
    if pedido is None or pedido.usr_id != usuario.id_usr:
        raise HTTPException(status_code=404, detail="Pedido no encontrado")
    if pedido.estatus not in ("pagado", "pendiente_pago"):
        raise HTTPException(
            status_code=400,
            detail="Ya no se puede cancelar: el pedido está en preparación o enviado",
        )
    for d in pedido.detalles:
        if d.prod_id is not None:
            producto = db.get(Producto, d.prod_id)
            if producto is not None:
                producto.stock += d.cantidad
    pedido.estatus = "cancelado"
    db.commit()
    db.refresh(pedido)
    return _pedido_a_respuesta(pedido)
