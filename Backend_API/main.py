from fastapi import Depends, FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

import models  # noqa: F401  (registra las tablas)
from database import Base, engine, migrar_columnas, obtener_sesion
from models import Blog, Comentario, ReaccionComentario, Usuario, Valoracion
from schemas import (
    BlogCrear,
    BlogRespuesta,
    ComentarioCrear,
    ComentarioRespuesta,
    LoginRequest,
    LoginRespuesta,
    ReaccionCrear,
    ReaccionResumen,
    UsuarioActualizar,
    UsuarioCrear,
    UsuarioRespuesta,
    ValoracionCrear,
)
from security import (
    ADMIN,
    CLIENTE,
    crear_token,
    hashear_password,
    solo_admin,
    usuario_actual,
    usuario_opcional,
    verificar_password,
)

import mensajes
import tienda

# Crea las tablas si aún no existen (bd.sql también las crea).
Base.metadata.create_all(bind=engine)
migrar_columnas()  # agrega 'sticker' si la BD es de la versión anterior

app = FastAPI(
    title="API · Pastelería Mimi (blog de pasteles + tienda)",
    version="2.0.0",
)

# Códigos permitidos (la app los dibuja como emoji / sticker).
REACCIONES = {"me_encanta", "me_gusta", "risa", "wow", "triste", "antojo"}
STICKERS = {
    "delicioso", "quiero_uno", "feliz_cumple", "hermoso",
    "receta", "aplausos", "chef", "corazones",
}

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


# ----------------------------------------------------------------------
# Utilidades
# ----------------------------------------------------------------------
def _blog_a_respuesta(
    db: Session, publicacion: Blog, usuario: Usuario | None = None
) -> BlogRespuesta:
    total = db.scalar(
        select(func.count(Comentario.id_com)).where(
            Comentario.blog_id == publicacion.id_blog,
            Comentario.estatus == 1,
        )
    )
    promedio, num_val = db.execute(
        select(func.avg(Valoracion.estrellas), func.count(Valoracion.id_val)).where(
            Valoracion.blog_id == publicacion.id_blog
        )
    ).one()
    mia = None
    if usuario is not None:
        mia = db.scalar(
            select(Valoracion.estrellas).where(
                Valoracion.blog_id == publicacion.id_blog,
                Valoracion.usr_id == usuario.id_usr,
            )
        )
    return BlogRespuesta(
        id_blog=publicacion.id_blog,
        titulo=publicacion.titulo,
        descripcion=publicacion.descripcion,
        img=publicacion.img,
        tags=publicacion.tags,
        fecha=publicacion.fecha,
        usr_id=publicacion.usr_id,
        autor=publicacion.autor.nom_usr,
        num_comentarios=total or 0,
        promedio_estrellas=round(float(promedio), 1) if promedio else 0,
        num_valoraciones=num_val or 0,
        mi_valoracion=mia,
    )


def _comentario_a_respuesta(
    db: Session, c: Comentario, usuario: Usuario
) -> ComentarioRespuesta:
    filas = db.execute(
        select(ReaccionComentario.tipo, ReaccionComentario.usr_id).where(
            ReaccionComentario.com_id == c.id_com
        )
    ).all()
    resumen: dict[str, ReaccionResumen] = {}
    for tipo, usr_id in filas:
        r = resumen.setdefault(tipo, ReaccionResumen(tipo=tipo, total=0, mia=False))
        r.total += 1
        if usr_id == usuario.id_usr:
            r.mia = True
    return ComentarioRespuesta(
        id_com=c.id_com,
        comentario=c.comentario,
        sticker=c.sticker,
        fecha=c.fecha,
        usr_id=c.usr_id,
        blog_id=c.blog_id,
        nombre_usuario=c.usuario.nom_usr,
        reacciones=sorted(resumen.values(), key=lambda r: -r.total),
    )


def _publicacion_o_404(db: Session, blog_id: int) -> Blog:
    publicacion = db.get(Blog, blog_id)
    if publicacion is None:
        raise HTTPException(status_code=404, detail="Publicación no encontrada")
    return publicacion


