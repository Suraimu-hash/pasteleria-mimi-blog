"""Módulo de mensajería interna: chat privado entre usuarios registrados."""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import and_, func, or_, select, update
from sqlalchemy.orm import Session

from database import obtener_sesion
from models import Mensaje, Usuario
from schemas import (
    ContactoRespuesta,
    ConversacionRespuesta,
    MensajeCrear,
    MensajeRespuesta,
)
from security import ADMIN, usuario_actual

router = APIRouter(tags=["Mensajería"])


def _a_respuesta(m: Mensaje) -> MensajeRespuesta:
    return MensajeRespuesta(
        id_msg=m.id_msg,
        texto=m.texto,
        fecha=m.fecha,
        leido=bool(m.leido),
        remitente_id=m.remitente_id,
        destinatario_id=m.destinatario_id,
    )


def _entre(a: int, b: int):
    return or_(
        and_(Mensaje.remitente_id == a, Mensaje.destinatario_id == b),
        and_(Mensaje.remitente_id == b, Mensaje.destinatario_id == a),
    )


@router.get("/contactos", response_model=list[ContactoRespuesta])
def listar_contactos(
    db: Session = Depends(obtener_sesion),
    usuario: Usuario = Depends(usuario_actual),
):
    """Usuarios a los que se les puede escribir (solo nombre y rol, sin correo)."""
    usuarios = db.scalars(
        select(Usuario)
        .where(Usuario.id_usr != usuario.id_usr)
        .order_by(Usuario.tip_usu, Usuario.nom_usr)
    ).all()
    return [
        ContactoRespuesta(id_usr=u.id_usr, nom_usr=u.nom_usr, tip_usu=u.tip_usu)
        for u in usuarios
    ]


@router.get("/mensajes/conversaciones", response_model=list[ConversacionRespuesta])
def listar_conversaciones(
    db: Session = Depends(obtener_sesion),
    usuario: Usuario = Depends(usuario_actual),
):
    yo = usuario.id_usr
    mensajes = db.scalars(
        select(Mensaje)
        .where(or_(Mensaje.remitente_id == yo, Mensaje.destinatario_id == yo))
        .order_by(Mensaje.fecha.desc(), Mensaje.id_msg.desc())
    ).all()

    conversaciones: dict[int, ConversacionRespuesta] = {}
    for m in mensajes:
        otro = m.destinatario_id if m.remitente_id == yo else m.remitente_id
        if otro not in conversaciones:
            u = db.get(Usuario, otro)
            if u is None:
                continue
            conversaciones[otro] = ConversacionRespuesta(
                usuario_id=otro,
                nombre=u.nom_usr,
                es_admin=u.tip_usu == ADMIN,
                ultimo_mensaje=("Tú: " if m.remitente_id == yo else "") + m.texto,
                fecha=m.fecha,
                no_leidos=0,
            )
        if m.destinatario_id == yo and not m.leido:
            conversaciones[otro].no_leidos += 1
    return list(conversaciones.values())


@router.get("/mensajes/no-leidos")
def contar_no_leidos(
    db: Session = Depends(obtener_sesion),
    usuario: Usuario = Depends(usuario_actual),
):
    total = db.scalar(
        select(func.count(Mensaje.id_msg)).where(
            Mensaje.destinatario_id == usuario.id_usr, Mensaje.leido.is_(False)
        )
    )
    return {"no_leidos": total or 0}


@router.get("/mensajes/{otro_id}", response_model=list[MensajeRespuesta])
def ver_conversacion(
    otro_id: int,
    despues_de: int = 0,
    db: Session = Depends(obtener_sesion),
    usuario: Usuario = Depends(usuario_actual),
):
    """Mensajes con otro usuario. Con ?despues_de=<id_msg> solo trae los nuevos.
    Marca como leídos los mensajes recibidos."""
    if db.get(Usuario, otro_id) is None:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")

    consulta = select(Mensaje).where(_entre(usuario.id_usr, otro_id))
    if despues_de:
        consulta = consulta.where(Mensaje.id_msg > despues_de)
    mensajes = db.scalars(consulta.order_by(Mensaje.id_msg.asc())).all()

    db.execute(
        update(Mensaje)
        .where(
            Mensaje.remitente_id == otro_id,
            Mensaje.destinatario_id == usuario.id_usr,
            Mensaje.leido.is_(False),
        )
        .values(leido=True)
    )
    db.commit()
    return [_a_respuesta(m) for m in mensajes]


@router.post("/mensajes/{otro_id}", response_model=MensajeRespuesta, status_code=201)
def enviar_mensaje(
    otro_id: int,
    datos: MensajeCrear,
    db: Session = Depends(obtener_sesion),
    usuario: Usuario = Depends(usuario_actual),
):
    if otro_id == usuario.id_usr:
        raise HTTPException(status_code=400, detail="No puedes enviarte mensajes a ti")
    if db.get(Usuario, otro_id) is None:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    texto = datos.texto.strip()
    if not texto:
        raise HTTPException(status_code=422, detail="El mensaje no puede estar vacío")

    mensaje = Mensaje(
        texto=texto,
        remitente_id=usuario.id_usr,
        destinatario_id=otro_id,
        leido=False,
    )
    db.add(mensaje)
    db.commit()
    db.refresh(mensaje)
    return _a_respuesta(mensaje)
