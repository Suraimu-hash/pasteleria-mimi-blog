"""Carga datos de ejemplo: usuarios, pasteles, comentarios, valoraciones,
reacciones, stickers, productos de la tienda y mensajes.

Uso (con el .env configurado y la BD creada con bd.sql):
    python seed.py

Es seguro ejecutarlo varias veces: cada bloque solo se carga si aún no existe
(así también agrega la tienda y los mensajes a una BD que ya tenía el blog).
Las contraseñas de ejemplo son SOLO para desarrollo; cámbialas en producción.
"""
from decimal import Decimal

from sqlalchemy import select

import models  # noqa: F401
from database import Base, SessionLocal, engine, migrar_columnas

from models import (
    Blog, Comentario, Mensaje, Producto, ReaccionComentario, Usuario, Valoracion,
)
from security import hashear_password

Base.metadata.create_all(bind=engine)
migrar_columnas()


def foto(palabras: str, n: int) -> str:
    # Imágenes de ejemplo por palabra clave. Puedes reemplazarlas por tus propias URLs.
    return f"https://loremflickr.com/800/500/{palabras}/all?lock={n}"


# (nombre, correo, contraseña, dirección, tipo)  tipo: 1 = admin, 2 = cliente
USUARIOS = [
    ("Pastelería Mimi", "admin@pasteleriamimi.com", "Admin12345", "Querétaro", 1),
    ("Adriana Contreras", "adriana@ejemplo.com", "Cliente12345", "Querétaro", 2),
    ("Carlos Pérez", "carlos@ejemplo.com", "Cliente12345", "Querétaro", 2),
]

# (índice del autor, título, descripción, imagen, etiquetas)
PASTELES = [
    (0, "Pastel de chocolate intenso",
     "Bizcocho húmedo de chocolate amargo, relleno de ganache y cubierto con "
     "buttercream de chocolate. Nuestro favorito para cumpleaños: sabor profundo, "
     "textura suave y un acabado brillante.",
     foto("cake,chocolate", 11), "Chocolate,Cumpleaños"),
    (0, "Red velvet con crema de queso",
     "Clásico bizcocho rojo aterciopelado con relleno y cobertura de queso crema. "
     "Ideal para aniversarios y ocasiones románticas. Se decora con migajas y fresas.",
     foto("cake,redvelvet", 12), "Red velvet,Aniversario"),
    (0, "Pastel de tres leches con fresas",
     "Bizcocho de vainilla bañado en tres leches, con crema chantilly y fresas "
     "frescas de temporada. Ligero, jugoso y muy mexicano.",
     foto("cake,strawberry", 13), "Frutas,Tres leches"),
    (0, "Pastel de boda de tres pisos",
     "Tres pisos de vainilla y cajeta con fondant blanco y flores de azúcar. "
     "Personalizamos tamaño, sabores y decoración según tu evento.",
     foto("wedding,cake", 14), "Bodas,Fondant"),
    (1, "Mi primer cheesecake de frutos rojos",
     "Lo hice en casa con base de galleta y cobertura de mermelada de frutos rojos. "
     "¡Quedó cremoso! Lo dejé enfriar toda la noche y fue el éxito de la reunión.",
     foto("cheesecake", 15), "Frutas,Casero"),
    (2, "Pastel de zanahoria sin gluten",
     "Versión con harina de almendra: húmedo, especiado y con nueces. "
     "La cobertura de queso crema le da el toque perfecto.",
     foto("carrot,cake", 16), "Sin gluten,Casero"),
]

# (índice del post, índice del usuario, comentario, sticker)
COMENTARIOS = [
    (0, 1, "¡Se ve delicioso! ¿Se puede pedir sin nueces? 🤤", None),
    (0, 2, "El mejor pastel de chocolate que he probado.", "delicioso"),
    (1, 2, "Me encantó la combinación con el queso crema.", None),
    (2, 1, "Perfecto para el verano, muy ligero. 🍓", None),
    (4, 0, "¡Felicidades por tu primer cheesecake! Se ve increíble.", "aplausos"),
    (5, 1, "¿Me compartes la receta de la cobertura?", "receta"),
]

# (índice del comentario, índice del usuario, tipo de reacción)
REACCIONES = [
    (0, 0, "me_gusta"), (0, 2, "antojo"),
    (1, 0, "me_encanta"), (1, 1, "me_encanta"),
    (4, 1, "me_encanta"), (5, 2, "risa"),
]

# (índice del post, índice del usuario, estrellas)
VALORACIONES = [
    (0, 1, 5), (0, 2, 5), (1, 1, 4), (1, 2, 5), (2, 2, 4),
    (3, 1, 5), (4, 0, 5), (4, 2, 4), (5, 1, 3),
]

