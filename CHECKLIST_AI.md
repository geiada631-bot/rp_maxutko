# CHECKLIST ДЛЯ ДРУГОЙ НЕЙРОНКИ — ANEURISM IV HUD (GMod)

Прочитай этот файл **целиком** перед любыми правками. Он описывает, что уже сделано,
почему сделано именно так, и какие ошибки нельзя повторить. Язык ответов пользователя — русский.

---

## 0. Кратко: что это за репозиторий

Это **самостоятельный аддон Garry's Mod**, который воссоздаёт HUD игры
**ANEURISM IV** (Vellocet Software) и добавляет **фракционную рацию**.

- Версия: **1.1.0**
- Корень репозитория = содержимое папки аддона. То есть чтобы поставить,
  нужно скопировать **весь этот репозиторий** в
  `<GMod>/garrysmod/addons/aneurism_hud/` (внутри останутся `lua/`, `materials/`, `resource/`).
- Две рабочие копии серверов пользователя:
  - `D:\steamcmd\Server\garrysmod\addons\aneurism_hud`
  - `D:\steamcmd2\Server\garrysmod\addons\aneurism_hud`
- Оба сервера используют гейммод `myrp` (на базе Helix), карта `rp_industrial17_exceed`.
- Мост к Helix лежит в `docs/integration/myrp_zz_aniv_hud/` — **это справочная копия**,
  не часть аддона. В бою он должен лежать в
  `<GMod>/garrysmod/gamemodes/myrp/schema/plugins/myrp_zz_aniv_hud/`.

---

## 1. Карта файлов и кто за что отвечает

| Файл | Роль |
|---|---|
| `lua/autorun/aniv_hud_init.lua` | Общий bootstrap: конвары, палитра, состояние, шрифты, материалы, 1:1-хелперы, публичный API, **серверная маршрутизация рации**, конкоманды |
| `lua/autorun/aniv_hud_resources.lua` | Только SERVER: `resource.AddFile()` для 24 файлов (PNG/VMT/TTF) |
| `lua/autorun/client/aniv_hud_core.lua` | Отрисовка: рация + LCD, книга, **6 полос статов**, legacy-4-иконки, подсказки, рамка чата, CRT. Экспортирует `ANIV.GetWidgetRects()`, `ANIV.GetRadioChatRect()`, `ANIV.GetBarRects()` |
| `lua/autorun/client/aniv_hud_input.lua` | Ввод: F3/X/Q/E/TAB, клики по виджетам, `DTextEntry` чата, перехват `PlayerSay`, курсор |
| `lua/autorun/client/aniv_hud_inventory.lua` | VGUI-панель инвентаря 4×4 (`ANIV_Inventory`) |
| `materials/aneurism_hud/*.png|vmt` | Спрайт рации 371×413 (с вики), обложка книги, бумага/пластик/металл, иконки |
| `resource/fonts/*.ttf` | Silkscreen (пиксельный), VT323 (LCD), обе OFL |
| `docs/refs/measurements.json` | **Все измерения в пикселях + UV + hex-цвета. Не выдумывай числа — бери отсюда** |
| `docs/PROMPT_ANEURISM_IV_UI.md` | Очень подробный промт/спецификация (410+ строк). Главный источник истины по ТЗ |
| `docs/integration/myrp_zz_aniv_hud/` | Мост к Helix (справка): снимает старый HUD и кормит ANIV живыми данными |
| `tools/generate_textures.ps1`, `tools/prepare_icons.py` | Генерация текстур/иконок заново |

---

## 2. Состояние рации (конечный автомат) — не упрощать до mute!

Изначально: `radioActive=false`, `radioChatOpen=false`, `cursorUnlocked=false`,
`muted=true`. Обычный чат работает.

