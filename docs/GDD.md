# Phytophthora infestans
## Game Design Document (versión 0.1)

Fecha: 9 de octubre de 2026

---

## 1. Resumen del proyecto

| Campo | Definición |
|---|---|
| Título | Phytophthora infestans |
| Género | Acción-supervivencia 2.5D |
| Jugadores | 1 (solo) |
| Vista | Lateral, con cámara fija |
| Estilo visual | Cartoon con sprites 2D sobre el motor 3D de Godot |
| Motor y lenguaje | Godot (GDScript). Versión por confirmar |
| Plataforma | PC |
| Controles | Solo teclado |
| Tono | Sátira corporativa |
| Público | Jóvenes y adultos |
| Duración total | Menos de 30 minutos |
| Referencia | Confinement (Roblox), por la mecánica de contención de anomalías |

---

## 2. Concepto y premisa

**Pitch:** Eres una papa empleada que debe contener las anomalías que su propia empresa provoca, antes de que el calor la cocine.

Potato Sans trabaja para Grupo Tubérculo S.A.S., una empresa que genera anomalías dentro de un edificio de oficinas para vender después el servicio de contención. La papa se calienta con el tiempo, con los golpes y con cada anomalía activa. Para sobrevivir, tiene que contener todas las anomalías de cada ronda.

Cada ronda es un turno de trabajo. El juego tiene seis rondas.

---

## 3. Pilares de diseño

- **El calor es tu reloj.** La presión sale de tu propio cuerpo, no de un marcador externo.
- **Cada anomalía exige otra forma de captura.** Tocar, deslizarse y lanzar herbicida se sienten distintos.
- **Contener también enfría.** Capturar es el objetivo y también el alivio, así que cada captura tiene valor.
- **La sátira está en la mecánica.** El negocio de la empresa explica por qué existen las anomalías, no solo los diálogos.
- **Partidas cortas.** Menos de 30 minutos en total para jugar de una sentada.

---

## 4. Controles

| Acción | Tecla |
|---|---|
| Mover | W A S D |
| Saltar | Espacio |
| Deslizarse | Shift |
| Lanzar herbicida | E |
| Pausa | Esc |

- El herbicida apunta en la dirección en la que se mueve la papa.
- No hay línea de trayectoria. Solo se ve el sprite del herbicida en vuelo.
- El menú de opciones no incluye reasignación de teclas.

---

## 5. Elementos del juego

### 5.1 La papa (protagonista)

- **Calor:** medidor que sube con el tiempo, los golpes y las anomalías activas. Si llega al máximo, pierdes.
- **Vida:** 3 golpes. Si llega a 0, pierdes.
- **Movimiento:** caminar, saltar, deslizarse, subir y bajar escaleras.
- **Herbicida:** lanzamiento ilimitado con cooldown de 5 segundos.

### 5.2 Anomalías

| Tipo | Nombre científico | Movimiento | Captura | Daño al contacto |
|---|---|---|---|---|
| Tocar | *Cucumis sativus* (pepino) | Evasiva. Huye de la papa a toda costa. Se frena al subir escaleras. | Tocarla | No |
| Deslizarse | *Lactuca sativa* (lechuga) | Rebota por el escenario | Deslizarse a través de ella (Shift) | Sí, excepto mientras la papa se desliza |
| Herbicida | *Pisum sativum* (guisante), apodo "Lanzaguisantes" | Lenta. Sigue a la papa y le dispara | Un impacto de herbicida | Sí. Sus disparos también causan daño |

- Al contener una anomalía, esta va a un contenedor dentro del piso.
- Los tipos se distinguen por sprite, forma y comportamiento.

### 5.3 Pisos y escaleras

El edificio tiene pisos conectados por escaleras. Se amplía a lo largo de la partida:

- **Piso 1:** rondas 1 y 2.
- **Piso 2:** desde la ronda 3, con mapa y anomalías nuevas.
- **Piso 3:** ronda 6, el piso final.

