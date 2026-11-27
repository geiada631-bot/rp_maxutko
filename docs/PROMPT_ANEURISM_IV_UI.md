# ПРОМТ ДЛЯ OPENCODE — HUD ANEURISM IV 1:1 ДЛЯ GARRY'S MOD

Скопируй весь текст ниже в новую сессию OpenCode, открытую в папке проекта.

---

## РОЛЬ

Ты — senior-разработчик Garry's Mod (Lua 5.1, Source engine, Helix framework) и одновременно UI/technical artist. Твоя задача — воссоздать HUD из игры **ANEURISM IV** максимально близко к оригиналу (1:1 по композиции, цвету, шрифтам, пропорциям и поведению) в виде аддона Garry's Mod для моего RP-сервера.

Работай итеративно: исследуй → измерь → реализуй → проверь → отчитайся. Не выдумывай данные, которые можно измерить или найти.

---

## 0. ФАКТЫ О ПРОЕКТЕ (не менять без согласования)

- Сервер: `D:\steamcmd\Server\garrysmod`
- Гейммод: `myrp` (база — Helix), карта `rp_industrial17_exceed`
- Запуск сервера: `D:\steamcmd\Server\start.bat` → `server_supervisor.ps1` (`+gamemode myrp`)
- Аддон HUD: `D:\steamcmd\Server\garrysmod\addons\aneurism_hud`
- Исходники аддона (рабочая копия): `C:\Users\geiad\OneDrive\Документы\Проект по умолчанию\aneurism_hud`
- Мост к Helix: `D:\steamcmd\Server\garrysmod\gamemodes\myrp\schema\plugins\myrp_zz_aniv_hud`
- Старый HUD геймода: `gamemodes\myrp\schema\plugins\myrp_hud`, хук `MYRP.CustomHUD.Paint`
- Клиент — отдельная машина: **все материалы и шрифты обязаны регистрироваться через `resource.AddFile`**
- Существующие аддоны `ulx-master`, `ulib-master` не трогать
- Перед любыми правками делать бэкап изменяемых файлов

Если папки/файлы уже существуют — сначала прочитай их, не перезаписывай вслепую. Чужой код не удалять.

---

## 1. ФАЗА ИССЛЕДОВАНИЯ (обязательна, не пропускать)

### 1.1. Что найти в интернете

Найди и изучи материалы об игре ANEURISM IV (Vellocet Software). Начни с:

- `https://aneurism.wiki.gg/wiki/HUD`
- `https://aneurism.wiki.gg/wiki/Controller`
- `https://aneurism.wiki.gg/wiki/Gameplay_Mechanics`
- `https://aneurism.wiki.gg/wiki/Inventory`
- страницы `File:` на вики (скриншоты HUD, спрайты, иконки)
- страница игры в Steam (скриншоты, описание HUD)
- геймплейные видео на YouTube (экраны HUD, инвентарь, рация)

Проверяй, что ссылки живые. Если страница недоступна — ищи альтернативу (Google-картинки, Steam Community, форумы).

### 1.2. Что скачать

Скачай все найденные референсы в `docs/refs/`:
- общий вид HUD;
- крупный план рации;
- иконки статусов;
- контекстные подсказки (Grab / Search);
- инвентарь / книгу;
- любые официальные спрайты и текстуры HUD.

Используй официальные изображения с вики/Steam. Если файл не скачивается — сделай скриншот страницы или сгенерируй аналог процедурно (скриптом), но **обязательно опиши в отчёте, что именно не удалось скачать**.

### 1.3. Измерения, а не «на глаз»

Для каждого референса напиши маленький скрипт (PowerShell + System.Drawing или Node + sharp), который:
- находит bounding box элемента по цветовым порогам;
- выдаёт координаты в пикселях и в долях (u0,v0,u1,v1);
- сохраняет результат в `docs/refs/measurements.json` и дублирует в Lua-таблицу.

Именно эти измеренные числа используй в коде. Никаких «примерно 0.235».

### 1.4. Таблица спецификации

Составь таблицу: `элемент | позиция (px при 1920×1080) | размер | цвет (hex) | шрифт | поведение`. Приложи её в отчёте.