| Действие | Переход | LCD (4 строки, тот же шрифт/позиция/цвет) |
|---|---|---|
| Старт | OFF | `MUTED.` / `Click to turn on.` / `F3: unlock cursor` / `Local chat active.` |
| `F3` | разблокирует курсор (toggle) | без изменений |
| Клик по корпусу рации | → ON, `muted=false` | `UNMUTED.` / `Click to turn off.` / `Press X to talk.` / `Faction channel.` |
| `X` при ON | открыть инпут | `BROADCASTING` / `Type your message.` / `Enter to send.` / `Esc to cancel.` + мигающая красная точка |
| `Enter` | отправить по сети, закрыть инпут | → ON |
| `Esc` | закрыть инпут, **рацию НЕ выключать** | → ON |
| Повторный клик | → OFF, обычный чат снова работает | → START |

Пока рация ON, клиентский хук `PlayerSay` возвращает `""` и открывает инпут
с набранным текстом — обычный чат недоступен. Вернуть его можно **только** кликом по рации.

---

## 3. Управление и конвары (все — `CreateClientConVar`,=TRUE,FALSE)

| Конвар | Дефолт | Назначение |
|---|---|---|
| `aniv_hud_radio_key` | `F3` | toggle курсора для клика по рации |
| `aniv_hud_radio_chat_key` | `X` | открыть фракционный чат, когда рация ON |
| `aniv_hud_broadcast_key` | `C` | hold-индикатор передачи (визуальный; в игре X — голос) |
| `aniv_hud_faction_chat` | `1` | отправка в серверный фракционный канал |
| `aniv_hud_ui_key` | `TAB` | временный курсор (удержание), как в игре |
| `aniv_hud_inventory_key` | `Q` | книга/инвентарь |
| `aniv_hud_interact_key` | `E` | Grab/Search |
| `aniv_hud_free_cursor` | `0` | постоянный курсор (тест) |
| `aniv_hud_ads_click` | `0` | курсор при прицеливании |
| `aniv_hud_prompt_preview` | `0` | показать обе подсказки сразу |
| `aniv_hud_prompt_dist` | `110` | дальность подсказок |
| `aniv_hud_icon_labels` | `0` | подписи под иконками |
| `aniv_hud_scale` | `1` | масштаб от 1080p |
| `aniv_hud_crt` | `1` | скан-линии/виньетка |
| `aniv_hud_enabled` | `1` | общий флаг |

Команды: `togglehud`, `aniv_hud_toggle`, `aniv_hud_radio on|off` (без аргумента — toggle),
`aniv_hud_reset`, `aniv_hud_debug`, `aniv_hud_materials`, `myrp_aniv_hud_status` (из моста).

---

## 4. Публичный API и хуки (не ломай совместимость)

`ANIV.SetStat/GetStat`, `SetBlood/SetAir/SetSanity`,
`SetRadioActive/ToggleRadio/IsRadioActive`,
`SetRadioChatOpen/IsRadioChatOpen`, `ToggleCursorUnlocked/IsCursorUnlocked`,
`SetMuted/ToggleMute` (**алиас**: `muted == not radioActive`),
`SetBroadcasting`, `SetInventory/AddItem/RemoveItem/InventoryCount`, `ToggleHUD`.

Хуки: `ANIV_StatChanged`, `ANIV_RadioStateChanged`, `ANIV_RadioChatStateChanged`,
`ANIV_CursorUnlockedChanged`, `ANIV_MuteChanged`, `ANIV_InventoryChanged`,
`ANIV_Interact`, `ANIV_ItemDropped`, `ANIV_RadioMessageReceived`,
`ANIV_HUDVisibilityChanged`, `ANIV_InventoryOpened/Closed`.

Хелперы отрисовки: `ANIV.Scale/S`, `Snap`, `Font`, `Text`, `InRect`, `Key`,
`ThickLine`, `MatReady`, `RefreshMaterials`, `DrawTex`, `DrawTexTiled`,
`DrawTexUV`, `DrawIcon`, `GetWidgetRects`, `GetRadioChatRect`.

---

## 5. Сетевой протокол рации (сервер авторитетен)