---

## 6. Sistema de calor

El calor es el núcleo de la presión. Sube y baja con los siguientes factores:

| Factor | Efecto | Intensidad |
|---|---|---|
| Paso del tiempo | Sube | Media. Unos 90 s hasta el máximo sin otros factores |
| Anomalía activa | Sube en toda la ronda | Media por anomalía |
| Golpe recibido | Sube | Media |
| Reloj agotado | Game over del turno | La ronda se reinicia completa |
| Anomalía contenida | Baja de forma gradual | Media |

- **Calor máximo:** game over.
- **Feedback:** el medidor se llena. Con calor alto, la papa suelta humo y vapor.
- Las intensidades son relativas. Los valores exactos se calibran en pruebas.

---

## 7. Vida

- La papa tiene 3 golpes.
- **Fuentes de daño:**
  - Anomalía de herbicida: dispara y causa daño, y también hace daño al contacto.
  - Anomalía de deslizarse: hace daño al contacto, excepto mientras la papa se desliza.
  - Peligros del escenario: trampas y objetos, por definir.
- La anomalía de tocar no hace daño al contacto.
- **Vida en 0:** game over, igual que con el calor máximo.
- **Feedback:** la papa parpadea y suena un golpe corto.

---

## 8. Deslizarse

- Mantén Shift para deslizarte.
- Mientras te deslizas, la papa es **translúcida e invulnerable**.
- Es la única forma de capturar la anomalía de deslizarse: pasas a través de ella.
- Riesgo: también funciona como esquive gratuito (ver sección 18).
- Duración del deslizamiento: por definir.

---

## 9. Herbicida

- Se lanza con **E**, en la dirección del movimiento de la papa.
- Es ilimitado, con cooldown de **5 segundos**.
- El icono del herbicida **tiembla** al quedar listo.
- Contiene a la anomalía de herbicida con **un solo impacto**.

---

## 10. Rondas

| Ronda | Piso | Anomalías | Tipos presentes | Notas |
|---|---|---|---|---|
| 1 | 1 | 1 | Tocar | Ronda corta real, sin tutorial |
| 2 | 1 | 2 | Tocar, deslizarse | Se suma el tipo de la ronda anterior |
| 3 | 2 (nuevo) | 3 | Tocar, deslizarse, herbicida | Se abre el piso 2 con mapa y anomalías nuevas. Primer herbicida |
| 4 | 2 | 4 | Mezcla equilibrada | |
| 5 | 2 | 5 | Mezcla equilibrada | |
| 6 | 3 (final) | 6 | Mezcla equilibrada | Ronda final. Al contener la última anomalía, el edificio explota |

**Reloj de la ronda:** 90 s base + 15 s por cada anomalía restante. Al contener anomalías, el reloj se acorta. Si se agota, es el game over definitivo del turno: la ronda se reinicia completa (todas sus anomalías, reloj, calor y vida).

- Reloj inicial por ronda: 105 s, 120 s, 135 s, 150 s, 165 s y 180 s. El tiempo real será menor, porque el reloj se acorta al contener.
- **Total de anomalías en el juego:** 21.

---

## 11. Flujo del juego

1. Menú principal: Nueva partida y Opciones.
2. Escena de inicio: la papa duerme en su puesto de trabajo y despierta.
3. Rondas 1 a 6.
4. Escena final: al contener la última anomalía de la ronda 6, el edificio explota.
5. Créditos.
6. Menú principal.

- **Sin guardado** entre sesiones. Cada sesión empieza desde el inicio.
- **Muerte** (calor máximo o vida en 0): la papa reaparece con calor 0 y vida llena; se conservan las anomalías ya contenidas y el reloj sigue donde iba.
- **Game over del turno** (reloj agotado): se reinicia la ronda completa: reloj, calor, vida y todas sus anomalías.

---

## 12. Victoria y derrota