### 1.5. УЖЕ ПОДТВЕРЖДЁННЫЕ ФАКТЫ (повторно проверено 27.11.2026 прямо с вики)

Не трать время на повторный поиск — эти страницы живы и доступны:

- `https://aneurism.wiki.gg/wiki/Controller` → «In the upper-left of the HUD, you have a radio which can be used to communicate with other Cortex fates», «To broadcast over the radio, press and hold `X`», «To mute/unmute the radio, press and hold `TAB`, then click on the radio interface on your UI», «Just prefix your telegram with `//` to send it through the special channels».
- `https://aneurism.wiki.gg/wiki/Gameplay_Mechanics` → «Cortex units … gain the ability to access the Voice propagator. you can mute and unmute it by clicking on it while holding TAB, and you speak through it by holding X»; «The Scum … speak on a different channel from the Cortex, so they cannot hear each other».
- `https://aneurism.wiki.gg/wiki/HUD` → 7 шкал `Sense / Blood / Air / Moisture / Nourishment / Sanity / Sepsis`, 0–100%; `moisture`, `nourishment`, `sanity` видны только при ≤75%.
- Локальная копия игры уже установлена: `D:\SteamLibrary\steamapps\common\ANEURISM IV` (Unity, `GameAssembly.dll`, `ANEURISM IV_Data`). Спрайты иконок извлечены оттуда через UnityPy (см. `README.md`), не выдумывай новые.
- Наблюдаемое несоответствие: на спрайте `Walkie_talkie (1).png` (371×413) запечёно `Hold K to broadcast`, а вики пишет `X`. Это нормально — текст dynamically перекрывается; используй конвар, а не запечённый текст.
- Текст может быть кириллическим: `DTextEntry` (не ручной перехват `KEY_*`) — единственный надёжный способ печатать кириллицу в GMod.

---

## 2. ВИЗУАЛЬНЫЙ СТИЛЬ (обязательные требования)

- Референсное разрешение — **1920×1080**. Масштаб: `S = ScrH()/1080`, clamp `0.55…1.65`, умножить на конвар `aniv_hud_scale`.
- **Пиксельная графика**: nearest-neighbour, без билинейного сглаживания. Все текстуры — с `$pointsample`.
- Все координаты и размеры при отрисовке — **целые пиксели** (`math.floor(v+0.5)`), иначе появляется полупиксельное мыло.
- Пропорции исходных спрайтов **сохранять** (не растягивать). Если ширина задана — высоту считать из нативного соотношения.
- Палитра (стартовые значения, уточнить по референсам):
  - болотно-зелёный фон/подсветка: `#1F5C1F`, яркий кислотный акцент: `#4CFF4C`
  - корпус рации: `#0E0E0E` … `#1C1C1C`, блик: `#3A3A3A`
  - LCD: янтарный `#C6A15B`, центр светлее `#E0C48A`, текст `#2A1A0C`
  - бумага/карточка: `#D8CDB4`, грязь `#8A7A5A`, символ `#2B2418`
  - кровь: `#C81E14`, кость/нога: `#E8B01E`, череп: `#2030D0`
  - «Grab»: `#4CD41E`, «Search»: `#E8E8E8`
- Шрифты (все OFL, положить в `resource/fonts`, зарегистрировать):
  - `Silkscreen` — подписи, счётчики, заголовки;
  - `VT323` — текст на LCD (тонкий терминальный);
  - `Press Start 2P` — «Grab»/«Search», если он ближе к референсу.
  - `surface.CreateFont` с `antialias = false`, размеры — целые, от 6 до 64.
- Любой текст — с 1px тёмной обводкой (`draw.SimpleText` + outline), чтобы читался на любом фоне.
- Общая атмосфера: грязно, тёмно, потёрто, «заводская радиорубка», лёгкий CRT.

---

## 3. КОМПОНЕНТЫ (детально)

### 3.1. Рация (верхний левый угол)

Референс: чёрный пластиковый корпус, крупный план, скруглённые углы, антенна сверху, рифлёная крутилка справа сверху, янтарный LCD с 4 строками текста.