@app.get("/")
def inicio():
    return {"mensaje": "API de Pastelería Mimi funcionando", "docs": "/docs"}


# ----------------------------------------------------------------------
# Sesión
# ----------------------------------------------------------------------
@app.post("/login", response_model=LoginRespuesta)
def iniciar_sesion(
    datos: LoginRequest,
    db: Session = Depends(obtener_sesion),
):
    correo = datos.mail.strip().lower()
    usuario = db.scalar(select(Usuario).where(Usuario.mail == correo))

    # Mismo mensaje para correo inexistente y contraseña incorrecta:
    # no revela si el correo está registrado.
    if usuario is None or not verificar_password(datos.password, usuario.pass_hash):
        raise HTTPException(status_code=401, detail="Correo o contraseña incorrectos")

    return LoginRespuesta(
        access_token=crear_token(usuario),
        usuario=UsuarioRespuesta.model_validate(usuario),
    )


@app.get("/me", response_model=UsuarioRespuesta)
def mi_usuario(usuario: Usuario = Depends(usuario_actual)):
    return usuario


# ----------------------------------------------------------------------
# Usuarios
# ----------------------------------------------------------------------
@app.post("/usuarios", response_model=UsuarioRespuesta, status_code=201)
def crear_usuario(
    datos: UsuarioCrear,
    db: Session = Depends(obtener_sesion),
    quien_llama: Usuario | None = Depends(usuario_opcional),
):
    """Registro público: cualquiera puede crear una cuenta de cliente.

    Solo un administrador con sesión iniciada puede crear otro administrador;
    en cualquier otro caso el tipo se fuerza a CLIENTE.
    """
    es_admin = quien_llama is not None and quien_llama.tip_usu == ADMIN
    tipo = datos.tip_usu if es_admin else CLIENTE

    usuario = Usuario(
        nom_usr=datos.nom_usr.strip(),
        mail=datos.mail.strip().lower(),
        pass_hash=hashear_password(datos.password),
        dir_usr=datos.dir_usr,
        tip_usu=tipo,
    )
    db.add(usuario)
    try:
        db.commit()
        db.refresh(usuario)
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=409, detail="El correo ya está registrado")
    return usuario


@app.get("/usuarios", response_model=list[UsuarioRespuesta])
def listar_usuarios(
    db: Session = Depends(obtener_sesion),
    _admin: Usuario = Depends(solo_admin),
):
    return db.scalars(select(Usuario).order_by(Usuario.id_usr)).all()


@app.put("/usuarios/{usuario_id}", response_model=UsuarioRespuesta)
def actualizar_usuario(
    usuario_id: int,
    datos: UsuarioActualizar,
    db: Session = Depends(obtener_sesion),
    quien_llama: Usuario = Depends(usuario_actual),
):
    es_admin = quien_llama.tip_usu == ADMIN
    if not es_admin and quien_llama.id_usr != usuario_id:
        raise HTTPException(status_code=403, detail="Solo puedes editar tu propio perfil")

    usuario = db.get(Usuario, usuario_id)
    if usuario is None:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")

    usuario.nom_usr = datos.nom_usr.strip()
    usuario.mail = datos.mail.strip().lower()
    usuario.dir_usr = datos.dir_usr
    if es_admin:  # solo un administrador puede cambiar el rol
        usuario.tip_usu = datos.tip_usu

    try:
        db.commit()
        db.refresh(usuario)
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=409, detail="El correo ya está registrado")
    return usuario


@app.delete("/usuarios/{usuario_id}")
def eliminar_usuario(
    usuario_id: int,
    db: Session = Depends(obtener_sesion),
    admin: Usuario = Depends(solo_admin),
):
    if usuario_id == admin.id_usr:
        raise HTTPException(status_code=400, detail="No puedes eliminar tu propia cuenta")

    usuario = db.get(Usuario, usuario_id)
    if usuario is None:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")

    db.delete(usuario)  # sus publicaciones y comentarios se eliminan en cascada
    db.commit()
    return {"mensaje": "Usuario eliminado correctamente"}


