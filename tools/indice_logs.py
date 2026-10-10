# -*- coding: utf-8 -*-
"""
Genera logs/INDICE_LOGS.md a partir de los logs individuales de cada integrante.

Uso:
    python tools/indice_logs.py

Por qué existe:
    Cada integrante edita SOLO su archivo logs/<nombre>.md, así que sus commits
    nunca pisan los de los demás. El índice se genera automáticamente para que
    nadie tenga que editarlo a mano (editar a mano sí causaría conflictos).

El índice es determinista: con los mismos logs de entrada produce siempre el
mismo resultado, así que si hay un conflicto en INDICE_LOGS.md basta con
re-ejecutar este script sobre la versión fusionada.
"""
import pathlib
import re
import sys

BASE = pathlib.Path(__file__).resolve().parent.parent
LOGS_DIR = BASE / "logs"
OUT = LOGS_DIR / "INDICE_LOGS.md"

# Integrantes del equipo: (nombre visible, archivo en logs/)
MIEMBROS = [
    ("Nicolas Buelvas", "nicolas-buelvas.md"),
    ("Stiven Valencia", "stiven-valencia.md"),
    ("Sebastian Marquez", "sebastian-marquez.md"),
    ("Carol Mosquera", "carol-mosquera.md"),
]

ENTRY_RE = re.compile(r"^##\s+(AI-\S+)", re.MULTILINE)
TS_RE = re.compile(r"^Timestamp:\s*(.+)$", re.MULTILINE | re.IGNORECASE)


def parse_log(path: pathlib.Path):
    """Devuelve (entradas, ids, timestamp de la última entrada)."""
    if not path.exists():
        return 0, [], "—"
    text = path.read_text(encoding="utf-8")
    ids = ENTRY_RE.findall(text)
    last_ts = "—"
    if ids:
        # timestamp del último bloque de entrada
        last_block = text.rsplit("## ", 1)[-1]
        m = TS_RE.search(last_block)
        if m:
            last_ts = m.group(1).strip()
    return len(ids), ids, last_ts


def build_index() -> str:
    lines = [
        "# ÍNDICE DE LOGS",
        "",
        "> **Archivo generado automáticamente.** No lo edites a mano:",
        "> ejecuta `python tools/indice_logs.py` para regenerarlo.",
        "> Cada integrante solo edita su propio archivo en `logs/`,",
        "> así que los cambios de uno no pisan los de otro (cero conflictos).",
        "",
        "| Integrante | Archivo | Entradas | Última entrada | Hora última |",
        "| :--- | :--- | --: | :--- | :--- |",
    ]

    total = 0
    for nombre, fname in MIEMBROS:
        n, ids, ts = parse_log(LOGS_DIR / fname)
        total += n
        ultima = ids[-1] if ids else "—"
        lines.append(f"| {nombre} | [{fname}]({fname}) | {n} | {ultima} | {ts} |")

    lines += [
        "",
        f"**Total de entradas:** {total}",
        "",
        "## Cómo agregar tu log",
        "",
        "1. Agrega una entrada al **final** de tu archivo `logs/<tu-nombre>.md`.",
        "2. Usa el formato del Anexo A del protocolo (`AI_IAdashems-<INICIAL>-000001`).",
        "3. Ejecuta `python tools/indice_logs.py` para refrescar este índice.",
        "4. Haz commit de **tu archivo + el índice**.",
        "",
        "> Si Git reporta conflicto en `INDICE_LOGS.md`, resúelo ejecutando",
        "> `python tools/indice_logs.py` sobre la versión fusionada y guardando el resultado.",
        "",
    ]
    return "\n".join(lines)


def main():
    if not LOGS_DIR.exists():
        sys.exit(f"No existe el directorio {LOGS_DIR}")
    OUT.write_text(build_index(), encoding="utf-8")
    print(f"[ok] Índice generado: {OUT}")


if __name__ == "__main__":
    main()