- Позиция при 1080p: `x=22, y=16`. Размер — по нативному спрайту (пропорции ~371:413), ширина ≈250px.
- Корпус: тёмный пластик, скругление углов ~8–10%, верхний блик, царапины/потёртости, тонкая тёмная обводка.
- Антенна: вертикальный цилиндр, сегментированное основание, выходит за верх корпуса.
- Крутилка: рифлёный цилиндр справа сверху, читаемая тень.
- LCD: янтарный, скруглённые углы, лёгкий градиент (светлее в центре), внутри — тёмный пиксельный текст.
- Текст LCD, 4 строки:
  1. `UNMUTED.` / `MUTED.` / `BROADCASTING` (в зависимости от состояния)
  2. `Click to mute.`
  3. `Hold C to`
  4. `broadcast.`
  - Клавиша в строке 3 берётся из конвара (по умолчанию `C`).
  - При `BROADCASTING` — мигающая красная точка в правом верхнем углу экрана.
- Клик по корпусу (когда курсор активен) — переключение mute. Удержание `C` — трансляция.
- Если спрайт недоступен — рисовать корпус процедурно (rect + градиенты + скругления), но композиция должна остаться той же.

### 3.2. Книга / карточка инвентаря — УДАЛЕНА ПОЛНОСТЬЮ

По прямой просьбе пользователя из HUD вырезаны **и VGUI-инвентарь, и сама книжка-счётчик** с символом Ψ. Не рисовать ничего под рацией. `ANIV.GetWidgetRects()` больше не возвращает `book`; текстура `book_cover.png` и её VMT удалены из аддона и из `resource.AddFile`. API `OpenInventory/CloseInventory/ToggleInventory` оставлены пустыми заглушками для совместимости с гейммодом.

### 3.3. Иконки статусов (низ, чуть левее центра)

Референс: 4 иконки на тёмной подложке — красная капля крови, жёлтая сломанная кость, жёлтая нога, синий череп.

- **Важно:** это не плоские силуэты. У иконок есть контур и внутренние линии (блик на капле, трещина на кости, сустав на ноге, глазницы и зубы у черепа). Рисуй пиксель-арт сеткой (строки из `#`/`.`), а не примитивами.
- Размер ≈44px при 1080p, gap ≈12px, всего 4 иконки.
- Подложка: тёмная металлическая пластина с тайлингом 1 тексель = 1 px.
- Заполнение: цветная часть растёт снизу вверх пропорционально значению стата (0–100%), через `render.SetScissorRect`.
- При значении < 30% — мигание красным (2–4 Гц).
- Опциональные подписи под иконками (конвар, по умолчанию выключены).

### 3.4. Контекстные подсказки (Grab / Search)

Референс: слева, друг под другом, «Grab» — ярко-зелёный с галочкой, «Search» — белый с иконкой глаза. Шрифт жирный пиксельный с обводкой.

- Позиция: левее центра, `y ≈ 57%` высоты экрана.
- Иконка + отступ 7px + текст.
- «Grab» — зелёная галочка, «Search» — белый глаз (пиксель-арт).
- Показ по трассировке взгляда: если объект ближе `aniv_hud_prompt_dist` (по умолчанию 110) и подходит по классу/флагу.
- Поддержать `ent.ANIV_HudPrompt` (строка) и `ent.ANIV_HudPrompt == false` (скрыть).
- Конвар `aniv_hud_prompt_preview 1` — показать обе подсказки для проверки.

### 3.5. CRT-оверлей

- Скан-линии каждые 2–3px, alpha 10–20.
- Слабый зелёный тинт всего экрана.
- Виньетка по краям (10px).
- Лёгкое мерцание (sin от `CurTime()`).
- Всё выключается конваром `aniv_hud_crt 0`.
- Оверлей не должен перекрывать читаемость текста.

### 3.6. ФРАКЦИОННАЯ РАЦИЯ — НОВАЯ МЕХАНИКА (главное требование заказа)

Это не косметика: рация — переключатель режима общения. Реализуй **конечный автомат из 3 состояний** и не подменяй его простым mute.

#### 3.6.1. Начальное состояние

- При спавне/подключении `ANIV.State.radioActive = false`, `radioChatOpen = false`, `cursorUnlocked = false`.
- Рация **выключена**, обычный чат (`Y`/`say`, команды) работает как обычно.
- LCD показывает ровно 4 строки в том же положении/шрифте/цвете, что и в оригинале:
  1. `MUTED.`
  2. `Click to turn on.`
  3. `F3: unlock cursor`
  4. `Local chat active.`