- `ANIV_RadioChat`: клиент → сервер, только `net.WriteString(text)`.
- Сервер: trim, макс. 160 символов, anti-spam 0.5 c (`ply.ANIVLastRadio`),
  фракция = `ply:GetCharacter():GetFaction()` (fallback `ply:Team()`),
  получатели = все с тем же индексом (`ix.faction.indices[index]`), `net.Send(recipients)`.
  Лог: `[ANIV][RADIO] <ник> [uid]: <текст>`.
- `ANIV_RadioChatReceive`: сервер → клиенты:
  `WriteEntity(sender)`, `WriteString(uid)`, `WriteString(name)`,
  `WriteUInt(r,8)`, `WriteUInt(g,8)`, `WriteUInt(b,8)`, `WriteString(text)`.
- Клиент печатает `chat.AddText` с зелёным префиксом `[RADIO · NAME]`, проигрывает
  `buttons/blip1.wav`, дёргает хук `ANIV_RadioMessageReceived`.
- `combine` не слышит `resistance` — это прямо из вики (Cortex/Scum разные каналы).

---

## 6. Правила 1:1 (не нарушать)

- Референс 1920×1080; `S = clamp(ScrH()/1080, 0.55, 1.65) * aniv_hud_scale`.
- Все координаты/размеры — целые пиксели через `ANIV.Snap()`.
- Пропорции спрайтов сохранять; TextureUV только явный; `noclamp` + `$pointsample`.
- Радио: `x=22*S, y=16*S, w=250*S, h≈278*S`; LCD UV из `measurements.json`
  (источник 371×413: `u0=93/371, v0=254/413, u1=233/371, v1=340/413`).
- Книга: `x=radio.x+56*S, y=radio.y+radio.h+10*S, 126×158`.
- **Полосы (по просьбе пользователя, по умолчанию):** ТОЛЬКО `BLOOD` и `AIR` (stamina). Капсула `265×39` — это реальный спрайт из игры (`bar_frame.png`), внутреннее окно `x20/y8/w225/h23`; gap `8`, ряд по центру внизу, `y = ScrH()-39*S-30*S`. Заливка = `bar_noise.png` (настоящий шум из игры) с tint `#C42C24`/`#3460E2`, ширина `iw*value/100`; незаполненная часть — серый шум. Текст ЗАГЛАВНЫМИ `BLOOD`/`AIR`, `Silkscreen 15*S`. Конвар `aniv_hud_bars_enabled 0` возвращает legacy-иконки. **Не перегенерируй текстуры процедурно** — они вырезаны из `docs/refs/hud_bars_reference.png` скриптом `tools/make_bar_textures.py`.
- Иконки (legacy): 44px, gap 12, низ, чуть левее центра. Подсказки: `y=0.57*ScrH`.
- Никогда не показывать розово-чёрный чекербоард — fallback на плоский цвет.

---

## 7. УЖЕ ИСПРАВЛЕННЫЕ ОШИБКИ — НЕ ПОВТОРЯТЬ

1. **VMT → `.vtf` которого нет.** `Material("aneurism_hud/name")` возвращает
   *валидный* материал с текстурой `_error`, и `IsError()` это не ловит.
   Поэтому в `M()` сначала грузится `Material("aneurism_hud/name.png","noclamp")`;
   дополнительно `ANIV.MatReady()` проверяет имя `$basetexture` на `error`.
2. **Множественные возвраты в списке аргументов.**
   `ANIV.InRect(gui.MousePos(), x, y, w, h)` и `ANIV.InRect(self:CursorPos(), ...)`
   обрезают два значения до одного → `h=nil` → ошибка каждый кадр.
   Всегда `local mx, my = ...` и только потом вызов.
3. **`IsSpec()` есть не везде.** Проверка спектатора только
   `(ply.IsSpec and ply:IsSpec())`.
4. **Кириллица не набирается через `KEY_*`.** Только `DTextEntry` ( системный ввод ).
5. **`MakePopup()` меняет мышь за кулисами.** После закрытия чата:
   `ANIV.State.uiMode = nil; ANIV.UpdateCursor()`.