# ----------------------------------------------------------------------
# Blog de pasteles
# ----------------------------------------------------------------------
@app.get("/blog", response_model=list[BlogRespuesta])
def listar_blog(
    mias: bool = False,
    db: Session = Depends(obtener_sesion),
    usuario: Usuario = Depends(usuario_actual),
):
    """Todas las publicaciones, o solo las propias con ?mias=true."""
    consulta = select(Blog)
    if mias:
        consulta = consulta.where(Blog.usr_id == usuario.id_usr)
    consulta = consulta.order_by(Blog.fecha.desc(), Blog.id_blog.desc())
    return [_blog_a_respuesta(db, p, usuario) for p in db.scalars(consulta).all()]


@app.get("/blog/{blog_id}", response_model=BlogRespuesta)
def obtener_blog(
    blog_id: int,
    db: Session = Depends(obtener_sesion),
    usuario: Usuario = Depends(usuario_actual),
):
    return _blog_a_respuesta(db, _publicacion_o_404(db, blog_id), usuario)


@app.post("/blog", response_model=BlogRespuesta, status_code=201)
def crear_blog(
    datos: BlogCrear,
    db: Session = Depends(obtener_sesion),
    usuario: Usuario = Depends(usuario_actual),
):
    titulo = datos.titulo.strip()
    descripcion = datos.descripcion.strip()
    if not titulo:
        raise HTTPException(status_code=422, detail="El título no puede estar vacío")
    if not descripcion:
        raise HTTPException(status_code=422, detail="La descripción no puede estar vacía")

    publicacion = Blog(
        titulo=titulo,
        descripcion=descripcion,
        img=datos.img.strip() if datos.img and datos.img.strip() else None,
        tags=datos.tags.strip() if datos.tags and datos.tags.strip() else None,
        usr_id=usuario.id_usr,  # el autor sale de la sesión, no lo envía el cliente
    )
    db.add(publicacion)
    db.commit()
    db.refresh(publicacion)
    return _blog_a_respuesta(db, publicacion, usuario)


@app.delete("/blog/{blog_id}")
def eliminar_blog(
    blog_id: int,
    db: Session = Depends(obtener_sesion),
    usuario: Usuario = Depends(usuario_actual),
):
    publicacion = _publicacion_o_404(db, blog_id)
    if publicacion.usr_id != usuario.id_usr and usuario.tip_usu != ADMIN:
        raise HTTPException(
            status_code=403,
            detail="Solo el autor o un administrador puede eliminarla",
        )
    db.delete(publicacion)
    db.commit()
    return {"mensaje": "Publicación eliminada"}


# ----------------------------------------------------------------------
# Valoraciones (estrellas 1–5, una por usuario y publicación)
# ----------------------------------------------------------------------
@app.put("/blog/{blog_id}/valoracion", response_model=BlogRespuesta)
def valorar_blog(
    blog_id: int,
    datos: ValoracionCrear,
    db: Session = Depends(obtener_sesion),
    usuario: Usuario = Depends(usuario_actual),
):
    """Crea o actualiza la calificación del usuario en sesión."""
    publicacion = _publicacion_o_404(db, blog_id)
    valoracion = db.scalar(
        select(Valoracion).where(
            Valoracion.blog_id == blog_id, Valoracion.usr_id == usuario.id_usr
        )
    )
    if valoracion is None:
        db.add(Valoracion(blog_id=blog_id, usr_id=usuario.id_usr, estrellas=datos.estrellas))
    else:
        valoracion.estrellas = datos.estrellas
    db.commit()
    return _blog_a_respuesta(db, publicacion, usuario)


@app.delete("/blog/{blog_id}/valoracion", response_model=BlogRespuesta)
def quitar_valoracion(
    blog_id: int,
    db: Session = Depends(obtener_sesion),
    usuario: Usuario = Depends(usuario_actual),
):
    publicacion = _publicacion_o_404(db, blog_id)
    valoracion = db.scalar(
        select(Valoracion).where(
            Valoracion.blog_id == blog_id, Valoracion.usr_id == usuario.id_usr
        )
    )
    if valoracion is not None:
        db.delete(valoracion)
        db.commit()
    return _blog_a_respuesta(db, publicacion, usuario)


