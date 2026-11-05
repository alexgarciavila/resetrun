# Reset Run — guía de proyecto y tareas

Actualizado: 5 de noviembre de 2026.

## Fuente y alcance

Esta guía recoge el prompt inicial disponible en esta conversación (apartado 2, Resetbot) y las decisiones posteriores. No se dispone de los demás apartados de un posible prompt general: no se deben dar por implementados ni inventar requisitos de esos apartados.

## Prompt inicial: personaje principal Resetbot

Proporcionaré los spritesheets originales de Resetbot, la mascota oficial de Resettecnic.

**Es obligatorio utilizar los sprites proporcionados, sin rediseñar el personaje.**

- Cada animación proporcionada contiene **8 frames**.
- Respetar el orden original de los fotogramas.
- Separar correctamente los 8 frames de cada spritesheet.
- Mantener las proporciones, los colores y el diseño original.
- Preservar el logotipo RESET del pecho.
- Utilizar interpolación Nearest para mantener los píxeles nítidos.
- No generar frames adicionales ni eliminar ninguno.

**Animaciones:**

- **Run:** utilizar los 8 frames de carrera en bucle.
- **Jump:** utilizar los 8 frames de salto respetando su secuencia.
- **Idle, Hit y Game Over:** utilizar animaciones existentes si se proporcionan. En caso contrario, reutilizar fotogramas apropiados sin modificar el diseño.

Configurar las animaciones mediante `AnimatedSprite2D` y `SpriteFrames` de Godot 4.

Ajustar la velocidad de reproducción de cada animación para que la carrera y el salto se vean naturales y sincronizados con el movimiento del personaje. En la carpeta `C:\Users\Sh4d0w\repos\resetrun\images\character` tienes los sprites del personaje.

## Decisiones posteriores del usuario

- Run y Jump se entregaron en imágenes separadas; Jump ya contiene 8 poses.
- Corregir recortes individuales en Run, Idle y Game Over: no deben aparecer poses vecinas ni extremidades cortadas.
- Eliminar las tres rayitas sobre la cabeza del fotograma 3 de Idle (índice desde cero).
- Idle debe mantener **ambas suelas** pegadas al suelo. Alinear el fotograma completo no basta: el pie derecho tiene desplazamiento independiente en la lámina.
- Hit debe tener movimiento: reutiliza las primeras tres poses de Game Over, en orden, sin crear dibujos nuevos.
- Crear un runner jugable y retirar los fondos opacos de los sprites.

## Estado del prototipo

- [x] Proyecto Godot 4 con escena principal `scenes/game.tscn`.
- [x] Componente visual reutilizable `scenes/resetbot.tscn`.
- [x] SpriteFrames con Run, Jump, Idle y Game Over de 8 poses; Hit de 3 poses reutilizadas.
- [x] Nearest explícito; PNG originales conservados.
- [x] Carrera automática, salto, obstáculos, tres vidas, invulnerabilidad temporal y dificultad progresiva.
- [x] Distancia, récord persistente y reinicio.
- [x] Prueba automática de inicio, salto, aterrizaje, daño, Game Over y reinicio.
- [ ] Aceptación visual por el usuario: las pruebas de lógica no garantizan encuadre ni apoyo de pies correctos.

## Backlog priorizado

| ID | Prioridad | Tarea | Criterio de finalización |
| --- | --- | --- | --- |
| ART-01 | P0 | Transparencia de las cuatro láminas | Sin rectángulos oscuros; contornos negros y logo RESET intactos; 8 poses en las mismas coordenadas. |
| ART-02 | P0 | Revisar todos los recortes | Inspección de cada frame sobre fondo claro y oscuro, sin cortes ni restos vecinos. |
| ANI-01 | P0 | Validar Idle con ambas suelas fijas | Reproducir varios ciclos ampliados; ningún pie sube ni un píxel. Revisar shader de corrección tras cambiar texturas. |
| ANI-02 | P0 | Unificar escala y anclaje entre animaciones | Resetbot conserva tamaño aparente al pasar de Idle a Run, Jump, Hit y Game Over. |
| ANI-03 | P0 | Sincronizar salto físico y poses | Una sola trayectoria coherente: la elevación dibujada en la lámina no debe sumarse indebidamente al desplazamiento físico. Aterrizaje al suelo sin flotación. |
| GAME-01 | P1 | Ajustar colisiones y dificultad jugando | Hitbox justa; obstáculos siempre superables; comprobar daño en suelo y aire y al acelerar. |
| GAME-02 | P1 | Pulir transiciones de estados | Impacto en el aire, aterrizaje durante Hit, último golpe y reinicio sin animaciones bloqueadas. |
| UX-01 | P1 | Menú y pausa | Inicio, pausa/reanudación y Game Over claros; controles visibles. Propuesta pendiente, no requisito del prompt original. |
| AUDIO-01 | P2 | Añadir audio | Salto, impacto y fin de partida con volumen/silencio. Propuesta pendiente de recursos. |
| ART-03 | P2 | Escenario y obstáculos definitivos | Sustituir geometría provisional con dirección artística acordada. |
| QA-01 | P1 | Probar ventana y controles | Teclado, clic, toque si procede; redimensionado y legibilidad. |
| BUILD-01 | P2 | Definir destino y exportar | Acordar Windows/web/móvil, preparar preset y probar build fuera del editor. |