# (nombre, descripción, precio, imagen, categoría, stock)
PRODUCTOS = [
    ("Pastel de chocolate intenso (20 personas)",
     "Bizcocho de chocolate amargo con ganache y buttercream de chocolate.",
     "650.00", foto("cake,chocolate", 21), "Pasteles", 8),
    ("Red velvet (15 personas)",
     "Bizcocho rojo aterciopelado con relleno y cobertura de queso crema.",
     "580.00", foto("cake,redvelvet", 22), "Pasteles", 6),
    ("Tres leches con fresas (12 personas)",
     "Vainilla bañada en tres leches, chantilly y fresas frescas.",
     "450.00", foto("cake,strawberry", 23), "Pasteles", 10),
    ("Cheesecake de frutos rojos",
     "Base de galleta, queso crema horneado y mermelada de frutos rojos.",
     "420.00", foto("cheesecake", 24), "Pasteles", 5),
    ("Caja de 6 cupcakes",
     "Surtido de vainilla, chocolate y red velvet con betún de colores.",
     "180.00", foto("cupcakes", 25), "Postres individuales", 20),
    ("Caja de 12 galletas decoradas",
     "Galletas de mantequilla con glaseado real. Diseños de temporada.",
     "220.00", foto("cookies,decorated", 26), "Galletas", 15),
    ("Brownies (6 piezas)",
     "Brownies húmedos con nuez y chispas de chocolate.",
     "150.00", foto("brownies", 27), "Postres individuales", 12),
    ("Velas y topper de cumpleaños",
     "Juego de 10 velas de colores y topper \"Feliz cumpleaños\".",
     "60.00", foto("birthday,candles", 28), "Accesorios", 30),
]

# (remitente, destinatario, texto)
MENSAJES = [
    (1, 0, "Hola, ¿hacen pasteles sin azúcar para un cumpleaños?"),
    (0, 1, "¡Hola Adriana! Sí, con 3 días de anticipación. ¿Para cuántas personas?"),
    (1, 0, "Para 15 personas, el sábado 😊"),
    (2, 1, "Adriana, vi tu cheesecake en el blog, ¡se ve buenísimo!"),
]


def cargar_blog(db) -> None:
    if db.scalar(select(Usuario).where(Usuario.mail == USUARIOS[0][1])):
        print("· Usuarios y blog ya existían.")
        return

    usuarios = []
    for nombre, correo, password, direccion, tipo in USUARIOS:
        u = Usuario(
            nom_usr=nombre,
            mail=correo,
            pass_hash=hashear_password(password),
            dir_usr=direccion,
            tip_usu=tipo,
        )
        db.add(u)
        usuarios.append(u)
    db.flush()

    posts = []
    for autor_idx, titulo, desc, img, tags in PASTELES:
        p = Blog(
            titulo=titulo,
            descripcion=desc,
            img=img,
            tags=tags,
            usr_id=usuarios[autor_idx].id_usr,
        )
        db.add(p)
        posts.append(p)
    db.flush()

    comentarios = []
    for post_idx, usr_idx, texto, sticker in COMENTARIOS:
        c = Comentario(
            comentario=texto,
            sticker=sticker,
            estatus=1,
            usr_id=usuarios[usr_idx].id_usr,
            blog_id=posts[post_idx].id_blog,
        )
        db.add(c)
        comentarios.append(c)
    db.flush()

    for com_idx, usr_idx, tipo in REACCIONES:
        db.add(ReaccionComentario(
            com_id=comentarios[com_idx].id_com,
            usr_id=usuarios[usr_idx].id_usr,
            tipo=tipo,
        ))
    for post_idx, usr_idx, estrellas in VALORACIONES:
        db.add(Valoracion(
            blog_id=posts[post_idx].id_blog,
            usr_id=usuarios[usr_idx].id_usr,
            estrellas=estrellas,
        ))
    print("· Usuarios, pasteles, comentarios, valoraciones y reacciones cargados.")


def cargar_tienda(db) -> None:
    if db.scalar(select(Producto.id_prod).limit(1)):
        print("· La tienda ya tenía productos.")
        return
    for nombre, desc, precio, img, categoria, stock in PRODUCTOS:
        db.add(Producto(
            nombre=nombre, descripcion=desc, precio=Decimal(precio),
            img=img, categoria=categoria, stock=stock, activo=True,
        ))
    print("· Productos de la tienda cargados.")


def cargar_mensajes(db) -> None:
    if db.scalar(select(Mensaje.id_msg).limit(1)):
        print("· Ya había mensajes.")
        return
    ids = []
    for _, correo, *_ in USUARIOS:
        u = db.scalar(select(Usuario).where(Usuario.mail == correo))
        if u is None:
            return
        ids.append(u.id_usr)
    for rem, dest, texto in MENSAJES:
        db.add(Mensaje(
            remitente_id=ids[rem], destinatario_id=ids[dest], texto=texto, leido=False,
        ))
    print("· Mensajes de ejemplo cargados.")


def main() -> None:
    with SessionLocal() as db:
        cargar_blog(db)
        db.flush()
        cargar_tienda(db)
        cargar_mensajes(db)
        db.commit()

    print("Listo.")
    print("  Administrador: admin@pasteleriamimi.com / Admin12345")
    print("  Cliente:       adriana@ejemplo.com / Cliente12345")
    print("  Cliente:       carlos@ejemplo.com / Cliente12345")


if __name__ == "__main__":
    main()



