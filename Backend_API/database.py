import os

from dotenv import load_dotenv
from sqlalchemy import create_engine, inspect, text
from sqlalchemy.orm import sessionmaker, DeclarativeBase
from sqlalchemy.engine import URL
load_dotenv()
url = URL.create(
    drivername="mysql+pymysql",
    username=os.getenv("DB_USER"),
    password=os.getenv("DB_PASSWORD"),
    host=os.getenv("DB_HOST", "127.0.0.1"),
    port=int(os.getenv("DB_PORT", "3306")),
    database=os.getenv("DB_NAME", "bd_aplicacion_movil"),
    query={"charset": "utf8mb4"},
)
engine = create_engine(url, pool_pre_ping=True)
SessionLocal = sessionmaker(
    bind=engine,
    autocommit=False,
    autoflush=False,
)
class Base(DeclarativeBase):
    pass
def obtener_sesion():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def migrar_columnas() -> None:
    """Agrega columnas nuevas a tablas que ya existían (sin borrar datos).

    Así una BD creada con la versión anterior funciona sin volver a correr bd.sql.
    """
    columnas = {c["name"] for c in inspect(engine).get_columns("comentarios")}
    if "sticker" not in columnas:
        with engine.begin() as con:
            con.execute(text("ALTER TABLE comentarios ADD COLUMN sticker VARCHAR(30) NULL"))
