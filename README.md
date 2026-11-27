# ANEURISM IV HUD для Garry's Mod

Адаптивный HUD в стиле **ANEURISM IV**: рация с динамическим LCD и **фракционным чатом**, **две полосы состояния** (`BLOOD` — здоровье, `AIR` — энергия/stamina) и контекстные подсказки `Grab` / `Search`. Плюс лёгкий CRT-эффект (скан-линии, зелёный оттенок, затемнение краёв). Книжка-счётчик и VGUI-инвентарь полностью удалены по просьбе пользователя.

Версия **1.1.0** добавляет фракционную рацию (`F3` → клик по рации → `X` → чат → клик для возврата в обычный чат) и две полосы с **настоящими спрайтами из игры** (вместо четырёх иконок). Старые иконки можно вернуть конваром `aniv_hud_bars_enabled 0`.

---

## 1. Что было найдено в оригинале (источники)

| Источник | Что дал |
|---|---|
| [aneurism.wiki.gg — Controller](https://aneurism.wiki.gg/wiki/Controller), [Gameplay Mechanics](https://aneurism.wiki.gg/wiki/Gameplay_Mechanics) | Рация в левом верхнем углу; `TAB` + клик = mute/unmute; `X` (в игре) = трансляция; экран рации показывает `UNMUTED. / Click to mute. / Hold X to broadcast.` |
| [aneurism.wiki.gg — HUD](https://aneurism.wiki.gg/wiki/HUD) | Статы называются Sense / Blood / Air / Sanity / Sepsis / Nourishment / Moisture; значения 0–100%; moisture, nourishment и sanity видны только при ≤75% |
| [Guides](https://aneurism.wiki.gg/wiki/Guides) | Инвентарь открывается по `Q`; подсказки над предметами пиксельным шрифтом; «зелёный» sense-бар внизу |
| [File:Walkie talkie (1).png](https://aneurism.wiki.gg/wiki/File:Walkie_talkie_(1).png) | Прямой спрайт рации 371×413 — использован как текстура корпуса |
| [File:HUDBarsUpdate17.png](https://aneurism.wiki.gg/wiki/File:HUDBarsUpdate17.png), [File:Inventory.png](https://aneurism.wiki.gg/wiki/File:Inventory.png), [File:Locationfinder.png](https://aneurism.wiki.gg/wiki/File:Locationfinder.png) | Палитра: болотный зелёный, ржавый металл, грязная бумага; пиксельный шрифт; зелёные рамки; цветные токены в тексте. Скопировано в `docs/refs/` |
| [Console Commands](https://aneurism.wiki.gg/wiki/Console_Commands_/_Server_Hosting) | В игре есть команда `togglehud` — она реализована |

> Важное отличие от ТЗ: в игре кнопка голосовой трансляции — **X**, а не C. В аддоне `X` используется для **текстового фракционного чата** (по вашей просьбе), а `C` остался визуальным индикатором передачи. **VGUI-инвентарь и книжка-счётчик полностью удалены**: в HUD их больше нет. Конвары: `aniv_hud_radio_chat_key`, `aniv_hud_broadcast_key`.

> Фракционный канал не выдуман: вики прямо говорит, что у Cortex и Scum **разные каналы** («they cannot hear each other»), а текстовые сообщения фракции отправляются префиксом `//`. В `myrp` роли фракций заданы в `schema/factions/sh_combine.lua` и `sh_resistance.lua`.

> Текстуры и спрайты Aneurism IV — авторский материал Vellocet Software. TTF-шрифты Silkscreen и VT323 распространяются по лицензии OFL. Используйте ассеты в личных проектах.

---

## 2. Установка

### На этом сервере (уже сделано)

* Аддон установлен в `D:\steamcmd\Server\garrysmod\addons\aneurism_hud`.
* Добавлен мост-плагин `D:\steamcmd\Server\garrysmod\gamemodes\myrp\schema\plugins\myrp_zz_aniv_hud\`.
  Он отключает старый HUD-плагин `myrp_hud` (панель HP/ARM/STM + патроны) и подаёт в ANIV HUD живые данные Helix:
  `Health → blood`, `LocalVar("stm") → air/leg`, `character data "sanity" → sanity`. Инвентарь персонажа больше нигде не отображается.
  Плагин загружается последним (префикс `zz`), поэтому его `hook.Remove("HUDPaint", "MYRP.CustomHUD.Paint")` срабатывает после регистрации старого HUD.
* Проверить состояние: консоль `myrp_aniv_hud_status`.
* Чтобы вернуть старый HUD — отключите/удалите папку `myrp_zz_aniv_hud` (Premium/Helix plugin manager) или папку аддона.

### Общая инструкция

1. Скопируйте папку `aneurism_hud` в:
   ```
   <GMod>/garrysmod/addons/aneurism_hud
   ```
   (внутри должны остаться папки `lua`, `materials`, `resource`).
2. Перезапустите Garry's Mod — GMod сам подхватит `lua/autorun` и `resource/fonts`.
3. В консоли:
   - `togglehud` — скрыть/показать HUD;
   - `aniv_hud_debug` — распечатать текущее состояние;
   - `aniv_hud_materials` — проверить, загрузились ли текстуры у клиента;
   - `aniv_hud_reset` — сбросить значения.
4. Если у вас установлен другой HUD-аддон, убедитесь, что он не перехватывает `HUDPaint` / `HUDShouldDraw`.

### Важно для выделенного сервера: розово-чёрные квадраты

GMod по сети отдаёт клиенту **только Lua**. Материалы, VMT и шрифты из аддона
клиент сам не скачивает — вместо них рисуется розово-чёрный «error»-материал.
Поэтому в аддоне есть `lua/autorun/aniv_hud_resources.lua`: он вызывает
`resource.AddFile()` для каждой текстуры/VMT/шрифта, и клиент получает их при
подключении (встроенная загрузка или FastDL / `sv_downloadurl`).

Проверка на сервере (консоль при старте):

```
[ANIV][SERVER] Added client download: materials/aneurism_hud/walkie_talkie.vmt
...
[ANIV][SERVER] HUD content registered: 24/24 files.
```

Проверка на клиенте: `aniv_hud_materials` — все строки должны быть `error=false`.
Даже если файл не дошёл, HUD больше не показывает чекербоард: `ANIV.DrawTex()`
рисует плоский цвет-заглушку.

### Структура

```
aneurism_hud/
├─ lua/
│  ├─ autorun/
│  │  ├─ aniv_hud_init.lua          -- конфиг, конвары, шрифты, 1:1-хелперы, API
│  │  └─ aniv_hud_resources.lua     -- resource.AddFile() для клиентских файлов
│  └─ autorun/client/
│     ├─ aniv_hud_core.lua          -- отрисовка (рация, 2 полосы, legacy-иконки, подсказки, CRT)
│     ├─ aniv_hud_input.lua         -- клавиши, курсор, клики, E-взаимодействие
│     └─ (aniv_hud_inventory.lua удалён — VGUI-инвентарь убран полностью)
├─ materials/aneurism_hud/
│  ├─ walkie_talkie.png             -- спрайт рации с вики (371×413)
│  ├─ paper.png                     -- процедурная старая бумага (128×128)
│  ├─ plastic.png                   -- процедурный тёмный пластик (128×128)
│  ├─ metal.png                     -- процедурный оксидированный металл (128×128)
│  ├─ icon_blood.png                -- ОРИГИНАЛЬНЫй спрайт игры: капля крови (16×16)
│  ├─ icon_skull.png                -- ОРИГИНАЛЬНЫй спрайт игры: череп (16×16)
│  ├─ icon_eye.png                  -- ОРИГИНАЛЬНЫй спрайт игры: глаз (16×16)
│  ├─ icon_check.png                -- ОРИГИНАЛЬНЫй спрайт игры: галочка (11×11)
│  ├─ icon_bone.png                 -- game-icons.net: сломанная кость (32×32)
│  ├─ icon_leg.png                  -- game-icons.net: нога (16×16)
│  ├─ bar_frame.png                 -- оригинальная капсула из игры (265×39)
│  ├─ bar_noise.png                 -- оригинальный шум из игры (128×32)
│  ├─ ui_button_bg.png              -- настоящая кнопка interaction menu (352×48)
│  ├─ ui_panel.png                  -- настоящий фон interaction menu (640×576)
│  └─ *.vmt                         -- материалы с $pointsample (пиксельная фильтрация)
├─ resource/fonts/
│  ├─ Silkscreen-Regular.ttf        -- пиксельный шрифт (OFL)
│  └─ VT323-Regular.ttf             -- терминальный LCD-шрифт (OFL)
├─ tools/
│  ├─ generate_textures.ps1         -- генератор текстур заново
│  └─ prepare_icons.py              -- пересборка иконок из исходников (Pillow)
└─ docs/refs/
   ├─ hud_bars_reference.png        -- 7 полос статов из вики
   ├─ inventory_reference.png
   ├─ locationfinder_reference.png
   └─ measurements.json             -- ВСЕ измерения в пикселях + UV + hex-цвета
```

Текстуры `paper/plastic/metal` сгенерированы скриптом `tools/generate_textures.ps1` (только .NET, без внешних зависимостей). Если сервис генерации изображений недоступен — перезапустите скрипт, чтобы получить новые вариации (измените сид `$rnd = New-Object System.Random(4815)`).

Иконки `blood`, `skull`, `eye`, `check` — это те же самые 16×16-спрайты, что лежат в `data.unity3d` игры (извлечены UnityPy). Кость и нога взяты из того же набора **game-icons.net**, который использовали разработчики, поэтому толщина штриха и антиалиасинг совпадают. Иконки рисуются белым спрайтом с `$vertexcolor`-подкраской: тёмный контур + яркая заливка снизу вверх.

Все числовые значения (позиции, UV LCD, размеры иконок, цвета) собраны в `docs/refs/measurements.json`. Например, LCD рации находится не «примерно», а точно: исходные пиксели `x 93…232, y 254…339` спрайта 371×413 → UV `0.250674, 0.615012 … 0.628032, 0.823245`.

---

## 3. Управление

| Действие | Клавиша | Конвар |
|---|---|---|
| Разблокировать/заблокировать курсор | **F3** (toggle) | `aniv_hud_radio_key` |
| Включить/выключить фракционную рацию (изначально **OFF**) | клик ЛКМ по рации при разблокированном курсоре | `aniv_hud_radio on\|off` |
| Написать в фракционный чат (только при включённой рации) | **X** → ввод → **Enter** | `aniv_hud_radio_chat_key` |
| Отменить ввод (рация остаётся включённой) | **Esc** | — |
| Вернуть обычный чат | повторный клик по рации (выключить её) | — |
| Визуальный индикатор передачи (удерживать) | **C** | `aniv_hud_broadcast_key` |
| Инвентарь | **удалён полностью** — не открывается ни клавишей, ни кликом | — |
| Взаимодействие с HUD (курсор на время удержания) | **TAB** | `aniv_hud_ui_key` |
| Взаимодействие с объектом (Grab/Search) | **E** | `aniv_hud_interact_key` |
| Скрыть/показать весь HUD | консоль | `togglehud` |

Пока рация включена, обычный чат заблокирован: всё, что вы напечатаете в стандартном окне чата, будет переадресовано в фракционный канал. Сообщения видны только игрокам той же фракции (`combine` ↔ `resistance` не слышат друг друга). Сервер логирует их как `[ANIV][RADIO] <ник> [combine]: <текст>`.

---

## 4. Конвары

| Конвар | По умолчанию | Описание |
|---|---|---|
| `aniv_hud_enabled` | `1` | Общий флаг (дублирует `togglehud`) |
| `aniv_hud_scale` | `1` | Масштаб относительно 1080p |
| `aniv_hud_crt` | `1` | Скан-линии и затемнение краёв |
| `aniv_hud_broadcast_key` | `C` | Hold-индикатор передачи (визуальный) |
| `aniv_hud_radio_key` | `F3` | Разблокировка курсора для клика по рации |
| `aniv_hud_radio_chat_key` | `X` | Открытие фракционного чата при включённой рации |
| `aniv_hud_faction_chat` | `1` | Маршрутизация сообщений только своей фракции |
| `aniv_hud_interact_key` | `E` | Кнопка взаимодействия |
| `aniv_hud_ui_key` | `TAB` | Кнопка режима курсора |
| `aniv_hud_free_cursor` | `0` | Постоянно видимый курсор (для теста кликов) |
| `aniv_hud_ads_click` | `0` | Курсор при прицеливании (правый ЛКМ), чтобы рация была кликабельна. По умолчанию выключено, т.к. мешает прицеливанию |
| `aniv_hud_prompt_preview` | `0` | Показать обе подсказки сразу (`Grab` + `Search`) |
| `aniv_hud_prompt_dist` | `110` | Дальность подсказок |
| `aniv_hud_icon_labels` | `0` | Подписи под иконками |
| `aniv_hud_bars_enabled` | `1` | Две полосы BLOOD/AIR вместо четырёх иконок |

---

## 5. Интеграция с вашим гамемодом

Все состояния меняются через публичный API — просто вызывайте его из своего кода.

```lua
-- клиент
ANIV.SetBlood(42)          -- 0..100  -> красная капля
ANIV.SetAir(70)            --         -> жёлтая нога (выносливость)
ANIV.SetSanity(18)         --         -> синий череп (мерцает при <30)
ANIV.SetStat("bone", 55)   --         -> сломанная кость (legacy-иконки)
ANIV.SetBlood(70)          --         -> полоса BLOOD
ANIV.SetAir(55)            --         -> полоса AIR (stamina)

ANIV.SetRadioActive(true)      -- включить фракционную рацию (стартует выключенной)
ANIV.IsRadioActive()
ANIV.ToggleRadio()
ANIV.SetRadioChatOpen(true)    -- открыть поле ввода (только если рация включена)
ANIV.ToggleCursorUnlocked()    -- то же, что F3
ANIV.SetMuted(true)            -- алиас: muted == not radioActive
ANIV.SetBroadcasting(true)
ANIV.ToggleHUD()
```

Старые `SetInventory/AddItem/RemoveItem/InventoryCount/OpenInventory/CloseInventory/ToggleInventory` — пустые заглушки: инвентарь вырезан полностью.

Хуки, которые можно ловить:

```lua
hook.Add("ANIV_StatChanged",            "x", function(name, v) end)
hook.Add("ANIV_RadioStateChanged",      "x", function(active) end)
hook.Add("ANIV_RadioChatStateChanged",  "x", function(open, initialText) end)
hook.Add("ANIV_CursorUnlockedChanged",  "x", function(unlocked) end)
hook.Add("ANIV_RadioMessageReceived",   "x", function(sender, uid, name, text) end)
hook.Add("ANIV_MuteChanged",            "x", function(muted) end)
hook.Add("ANIV_Interact",               "x", function(prompt, ent) end) -- "Grab"/"Search"
```

Сервер → клиент (необязательно, пример в `docs/example_server.lua`):

```lua
net.Start("ANIV_SetStat") net.WriteString("blood") net.WriteFloat(62) net.Send(ply)
```

### Подсказки над объектами

HUD сам определяет тип по классу сущности. Можно переопределить вручную на своей сущности:

```lua
ENT.ANIV_HudPrompt     = "Grab"         -- или "Search", или false чтобы скрыть
ENT.ANIV_RemoveOnGrab  = true           -- удалить объект после picked up
ENT.ANIV_Grabbable     = true           -- Force «Grab»
```

По умолчанию рисуются **только 2 полосы** — `BLOOD` и `AIR` (stamina), с настоящими спрайтами из игры. Остальные статы спрятаны по просьбе пользователя. Старые 4 иконки доступны через `aniv_hud_bars_enabled 0` (`blood` = здоровье, `bone` = перелом, `leg` = air, `skull` = sanity; при <30% мигают красным).

---

## 6. Известные отличия от оригинала

* Вместо родного шрифта игры используются максимально близкие бесплатные OFL-шрифты `Silkscreen` и `VT323`.
* Оригинальный HUD показывает **7 полос** (Sense/Blood/Air/Sanity/Sepsis/Nourishment/Moisture); по просьбе пользователя оставлены только **BLOOD и AIR**. Полный референс лежит в `docs/refs/hud_bars_reference.png`, текстуры капсулы/шума вырезаны оттуда через `tools/make_bar_textures.py`.
* Рация использует оригинальный спрайт с вики; LCD перекрывается и рисуется динамически (поэтому текст меняется).
* На скриншоте из игры третья строка LCD выглядит как `Hold F to`; по вашему ТЗ по умолчанию стоит `C`. Меняется конваром `aniv_hud_broadcast_key F`.
* Иконки из скриншота — это стилизованные «залитые» версии тех же глифов; у нас они повторяют форму глифов, но без игрового bloom/свечения (в GMod это дал бы post-process, а не сама текстура).
* Клик по рации доступен в «режиме HUD» (F3 / TAB / `aniv_hud_free_cursor 1`) — точно как в игре, где нужно зажать TAB.
* LCD-строки адаптированы под новую механику: `MUTED. / Click to turn on. / F3: unlock cursor / Local chat active.` → `UNMUTED. / Click to turn off. / Press X to talk. / Faction channel.` → при вводе `BROADCASTING / Type your message. / Enter to send. / Esc to cancel.` Положение, шрифт и цвета панели — 1:1 с референсом.
* Голосовая трансляция игры (hold `X`) заменена текстовым фракционным чатом на `X`, как вы и просили; `C` остался только визуальным hold-индикатором.
* Розово-чёрные шашечки были вызваны не отсутствием файлов (клиент их скачал), а тем, что `.vmt` ссылался на несуществующий `.vtf`. Теперь текстуры грузятся как `Material("...png")` — GMod поддерживает PNG напрямую. Дополнительно `ANIV.MatReady()` проверяет имя `$basetexture` и рисует плоскую заливку вместо шашечек, если текстура всё же не пришла.
* Исправлены ошибки Lua: `InRect(gui.MousePos()/CursorPos(), …)` обрезал два возвращаемых значения до одного (`h = nil`) — теперь координаты сначала присваиваются в локальные переменные.
