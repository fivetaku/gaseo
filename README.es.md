[English](README.md) | [한국어](README.ko.md) | [中文](README.zh.md) | [日本語](README.ja.md) | Español

# gaseo (가세오)

<p align="center">
  <img src="assets/gaseo-hero-01.png" alt="gaseo" width="320">
</p>

> **Manda a Paseo la sesión en la que estás ahora mismo — y sigue desde allí.**

[Paseo](https://paseo.app) solo lista los agentes que él mismo lanzó. Una sesión que abriste escribiendo `claude` en la terminal no aparece nunca, y no hay forma de retomarla desde la app. `gaseo` cierra ese hueco: di «가세오» y la conversación que estás teniendo en este segundo aparece en Paseo con su propio título, lista para continuar.

[Inicio rápido](#inicio-rápido) • [Por qué gaseo](#por-qué-gaseo) • [Cómo funciona](#cómo-funciona) • [Funciones](#funciones) • [Comandos](#comandos) • [Requisitos](#requisitos)

---

## Inicio rápido

### 1. Añade el marketplace

```
/plugin marketplace add https://github.com/fivetaku/gptaku_plugins.git
```

### 2. Instala

```
/plugin install gaseo
```

### 3. Reinicia Claude Code

(Los comandos nuevos solo se registran tras reiniciar.)

### 4. Ejecuta

```
/gaseo
```

Ya está: la sesión en la que estás ya vive en Paseo. Abre la app y sigue hablando.

Para traer conversaciones anteriores de esta carpeta:

```
/gaseo past
```

O simplemente dilo:

- «파세오로 가세오»
- «이 세션 파세오로 가세오»
- «가세오 해줘»
- "register this session to paseo"
- "import my past sessions into paseo"

---

## Por qué gaseo

**Tus sesiones de terminal son invisibles para Paseo.** Paseo muestra los agentes que arrancó él. Todo lo que lanzaste tú desde una shell —o sea, la mayor parte del trabajo real— sencillamente no está en la lista, y la interfaz no tiene botón de importar.

**Es un enlace, no una copia.** `gaseo` ejecuta `paseo import`, que no escribe más que un puntero al ID de sesión. Tu transcripción se queda exactamente donde Claude Code la dejó. Archiva el agente en Paseo más adelante y la conversación original sigue intacta.

**Levántate del escritorio a mitad de tarea.** Registra la sesión, cierra el portátil y continúa desde la app de Paseo: misma conversación, mismo historial, sin volver a explicar nada.

**Nada se registra dos veces.** Las sesiones que Paseo ya conoce —incluidas las que él lanzó— se detectan y se omiten.

**Las carpetas que Paseo nunca ha visto también valen.** El espacio de trabajo se crea al importar.

---

## Cómo funciona

```
/gaseo
  → localiza el directorio de sesiones de esta carpeta
      ~/.claude/projects/<ruta con los caracteres no alfanuméricos como '-'>/
  → $CLAUDE_CODE_SESSION_ID si su transcripción está aquí; si no, el .jsonl más reciente
  → ¿ya está en ~/.paseo/agents? → la omite, lo informa y termina
  → paseo import <idDeSesión> --provider claude --cwd <carpeta>
  → aparece en Paseo con su título original
```

Paseo no guarda ninguna conversación propia. Cada registro de agente contiene únicamente un puntero `persistence.nativeHandle` al ID de sesión de Claude, y por eso la importación es instantánea, no requiere reiniciar el daemon y jamás duplica tus datos.

---

## Funciones

| Función | Descripción |
|---------|-------------|
| Registrar la sesión actual | `/gaseo` reconoce la sesión en la que hablas, sin pedir ningún ID |
| Selector de sesiones pasadas | `/gaseo past` lista las anteriores con primer mensaje, hora y estado de registro |
| A prueba de duplicados | Las sesiones ya registradas se informan, no se reimportan |
| Espacios de trabajo nuevos | Importa en carpetas que Paseo nunca ha visto, creando el espacio |
| Enlace, no copia | Las transcripciones originales no se mueven, alteran ni duplican |
| Detección confirmable | Muestra el primer mensaje de la sesión elegida antes de que confíes en ella |

---

## Comandos

| Comando | Descripción |
|---------|-------------|
| `/gaseo` | Registra la sesión actual |
| `/gaseo past` | Lista las sesiones pasadas de esta carpeta y elige cuáles registrar |
| `/gaseo <carpeta>` | Registra la sesión actual de otra carpeta |
| `/gaseo past <carpeta>` | Selector de sesiones pasadas de otra carpeta |

### Disparadores en lenguaje natural

- `/gaseo`, «파세오로 가세오», «이 세션 파세오로 가세오», «가세오 해줘», «파세오에 등록해줘»
- «과거 세션 파세오로 가져와줘»
- "register this session to paseo", "send this session to paseo"
- "import my past sessions into paseo"

---

## Notas y límites

**Cómo se identifica la sesión actual.** `gaseo` lee `$CLAUDE_CODE_SESSION_ID`, el ID que Claude Code expone para la sesión viva, y comprueba que exista una transcripción correspondiente en la carpeta. Solo cuando eso no está disponible recurre a elegir la transcripción escrita más recientemente: una conjetura, porque los subagentes en segundo plano y las sesiones lanzadas por hooks escriben en el mismo directorio y suelen ser más nuevas. La salida indica qué ruta se usó (`via=env` o `via=mtime`); ante una conjetura `via=mtime`, revisa el primer mensaje que imprime o usa `/gaseo past` para elegir explícitamente.

**Solo sesiones de Claude.** Las de codex se guardan por fecha en lugar de por carpeta, así que la correspondencia carpeta-sesión en la que esto se apoya todavía no les aplica.

**El daemon nunca se reinicia por ti.** Si `paseo import` falla porque el daemon está caído, `gaseo` lo informa y se detiene. Reiniciar mata todos los agentes en ejecución, así que esa decisión sigue siendo tuya.

---

## Requisitos

- CLI de [Claude Code](https://docs.anthropic.com/claude-code)
- [Paseo](https://paseo.app) instalado y con su daemon en marcha (`paseo status`)
- El CLI `paseo` en el `PATH`, o en su ruta de instalación por defecto

---

## Licencia

MIT — consulta [LICENSE](LICENSE) y [DISCLAIMER.md](DISCLAIMER.md).

---

<div align="center">

**Tu sesión no tiene por qué quedarse en la terminal.**

</div>