# ----------------------------------------------------------------------
# Comentarios
# ----------------------------------------------------------------------
@app.get("/blog/{blog_id}/comentarios", response_model=list[ComentarioRespuesta])
def listar_comentarios(
    blog_id: int,
    db: Session = Depends(obtener_sesion),
    usuario: Usuario = Depends(usuario_actual),
):
    _publicacion_o_404(db, blog_id)
    comentarios = db.scalars(
        select(Comentario)
        .where(Comentario.blog_id == blog_id, Comentario.estatus == 1)
        .order_by(Comentario.fecha.asc(), Comentario.id_com.asc())
    ).all()
    return [_comentario_a_respuesta(db, c, usuario) for c in comentarios]


@app.post(
    "/blog/{blog_id}/comentarios",
    response_model=ComentarioRespuesta,
    status_code=201,
)
def crear_comentario(
    blog_id: int,
    datos: ComentarioCrear,
    db: Session = Depends(obtener_sesion),
    usuario: Usuario = Depends(usuario_actual),
):
    _publicacion_o_404(db, blog_id)
    texto = datos.comentario.strip()
    sticker = datos.sticker.strip() if datos.sticker else None
    if sticker and sticker not in STICKERS:
        raise HTTPException(status_code=422, detail="Sticker no válido")
    if not texto and not sticker:
        raise HTTPException(
            status_code=422, detail="Escribe un comentario o elige un sticker"
        )

    nuevo = Comentario(
        comentario=texto,
        sticker=sticker,
        usr_id=usuario.id_usr,
        blog_id=blog_id,
        estatus=1,
    )
    db.add(nuevo)
    db.commit()
    db.refresh(nuevo)
    return _comentario_a_respuesta(db, nuevo, usuario)


@app.delete("/comentarios/{comentario_id}")
def eliminar_comentario(
    comentario_id: int,
    db: Session = Depends(obtener_sesion),
    usuario: Usuario = Depends(usuario_actual),
):
    comentario = db.get(Comentario, comentario_id)
    if comentario is None:
        raise HTTPException(status_code=404, detail="Comentario no encontrado")
    if comentario.usr_id != usuario.id_usr and usuario.tip_usu != ADMIN:
        raise HTTPException(
            status_code=403,
            detail="Solo el autor o un administrador puede eliminarlo",
        )
    db.delete(comentario)
    db.commit()
    return {"mensaje": "Comentario eliminado"}


# ----------------------------------------------------------------------
# Reacciones a comentarios (emojis)
# ----------------------------------------------------------------------
@app.post("/comentarios/{comentario_id}/reacciones", response_model=ComentarioRespuesta)
def alternar_reaccion(
    comentario_id: int,
    datos: ReaccionCrear,
    db: Session = Depends(obtener_sesion),
    usuario: Usuario = Depends(usuario_actual),
):
    """Pone la reacción si no existía; la quita si ya estaba (toggle)."""
    if datos.tipo not in REACCIONES:
        raise HTTPException(status_code=422, detail="Reacción no válida")
    comentario = db.get(Comentario, comentario_id)
    if comentario is None or comentario.estatus != 1:
        raise HTTPException(status_code=404, detail="Comentario no encontrado")

    existente = db.scalar(
        select(ReaccionComentario).where(
            ReaccionComentario.com_id == comentario_id,
            ReaccionComentario.usr_id == usuario.id_usr,
            ReaccionComentario.tipo == datos.tipo,
        )
    )
    if existente is None:
        db.add(ReaccionComentario(com_id=comentario_id, usr_id=usuario.id_usr, tipo=datos.tipo))
    else:
        db.delete(existente)
    try:
        db.commit()
    except IntegrityError:  # doble toque muy rápido
        db.rollback()
    return _comentario_a_respuesta(db, comentario, usuario)


# Módulos en archivos aparte
app.include_router(tienda.router)
app.include_router(mensajes.router)