- **Ganar una ronda:** contener todas sus anomalías con la papa viva.
- **Perder:** calor al máximo o vida en 0.
- **Ganar el juego:** contener la última anomalía de la ronda 6. Eso dispara la explosión del edificio.
- No hay puntaje ni estadísticas al final.

---

## 13. Interfaz

### 13.1 HUD (durante la ronda)

- Medidor de calor
- Reloj de la ronda
- Vida (3 golpes)
- Contador de anomalías restantes
- Icono de herbicida con su cooldown

### 13.2 Menús

- **Menú principal:** Nueva partida y Opciones. Salir: por definir.
- **Opciones:** volumen (música y efectos por separado) y pantalla y resolución.
- **Pausa (Esc):** opciones y salir de la ronda.

### 13.3 Feedback de propiedades

| Propiedad | Feedback |
|---|---|
| Vida | Parpadeo rojo y sonido corto al recibir un golpe |
| Calor | Medidor que se llena. Humo y vapor con calor alto |
| Invulnerabilidad | Papa translúcida mientras se desliza |
| Herbicida | Icono que tiembla al quedar listo |
| Anomalía contenida | Va a un contenedor dentro del piso |

---

## 14. Arte y estilo visual

- Estilo **cartoon** con sprites 2D.
- Sprites sobre planos en el motor 3D de Godot, con cámara lateral fija.
- Cada tipo de anomalía se distingue por **sprite, forma y comportamiento**.
- Escenario: edificio de oficinas con pisos y escaleras.
- La papa muestra humo con calor alto y se vuelve translúcida al deslizarse.

---

## 15. Audio

- **Música:** corporativa, como un video motivacional de empresa.
- **Efectos:** mezcla de sonidos de oficina y efectos cartoon.
- **Golpe:** sonido corto.
- **Captura de anomalías:** por definir.

---

## 16. Narrativa

- **Empresa:** Grupo Tubérculo S.A.S.
- **Protagonista:** Potato Sans, empleada.
- **Premisa:** la empresa provoca anomalías para vender su servicio de contención.
- **Inicio:** la papa duerme en su puesto de trabajo y despierta.
- **Final:** la explosión del edificio al contener la última anomalía.
- **Cierre:** créditos y menú principal.
- **Diálogos y textos:** por escribir.

---

## 17. Restricciones de diseño

- Un jugador, solo PC, solo teclado.
- Seis rondas y menos de 30 minutos en total.
- Sin guardado entre sesiones.
- Sin power-ups, recompensas ni puntaje.
- Tres tipos de anomalía fijos en la primera versión.
- Público: jóvenes y adultos.

---

## 18. Riesgos a probar

1. **Anomalía que huye (pepino):** depende de las escaleras y de arrinconarla. Puede frustrar.
2. **Apuntado por movimiento sin trayectoria:** los lanzamientos pueden sentirse imprecisos. Probar si hace falta una línea.
3. **Ronda 3:** se combinan piso nuevo, herbicida y mecánicas acumuladas. Puede ser demasiado de golpe.
4. **Lanzaguisantes:** su frecuencia de disparo frente al cooldown de 5 s puede sentirse injusta.
5. **Invulnerabilidad al deslizarte:** puede volver trivial la captura de la lechuga.
6. **Sin guardado:** el juego completo tiene que sentirse bien en una sola sesión.
7. **Calor:** comprobar que la presión dependa de decisiones y no solo de un reloj.

---

## 19. Pendientes

- Plataforma de publicación: Steam, itch.io o ambos.
- Valores exactos de calor, velocidades y duración del deslizamiento.
- Umbral de calor alto (cuando aparece el humo).
- Velocidad y frecuencia de disparo del Lanzaguisantes.
- Velocidad de movimiento de la papa.
- Diseño del mapa de cada piso.
- Trampas y peligros del escenario.
- Guion de la escena de inicio y de la escena final.
- Sonidos de captura de cada tipo.
- Opción de salir en el menú principal.
- Versión de Godot.