P0: resolver antes de añadir contenido. P1: necesario para un prototipo estable. P2: siguiente fase; confirmar alcance antes de desarrollar funciones nuevas.

## Flujo de trabajo

1. Elegir una tarea del backlog y marcarla en curso con fecha.
2. Leer el requisito y su criterio de finalización; no rediseñar Resetbot.
3. Modificar fuentes y generadores, no únicamente el `.tres` generado.
4. Ejecutar `python tools/build_frames.py` si cambian atlas o recortes.
5. Importar el proyecto y ejecutar la prueba lógica cuando cambie el juego.
6. Revisar visualmente cada animación afectada a escala ampliada y a escala de juego.
7. Registrar resultado y limitaciones; marcar completada solo con evidencia.

## Archivos y pruebas

- `project.godot`: configuración; F5 ejecuta el juego completo.
- `scripts/game.gd`: estados, movimiento, obstáculos, colisiones y puntuación.
- `scripts/resetbot.gd`: reproducción de animaciones.
- `scripts/idle_feet.gdshader`: corrección localizada del pie derecho durante Idle.
- `tools/build_frames.py`: fuente de las regiones de atlas y velocidades.
- `scenes/resetbot_frames.tres`: recurso generado; regenerar tras cambios.
- `tools/check_game.gd`: prueba lógica, ejecutar con Godot `--headless --path . --script tools/check_game.gd`.
- `user://record.cfg`: récord local, fuera del repositorio.

Godot localizado en `C:\Users\Sh4d0w\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`.

Controles actuales: Espacio / flecha arriba / clic para empezar y saltar; R reinicia. Tras Game Over, Espacio o clic devuelve a inicio.

## Prompt para retomar el proyecto

> Continúa Reset Run en este repositorio. Lee `docs/GUIA_PROYECTO.md` y respeta el prompt original de Resetbot: sprites proporcionados, diseño y logo intactos, 8 frames en orden para las animaciones entregadas, Nearest, AnimatedSprite2D y SpriteFrames de Godot 4. Revisa el backlog y resuelve primero las tareas P0 pendientes. Conserva los originales, verifica visualmente ambas suelas de Idle, los límites de todos los recortes y la coherencia del salto con las físicas. Ejecuta las pruebas correspondientes y actualiza esta guía con evidencias y tareas restantes. No marques una corrección visual como validada solo porque pasa una prueba de lógica.

## Registro de transparencia

- Entregables: `images/character/transparent/{run,jump,idle,gameover}_resetbot.png`.
- Originales: conservados en `images/character/`.
- M�todo: herramienta integrada imagegen (edici�n), una extracci�n por l�mina; composici�n del alfa sobre los colores originales con `tools/apply_alpha.ps1`. La salida de Run cambi� de lienzo; su m�scara se registra a la geometr�a original con escala 2172/2048 y desplazamiento vertical de 175 p�xeles de referencia. No se usan los RGB generados.
- M�scaras guardadas: `tools/alpha_masks/`. Esas im�genes son entradas de procesamiento, no sprites del juego.
- Prompt com�n utilizado: �Remove ONLY the dark blue/gray background and ground shadows to true alpha transparency. Also remove titles, captions, divider lines. Keep all EIGHT original poses in their EXACT original pixel locations and sizes on the EXACT same canvas. Preserve every original character design, black outlines, black head/body, red eye, white gloves/shoes, RESET chest logo, colors, pixel art and details. Do NOT remove black character pixels. Do NOT redesign, rearrange, resize, crop canvas, add or omit any frame. Preserve white action marks in Game Over, no new marks in Idle. Transparent PNG for Godot atlas regions.�
- Evidencia visual: `tools/previews/transparency.png`, las cuatro secuencias sobre fondo claro. Pendiente revisi�n a escala real en partida y aceptaci�n de pies/contornos.

### Corrección del ojo en Hit y Game Over

