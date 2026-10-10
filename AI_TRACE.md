# AI TRACE — IAdashems

Registro de trazabilidad del uso de IA (AI Game Jam).

Los agentes operan con [AGENTS.md](AGENTS.md): al terminar una sesión deben appender una entrada en el log del integrante y regenerar el índice.

## Índice de logs

**👉 [logs/INDICE_LOGS.md](logs/INDICE_LOGS.md)**

Cada integrante tiene su **propio archivo de log** en `logs/`, de modo que cada uno
sube sus entradas sin pisar las de los demás y sin generar conflictos de fusión:

| Integrante | Log |
| :--- | :--- |
| Nicolas Buelvas | [logs/nicolas-buelvas.md](logs/nicolas-buelvas.md) |
| Stiven Valencia | [logs/stiven-valencia.md](logs/stiven-valencia.md) |
| Sebastian Marquez | [logs/sebastian-marquez.md](logs/sebastian-marquez.md) |
| Carol Mosquera | [logs/carol-mosquera.md](logs/carol-mosquera.md) |

## Flujo

1. Agrega tu entrada al **final** de **tu** archivo (formato del Anexo A del protocolo).
2. Regenera el índice: `python tools/indice_logs.py`
3. Commitea **tu archivo + `logs/INDICE_LOGS.md`**.

> `logs/INDICE_LOGS.md` es un archivo **generado**: no lo edites a mano.
> Si Git reporta un conflicto ahí, resuelve re-ejecutando el script sobre la versión fusionada.