#### 3.6.2. Курсор (F3)

- Клавиша `F3` (конвар `aniv_hud_radio_key`) **переключает** (toggle, не hold!) разблокировку курсора: `ANIV.ToggleCursorUnlocked()` → `gui.EnableScreenClicker(true/false)`.
- Более ранний режим `TAB`-удержание оставить как есть (он не конфликтует, оба условия объединяются OR).
- Пока курсор разблокирован, клик по корпусу рации (хитбокс **тот же**, что экспортирует `ANIV.GetWidgetRects().radio`) переключает рацию. Не хардкодь координаты во второй раз.
- Книжки в HUD больше нет; клики по активным виджетам проверять только через `ANIV.InRect`.
- Пока открыт чат-инпут рации, `GUIMousePressed` должен игнорировать клики по HUD, чтобы набор текста не выключал рацию случайно.

#### 3.6.3. Включение рации (кликаем по корпусу)

- `ANIV.ToggleRadio()` → `radioActive = true`, `muted = false`, `radioChatOpen = false`.
- В чат игроку выводится зелёное уведомление: `[RADIO] Фракционный канал включён. Нажмите X, чтобы говорить.`
- LCD:
  1. `UNMUTED.`
  2. `Click to turn off.`
  3. `Press X to talk.`
  4. `Faction channel.`
- **Обычный чат с этого момента заблокирован.** Перехватить клиентский хук `PlayerSay`: если `radioActive == true`, вернуть `""` и открыть инпут рации с уже набранным текстом. Это и есть «разговор на X» + защита от утечки сообщений в общий чат.
- Клавиша `X` (конвар `aniv_hud_radio_chat_key`) при включённой рации открывает чат-инпут. При выключенной — ничего не делает.

#### 3.6.4. Инпут фракционного чата

- Использовать **VGUI `DTextEntry`** (создаётся лениво, `vgui.Create` при первом открытии). Не перехватывай `KEY_*` вручную: кириллица в GMod через `input.IsKeyDown` не набирается.
- Фрейм: прямоугольник `ANIV.GetRadioChatRect()` — ширина `460*S`, высота `34*S`, центр по X, `y = ScrH()*0.62`. Рамка цвета LCD `#BA9654`, фон `#0A0C0A` alpha 225, заголовок `[ FACTION RADIO ]` зелёным `#5ED65C` над полем. Шрифт `ANIV.Font(20*S, true)` (VT323), текст `#2A1A0C`.
- `MakePopup()` + `RequestFocus()` при открытии, `KillFocus()` + `SetVisible(false)` при закрытии, затем пересчитать курсор через `ANIV.UpdateCursor()`.
- `Enter` → `ANIV_RadioChat` на сервер, `Esc` → закрыть инпут (рация остаётся включённой).
- Пока открыт инпут, LCD показывает:
  1. `BROADCASTING`
  2. `Type your message.`
  3. `Enter to send.`
  4. `Esc to cancel.`
  и мигает красная точка в правом верхнем углу LCD (2–5 Гц), как в оригинале.

#### 3.6.5. Выключение (второй клик)

- Повторный клик по тому же хитбоксу → `radioActive = false`, `muted = true`, закрыть инпут, сбросить `broadcasting`.
- В чат: `[RADIO] Обычный чат восстановлен.`
- LCD возвращается к 4 строкам из 3.6.1. `PlayerSay` снова пропускает сообщения в общий чат.
- Требование заказа: **только этот клик** возвращает обычное общение; `Esc` в инпуте рацию НЕ выключает.

#### 3.6.6. Серверная маршрутизация (обязательно, не «визуальный радар»)

- `util.AddNetworkString("ANIV_RadioChat")` (клиент→сервер, только текст) и `ANIV_RadioChatReceive` (сервер→клиенты).
- Клиент НЕ решает, кто услышит. Сервер сам определяет фракцию отправителя:
  1. `ply:GetCharacter():GetFaction()` (Helix), fallback `ply:Team()`;
  2. `ix.faction.indices[index].uniqueID / .name / .color` (в `myrp` это `combine` и `resistance`);
  3. получатели — все игроки с тем же `index`, `net.Send(recipients)`.
