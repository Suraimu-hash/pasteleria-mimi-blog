"""Seguridad: hash de contraseñas (Argon2), sesiones con JWT y control de acceso por rol."""
import os
from datetime import datetime, timedelta, timezone

import jwt
from dotenv import load_dotenv
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from pwdlib import PasswordHash
from sqlalchemy.orm import Session

from database import obtener_sesion
from models import Usuario

load_dotenv()

SECRET_KEY = os.getenv("SECRET_KEY")
ALGORITHM = "HS256"
EXPIRA_MINUTOS = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "120"))

if not SECRET_KEY:
    raise RuntimeError(
        "Falta SECRET_KEY en el archivo .env (copia .env.example a .env y define una clave)."
    )

ADMIN = 1
CLIENTE = 2

_hasher = PasswordHash.recommended()
_bearer = HTTPBearer(auto_error=False)


# ---------- Contraseñas ----------
def hashear_password(password: str) -> str:
    return _hasher.hash(password)


def verificar_password(password: str, hash_guardado: str) -> bool:
    try:
        return _hasher.verify(password, hash_guardado)
    except Exception:
        return False


# ---------- Tokens ----------
def crear_token(usuario: Usuario) -> str:
    expira = datetime.now(timezone.utc) + timedelta(minutes=EXPIRA_MINUTOS)
    payload = {"sub": str(usuario.id_usr), "exp": expira}
    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)


def _usuario_desde_token(
    credenciales: HTTPAuthorizationCredentials | None, db: Session
) -> Usuario | None:
    if credenciales is None:
        return None
    try:
        payload = jwt.decode(credenciales.credentials, SECRET_KEY, algorithms=[ALGORITHM])
        usuario_id = int(payload.get("sub"))
    except (jwt.PyJWTError, TypeError, ValueError):
        return None
    return db.get(Usuario, usuario_id)


# ---------- Dependencias de FastAPI ----------
def usuario_actual(
    credenciales: HTTPAuthorizationCredentials | None = Depends(_bearer),
    db: Session = Depends(obtener_sesion),
) -> Usuario:
    """Exige sesión iniciada (token válido) y devuelve el usuario."""
    usuario = _usuario_desde_token(credenciales, db)
    if usuario is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Sesión inválida o expirada. Inicia sesión de nuevo.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return usuario


def usuario_opcional(
    credenciales: HTTPAuthorizationCredentials | None = Depends(_bearer),
    db: Session = Depends(obtener_sesion),
) -> Usuario | None:
    """Devuelve el usuario si hay token válido; si no, None (rutas públicas)."""
    return _usuario_desde_token(credenciales, db)


def solo_admin(usuario: Usuario = Depends(usuario_actual)) -> Usuario:
    if usuario.tip_usu != ADMIN:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Esta acción es solo para administradores",
        )
    return usuario