6. **PowerShell `Set-Content -Encoding UTF8` добавляет BOM и ломает Lua.**
   Писать через `[IO.File]::WriteAllText($p,$txt,(New-Object Text.UTF8Encoding($false)))`.
7. **Без `resource.AddFile` клиент видит шашечки.** Все 24 файла зарегистрированы;
   `sv_allowdownload 1` в `cfg/server.cfg`.
8. **Клиент не видит правки Lua без рестарта/переподключения.**

---

## 8. Чек-лист проверки перед сдачей

- [ ] Прочитал `docs/PROMPT_ANEURISM_IV_UI.md` и `docs/refs/measurements.json`.
- [ ] Сделал бэкап каждого изменяемого файла.
- [ ] Lua 5.1: нет `!`, `&&`, `||`, `continue`; нет BOM.
- [ ] Синтаксис проверен парсером:
      `node check.js <path>` с `luaparse` (установка: `C:\Program Files\nodejs\npm.cmd install luaparse --prefix <temp>`).
- [ ] Нет новых вызовов вида `InRect(gui.MousePos(), ...)` / `InRect(CursorPos(), ...)`.
- [ ] Новые материалы грузятся через `.png` первыми; `MatReady()` не обходится.
- [ ] Рация стартует **выключенной**; `Esc` не выключает её; второй клик возвращает чат.
- [ ] Сообщение уходит только своей фракции; лог сервера `[ANIV][RADIO]` есть.
- [ ] `aniv_hud_materials` → у всех строк `ready=true` и имя текстуры не `_error`.
- [ ] `aniv_hud_debug` показывает ожидаемые `radio/radioChat/cursorUnlocked`.
- [ ] HUD одинаково масштабируется на 1280×720 / 1920×1080 / 2560×1440.
- [ ] Хуки моста (`MYRP.CustomHUD.Paint`) снимаются, но чужие хуки не удалены.
- [ ] Файлы синхронизированы в обе копии сервера (`D:\steamcmd`, `D:\steamcmd2`), хэши совпадают.
- [ ] Отчёт пользователю: что менял, что проверял, что нужно перезапустить.

---

## 9. Быстрые ответы на частые вопросы другой модели

**«Почему шашечки, хотя файлы скачаны?»** — VMT без VTF; читай раздел 7.1.
**«Где взять точные UV?»** — `docs/refs/measurements.json`, не «на глаз».
**«Почему X не работает?»** — рация должна быть ON; `X` открывает чат, а не голос.
**«Как поменять клавиши?»** — конвары из раздела 3, не правь код.
**«Нужно ли трогать myrp_hud?»** — нет; мост лишь снимает один хук `HUDPaint`.
**«Можно ли удалить VMT?»** — не надо: они зарегистрированы в `resource.AddFile`;
загрузка идёт через PNG, но VMT оставляем для совместимости.
**«Где источники спрайтов?»** — вики `File:Walkie_talkie_(1).png`, иконки извлечены
из `ANEURISM IV_Data/data.unity3d` (UnityPy) и game-icons.net; см. `README.md`.

---

## 10. Что осталось незаделанным / известные отличия

- Оригинал показывает **7 шкал** (Sense/Blood/Air/Sanity/Sepsis/Nourishment/Moisture);
  по прямой просьбе пользователя оставлены **только BLOOD и AIR**. Старые 4 иконки
  доступны через `aniv_hud_bars_enabled 0`. Референс 7 полос — в `docs/refs/`.
- Текст LCD адаптирован под фракционную рацию; шрифт/положение/цвет — 1:1.
- Голосовая трансляция заменена текстовым чатом (по просьбе пользователя).
- Шрифты — OFL-аналоги (`Silkscreen`, `VT323`), не родной TMP-атлас игры.
- Ассеты ANEURISM IV — авторский материал Vellocet Software; только для личных проектов.