- Это дословно повторяет «Scum … speak on a different channel from the Cortex, so they cannot hear each other» из вики.
- Ограничения: trim, макс. 160 символов, anti-spam 0.5 c на игрока (`ply.ANIVLastRadio`), логирование в консоль сервера `[ANIV][RADIO] <nick> [uid]: <text>`.
- Пакет: `net.WriteEntity(sender)`, `uid`, `name`, `r/g/b` как `WriteUInt(8)`, `text`.
- Клиент при получении: `chat.AddText(ANIV.COL.green, "[RADIO ", factionColor, "· "..name, ANIV.COL.green, "] ", factionColor, nick, ANIV.COL.white, ": ", text)` + `surface.PlaySound("buttons/blip1.wav")` + хук `ANIV_RadioMessageReceived`.
- Конвар `aniv_hud_faction_chat` (по умолчанию `1`) может отключить отправку для тестов.

#### 3.6.7. Публичный API (добавить в `aniv_hud_init.lua`)

`ANIV.SetRadioActive(v)`, `ANIV.ToggleRadio()`, `ANIV.IsRadioActive()`, `ANIV.SetRadioChatOpen(open, initialText)`, `ANIV.IsRadioChatOpen()`, `ANIV.ToggleCursorUnlocked()`, `ANIV.IsCursorUnlocked()`. Хуки: `ANIV_RadioStateChanged(active)`, `ANIV_RadioChatStateChanged(open, initialText)`, `ANIV_CursorUnlockedChanged(unlocked)`, `ANIV_RadioMessageReceived(sender, uid, name, text)`.
`ANIV.SetMuted(v)`/`ToggleMute()` оставить как алиасы (`muted == not radioActive`) для совместимости со старым кодом.
Консоль: `aniv_hud_radio on|off` (без аргумента — toggle), `aniv_hud_reset` сбрасывает радио в OFF.

#### 3.6.8. Что НЕ делать

- Не начинать с включённой рации.
- Не вешать разговор на `Y` — разговор только на `X` (и переадресация из `PlayerSay` в тот же инпут).
- Не путать `mute` и `radio`: `Esc` закрывает ввод, но не выключает рацию.
- Не отправлять сообщение всем подряд — только своей фракции.
- Не рисовать текст `DTextEntry` вручную через `draw.SimpleText` (сломается кириллица).

### 3.7. ДВЕ ПОЛОСЫ: BLOOD И AIR (= выносливость/stamina)

Пользователь прямо попросил убрать всё, кроме здоровья и энергии. В HUD остаются
**только** `BLOOD` и `AIR` (в Aneurism IV `Air` — это stamina). Остальные четыре
полосы и legacy-иконки не рисуются.

- **Источник графики — реальный спрайт игры, а не процедурная имитация.**
  `tools/make_bar_textures.py` вырезает капсулу из `docs/refs/hud_bars_reference.png`
  (реальный скриншот из вики `File:HUDBarsUpdate17.png`, строка blood y=51..94)
  и создаёт:
  - `bar_frame.png` (265×39) — исходный потёртый серый корпус с чёрным внутренним окном;
  - `bar_noise.png` (128×32) — настоящий красный шум из игры, переведённый в grayscale.
  НЕ генерировать эти текстуры заново процедурным скриптом.
- Геометрия строго из спрайта: капсула `265×39`, внутреннее окно
  `x=20, y=8, w=225, h=23` в локальных пикселях текстуры; gap `8`;
  ряд по центру снизу, `y = ScrH() - 39*S - 30*S`. Всё через `ANIV.Snap()`.
- Корпус рисуется через `ANIV.DrawTex(ANIV.MAT.barFrame, ...)` — full UV, без
  растяжения пропорций и без скруглений «от балды».
- Незаполненная часть: серый шум (тинт `#60625C`), заполненная: тот же шум,
  закрашенный в `#C42C24` для blood и `#3460E2` для air, слева направо,
  ширина = `iw * value/100`. Через `ANIV.DrawTexTiled`, без `SetScissorRect`.
- Текст: ровно `BLOOD` и `AIR` ЗАГЛАВНЫМИ, по центру капсулы, `Silkscreen`
  `15*S`, цвет `#EEEEE6`, обводка 1px.