Se retiraron las pupilas negras de las primeras cinco poses mediante edición integrada de imágenes, limitada al interior de los iris; el resto del atlas y su alfa se conservan. Hit reutiliza las tres primeras y recibe la misma corrección. Prompt: quitar únicamente la pupila negra y rellenar con rojo conservando ojo, poses, logo y dimensiones. Fuente de edición guardada en tools/alpha_masks/gameover_eye_edit.png. Reaplicación: tools/fix_gameover_eyes.ps1, invocado también al regenerar transparencia. Comprobación ampliada: tools/previews/eyes.png.


### Prueba sin contorno exterior

Variante activa: `images/character/no_outline/`. Las versiones anteriores est�n intactas en `images/character/transparent/`. Se conserva RGB, alfa interior, posiciones, tama�o de lienzo y n�mero de poses. La eliminaci�n se limita a p�xeles oscuros pr�ximos al borde usando las m�scaras de edici�n de imagegen, guardadas en `tools/outline_masks/`. No se usan colores generados.

Prompt: �Remove ONLY the thick outermost black contour stroke around each character silhouette, making those outer stroke pixels transparent. Keep the interior black head, body and limbs intact. Preserve original colors, RESET logo, red eye with no black pupil, every pose and all 8 frame positions, exact canvas dimensions. No redesign, no new frames, no repositioning. Background genuinely transparent.� Herramienta integrada de edici�n de im�genes; composici�n mediante `tools/apply_outline_variant.ps1`.

- Regenerar variante: ejecutar `tools/apply_outline_variant.ps1` despu�s de regenerar transparencia y ojos.
- Activarla: `python tools/build_frames.py`.
- Volver al contorno anterior: `python tools/build_frames.py --original-outline`.
- Comparaci�n: `tools/previews/outline_comparison.png` (arriba anterior, abajo prueba).
- Pendiente: aceptaci�n visual del usuario, comprobar nuevamente apoyo de pies tras retirar contorno de suelas.

### Coherencia de tamaño, anclaje y golpes

- Todas las animaciones se escalan de forma uniforme usando el ancho de cabeza como referencia común (102 píxeles en pantalla). Se conserva la proporción de cada dibujo y la altura propia de las posturas agachadas; no se iguala artificialmente la altura de todas las poses.
- `resetbot.gd` calcula y cachea el anclaje inferior de cada fotograma a partir de su alfa. El origen del nodo corresponde al suelo; se elimina el anclaje manual diferente por lámina de `game.gd`. La trayectoria física del salto se aplica una sola vez.
- Resetbot permanece opaco al recibir daño y durante Game Over. La invulnerabilidad se señala con un tinte suave; ya no reduce alfa. Z del personaje: 10. El obstáculo golpeado se retira inmediatamente, también en el último golpe.
- Prueba ampliada `tools/check_game.gd`: todos los anclajes, alfa 1 tras cada golpe, eliminación del obstáculo, inicio, salto, aterrizaje, Game Over y reinicio. Resultado: PASS en Godot 4.7.2.
- Verificación renderizada en Godot: `tools/previews/animation_sizes.png`, generada con `tools/preview_sizes.gd`; muestra las cinco animaciones en su primer frame a la misma referencia de suelo. Aceptación final de movimiento por el usuario pendiente.


### Primer escenario: datacenter

Integrado el recurso proporcionado `images/background/datacenter.png`, sin modificar el PNG. Sustituye al decorado geom�trico provisional. Se escala proporcionalmente y alinea la pasarela con FLOOR_Y; desplazamiento horizontal al 35 % de la velocidad de carrera con repetici�n, detenido en inicio y Game Over y reiniciado con la partida. El personaje y obst�culos se dibujan delante. HUD con sombra para mejorar lectura.

Verificaci�n: importaci�n Godot 4.7.2, prueba de juego PASS y captura renderizada `tools/previews/datacenter_game.png`, generada mediante `tools/preview_game.gd`. Pendiente aceptar la continuidad visual en la uni�n de repeticiones del fondo y definir escenarios posteriores.

### Velocidad progresiva y sensación de carrera

Ajuste actual: 360 px/s al empezar, 540 a los 400 m y límite de 720 a los 800 m. Fórmula lineal limitada, configurable en START_SPEED, MAX_SPEED y METERS_TO_MAX_SPEED de scripts/game.gd. Distancia integrada con delta; no depende de los FPS. El fondo pasa del 35 % al 80 % de la velocidad de carrera y se añaden trazos discretos en primer plano bajo la pasarela, sin modificar los sprites. Run conserva 12 fps al inicio y alcanza 24 fps al límite; salto mantiene su duración física. HUD muestra multiplicador de velocidad. Se conserva la separación temporal mínima de obstáculos de 1,35 s, superior al salto de 0,8 s.

Pruebas: progresión a 0/400/800/10000 m, límite y reinicio, además de la suite previa: PASS. Pendiente valoración jugable de la curva por el usuario.