- Данные: `blood = Health/MaxHealth`, `air = LocalVar("stm")` (мост Helix).
  API: `ANIV.SetBlood(v)` / `ANIV.SetAir(v)` / `ANIV.SetStat("air", v)`.
- Конвар `aniv_hud_bars_enabled 1` (по умолчанию) → полосы; `0` → старые 4 иконки.
  Старый код иконок не удалять.

---

## 4. ПОВЕДЕНИЕ И УПРАВЛЕНИЕ

| Действие | По умолчанию | Конвар |
|---|---|---|
| Показать/скрыть HUD | `togglehud` | — |
| Разблокировать/заблокировать курсор (toggle) | `F3` | `aniv_hud_radio_key` |
| Курсор для кликов по HUD (hold) | удержание `TAB` | `aniv_hud_ui_key` |
| Включить/выключить фракционную рацию (изначально OFF) | клик по корпусу рации | `aniv_hud_radio` |
| Открыть фракционный чат (только когда рация ON) | `X` | `aniv_hud_radio_chat_key` |
| Отправить / отменить ввод | `Enter` / `Esc` | — |
| Визуальный индикатор передачи (hold) | `C` | `aniv_hud_broadcast_key` |
| Инвентарь (VGUI) | **полностью удалён** — не открывается ни клавишей, ни кликом | — |
| Взаимодействие | `E` | `aniv_hud_interact_key` |
| Фракционный чат включён | `1` | `aniv_hud_faction_chat` |
| Постоянный курсор (тест) | `0` | `aniv_hud_free_cursor` |
| Курсор при прицеливании | `0` | `aniv_hud_ads_click` |

- VGUI-панель инвентаря 4×4 удалена полностью; файл `aniv_hud_inventory.lua` из аддона убран. Вся подсистема предметов вырезана: состояние `inventory`, `ANIV_SetInventory`, `SetInventory/AddItem/RemoveItem/InventoryCount`, хуки `ANIV_InventoryChanged`/`ANIV_ItemDropped` и подача из моста. Оставлены только пустые заглушки старого API для совместимости с гейммодом.
- Курсор показывать только когда он нужен (`gui.EnableScreenClicker`), иначе не мешать прицеливанию.
- Все клики проверять по экспортированным прямоугольникам виджетов (`ANIV.GetWidgetRects()`), а не по магическим числам в двух местах.

---

## 5. ТЕХНИЧЕСКИЕ ТРЕБОВАНИЯ

### 5.1. Структура аддона

```
aneurism_hud/
├─ lua/autorun/aniv_hud_init.lua              -- конфиг, конвары, шрифты, материалы, API
├─ lua/autorun/aniv_hud_resources.lua         -- resource.AddFile для клиентских файлов
├─ lua/autorun/client/aniv_hud_core.lua       -- отрисовка
├─ lua/autorun/client/aniv_hud_input.lua      -- ввод, курсор, клики
├─ materials/aneurism_hud/*.png|*.vmt
├─ resource/fonts/*.ttf
├─ docs/refs/                                 -- скачанные референсы + measurements.json
├─ tools/generate_textures.ps1                -- процедурная генерация, если скачать не удалось
└─ README.md
```

### 5.2. Материалы

- Каждый PNG сопровождается `.vmt`:
  ```
  "UnlitGeneric"
  {
      "$basetexture" "aneurism_hud/NAME"
      "$translucent" "1"      -- только для спрайтов с прозрачностью
      "$vertexalpha" "1"
      "$vertexcolor" "1"
      "$nocull" "1"
      "$pointsample" "1"
  }
  ```
- В коде: `Material("aneurism_hud/NAME", "noclamp")`, фолбэк на `.png`, фолбэк на плоский цвет.
- **Никогда** не оставлять пользователя с розово-чёрным чекербоардом: если `mat:IsError()` — рисовать цветную заглушку.

### 5.3. Обязательная регистрация контента

GMod передаёт клиенту только Lua. Материалы и шрифты надо регистрировать:

```lua
if SERVER then
    for _, p in ipairs({ "materials/aneurism_hud/....png", "resource/fonts/....ttf" }) do
        if file.Exists(p, "GAME") then resource.AddFile(p) end
    end
end
```

Плюс `sv_allowdownload 1` в `cfg/server.cfg`.

### 5.4. Отрисовка 1:1

- `surface.DrawTexturedRectUV(x, y, w, h, u0, v0, u1, v1)` с явными UV.
- Целые `x, y, w, h`.
- Тайлинг поверхностей (бумага/металл): UV `0…w/texW`, `0…h/texH`, при `noclamp` — 1 тексель = 1 px.
- Никаких `DrawTexturedRect` без UV в новом коде.

### 5.5. Совместимость и стабильность

- Lua 5.1: без `!`, `&&`, `||`, `continue`, без BOM в файлах.
- `HUDPaint` + `HUDShouldDraw` (скрывать `CHudHealth`, `CHudBattery`, `CHudAmmo`, `CHudSecondaryAmmo`, `CHudDamageIndicator`).
- Проверка спектатора безопасная: `ply.Team() == TEAM_SPECTATOR` и `(ply.IsSpec and ply.IsSpec())` — `IsSpec()` есть не во всех геймодах.
- Никаких аллокаций таблиц каждый кадр в горячем пути.
- Все `GetConVar(...)` кэшировать при загрузке, если это горячий путь.
- Не ломать другие HUD-аддоны: если другой аддон уже рисует — не подавлять его без явного флага.

### 5.6. Интеграция с MYRP / Helix

Мост-плагин `myrp_zz_aniv_hud` (префикс `zz` = загрузка последней):
- снимает старый HUD: `hook.Remove("HUDPaint", "MYRP.CustomHUD.Paint")`;
- кормит HUD живыми данными: `Health/MaxHealth → blood`, `LocalVar("stm") → air/leg`, `character:GetData("sanity") → sanity`, `bones/bone → bone`;
- инвентарь персонажа больше не используется;
- не удаляет чужие хуки `ShouldHideBars`, `CanDrawAmmoHUD`, `HUDShouldDraw`.

Публичный API HUD: `ANIV.SetStat/GetStat`, `SetBlood/SetAir/SetSanity`, `SetRadioActive/ToggleRadio/IsRadioActive`, `SetRadioChatOpen/IsRadioChatOpen`, `ToggleCursorUnlocked/IsCursorUnlocked`, `SetMuted/ToggleMute` (алиасы радио), `SetBroadcasting`, `ToggleHUD`. Старые `SetInventory/AddItem/RemoveItem/InventoryCount/OpenInventory/CloseInventory/ToggleInventory` — пустые заглушки.

Рация не требует правки мост-плагина: серверная маршрутизация живёт в самом аддоне (`lua/autorun/aniv_hud_init.lua`, блок `SERVER`), поэтому работает и без Helix (fallback на `ply:Team()`). В `myrp` фракции заданы в `schema/factions/sh_combine.lua` (`combine`) и `sh_resistance.lua` (`resistance`) — именно их `uniqueID` и цвета используй в `[RADIO · …]` префиксе.

---

## 6. КРИТЕРИИ ПРИЁМКИ (Definition of Done)

Проверь и покажи результат по каждому пункту:

1. Рация, 2 полосы BLOOD/AIR, 2 подсказки и CRT видны и расположены как на референсах; книжки и инвентаря нет.
2. Ни одного розово-чёрного квадрата: `aniv_hud_materials` → все `error=false`; при отсутствии файла — плоский цвет, не чекербоард.
3. Пропорции спрайтов не искажены; на 1280×720, 1920×1080 и 2560×1440 HUD выглядит одинаково (масштабируется).
4. **Рация изначально OFF**: LCD `MUTED. / Click to turn on. / F3: unlock cursor / Local chat active.` `F3` разблокирует курсор; клик по рации → `radioActive=true`, LCD `UNMUTED. / Click to turn off. / Press X to talk. / Faction channel.`; `X` открывает инпут; `Enter` отправляет; `Esc` закрывает ввод, но рацию НЕ выключает; второй клик → OFF и обычный чат снова работает.
5. Фракционный чат доставляется **только** игрокам той же фракции: `combine` не слышит `resistance` и наоборот (проверить с двумя клиентами, лог сервера `[ANIV][RADIO]`). Попытка написать в обычный чат при включённой рации уходит в рацию, а не в общий чат.
6. Инвентаря и книжки-счётчика в HUD нет: ни `C`, ни `Q`, ни клик не открывают ничего; под рацией ничего не рисуется.
7. `Grab`/`Search` появляются по взгляду и исчезают при отдалении.
8. `togglehud` скрывает/показывает HUD; старый HUD геймода не дублируется.
9. Нет ошибок Lua в `console.log` сервера и в клиентской консоли (проверить после рестарта).
10. Синтаксис всех Lua-файлов проверен парсером (luaparse, Lua 5.1), BOM отсутствует.
11. Все файлы синхронизированы в `D:\steamcmd\Server\garrysmod\addons\aneurism_hud`, хэши совпадают с рабочей копией.

---

## 7. ИЗВЕСТНЫЕ ГРАБЛИ (уже проверены на этом проекте)

- **Розово-чёрный чекербоард** = клиент не получил материал. Причина — не UV, а отсутствие `resource.AddFile`. Проверять в первую очередь.
- `Material()` с `.vmt` + невалидные ключи (`nocompress`, `nolod`, `nomip`) — игнорируются, но лучше не писать.
- `pointsample` нужен для пиксель-арта; без него текстура мылится.
- `IsSpec()` нет в базовом GMod/Helix → `attempt to call method 'IsSpec' (a nil value)`.
- PowerShell `Set-Content -Encoding UTF8` добавляет BOM и ломает Lua → писать через `[IO.File]::WriteAllText($p, $txt, (New-Object Text.UTF8Encoding($false)))`.
- `npm.ps1` блокируется политикой → `C:\Program Files\nodejs\npm.cmd`.
- Клиент не увидит изменения без рестарта сервера и переподключения.
- NPOT-текстуры (371×413) работают, но требуют `noclamp` для тайлинга.
- Кириллица не набирается через `input.IsKeyDown(KEY_...)` — только `DTextEntry` (он использует системный ввод).
- Клиентский `PlayerSay` возвращает `""` — сообщение не уходит на сервер; это рабочий способ перехватить обычный чат.
- `DTextEntry:MakePopup()` сам включает мышь; после `KillFocus()` обязательно вызвать `ANIV.UpdateCursor()`, иначе курсор «залипнет».
- `net.WriteType(Color)` надёжнее не использовать — передавай r/g/b через `WriteUInt(8)`.
- **Главная причина розовых шашечек здесь:** `.vmt` с `$basetexture "aneurism_hud/name"` ищет `.vtf`, которого нет. `Material()` при этом возвращает *не* error-материал, а валидный материал с текстурой `_error`. Проверять надо имя `$basetexture`, а не только `IsError()`; надёжнее грузить сразу `Material("aneurism_hud/name.png", "noclamp")` — GMod понимает PNG напрямую (см. `lua/menu/errors.lua` в исходниках игры).
- `gui.MousePos()` / `self:CursorPos()` возвращают **два** значения. Вызов вида `ANIV.InRect(gui.MousePos(), x, y, w, h)` обрезает их до одного и даёт `h = nil` → ошибка каждый кадр. Всегда сначала `local mx, my = ...`.

---

## 8. ЗАПРЕЩЕНО

- Выдумывать UV/координаты вместо измерения.
- Хардкодить абсолютные пиксели без масштаба `S`.
- Растягивать спрайт, ломая пропорции.
- Оставлять `DrawTexturedRect` без UV и без проверки `IsError()`.
- Трогать `ulx`, `ulib`, `myrp_hud` (кроме снятия одного хука в мосте).
- Удалять существующие файлы без бэкапа.
- Сдавать работу без проверки синтаксиса и без отчёта.

---

## 9. ФОРМАТ ОТЧЁТА В КОНЦЕ

1. Что найдено в интернете (ссылки, что скачано в `docs/refs/`, что не удалось).
2. Таблица измерений: элемент → координаты/размер/цвет/UV.
3. Список созданных/изменённых файлов с путями.
4. Как проверял (команды, конвары, что смотреть в консоли).
5. Что получилось 1:1, а что пришлось аппроксимировать и почему.
6. Что нужно сделать пользователю (рестарт, переподключение, проверки).
