# ЧЕКЛИСТ ДЛЯ ДРУГОЙ НЕЙРОНКИ — ANEURISM IV HUD (Garry's Mod)

> Прочитай файл целиком **до** любой правки. Здесь зафиксировано, что уже сделано,
> почему сделано именно так, какие ошибки исправлены и как всё проверить.
> Пользователь говорит по-русски — отвечай по-русски.

---

## 0. Что это за репозиторий

Самостоятельный аддон GMod, который воссоздаёт HUD игры **ANEURISM IV**
(Vellocet Software) и добавляет **фракционную рацию**. Версия **1.1.0**.

**Корень репозитория = содержимое папки аддона.** Installing:
скопируй весь этот репозиторий в `<GMod>/garrysmod/addons/aneurism_hud/`
(внутри останутся `lua/`, `materials/`, `resource/`, `docs/`, `tools/`).

Рабочие копии на машине пользователя:
- `D:\steamcmd\Server\garrysmod\addons\aneurism_hud`
- `D:\steamcmd2\Server\garrysmod\addons\aneurism_hud`

Гейммод: `myrp` (на базе Helix), карта `rp_industrial17_exceed`.
Мост к Helix лежит в `docs/integration/myrp_zz_aniv_hud/` — **справка**, не часть аддона;
в бою он должен быть в `<GMod>/garrysmod/gamemodes/myrp/schema/plugins/myrp_zz_aniv_hud/`.

**Чего в этом репозитории НЕТ:** меню взаимодействия `myrp_weapon_interaction`.
Оно живёт в другом репозитории `suda-moi-proecti` (исходники сервера). Здесь только
текстуры `ui_button_bg.png` / `ui_panel.png`, которые оно использует.

---

## 1. Карта файлов

| Файл | Ответственность |
|---|---|
| `lua/autorun/aniv_hud_init.lua` | Конвары, палитра, состояние, шрифты, материалы, хелперы 1:1, публичный API, **серверная маршрутизация рации**, конкоманды |
| `lua/autorun/aniv_hud_resources.lua` | Только SERVER: `resource.AddFile()` — **30 файлов** (PNG/VMT/TTF) |
| `lua/autorun/client/aniv_hud_core.lua` | Отрисовка: рация + LCD, книга, **2 полосы BLOOD/AIR**, legacy-4-иконки, подсказки, рамка чата, CRT. Экспортирует `ANIV.GetWidgetRects()`, `ANIV.GetRadioChatRect()`, `ANIV.GetBarRects()` |
| `lua/autorun/client/aniv_hud_input.lua` | Ввод: F3/X/Q/E/TAB, клики, `DTextEntry` чата, перехват `PlayerSay`, курсор |
| `materials/aneurism_hud/walkie_talkie.png` | Спрайт рации 371×413, вики `File:Walkie_talkie_(1).png` |
| `materials/aneurism_hud/bar_frame.png`, `bar_noise.png` | Настоящие полосы: капсула 265×39 и шум 128×32 из `docs/refs/hud_bars_reference.png` |
| `materials/aneurism_hud/ui_button_bg.png`, `ui_panel.png` | Настоящие UI-спрайты из `data.unity3d`: кнопка 352×48 и фон 640×576 |
| `materials/aneurism_hud/icon_*.png` | Оригинальные иконки капли/черепа/глаза/галочки и game-icons.net кость/нога |
| `resource/fonts/*.ttf` | Silkscreen (пиксель), VT323 (LCD), лицензия OFL |
| `docs/refs/measurements.json` | Все измерения, UV и hex-цвета. **Не выдумывай числа — бери отсюда** |
| `docs/PROMPT_ANEURISM_IV_UI.md` | Полная спецификация (400+ строк), главный источник ТЗ |
| `docs/integration/myrp_zz_aniv_hud/` | Справочная копия моста к Helix |
| `tools/generate_textures.ps1` | Paper/plastic/metal/book_cover (детерминированный сид) |
| `tools/prepare_icons.py` | Пересборка иконок |
| `tools/make_bar_textures.py` | Вырезает `bar_frame.png`/`bar_noise.png` из референса |
| `tools/extract_unity_ui.py` | Извлекает `ui_button_bg.png`/`ui_panel.png`/`icon_check.png` из `data.unity3d` (UnityPy) |

---

## 2. Что именно просил пользователь (последние решения)

1. **HUD здоровья/энергии:** только `BLOOD` и `AIR` (= stamina). Остальные полосы
   (moisture/nourishment/sanity/sepsis) убраны по прямой просьбе. Старые 4 иконки
   доступны через `aniv_hud_bars_enabled 0`, но по умолчанию НЕ рисуются.
2. **Меню взаимодействия:** оформление под Aneurism IV, **только кнопки** —
   без панели, заголовка, "`ДЕЙСТВИЕ`" и подсказок. Одно действие = одна кнопка.
   Надпись не должна выходить за кнопку (авто-подбор шрифта 17→9 и `...`).
   Логика/клавиши не менялись. Код меню — в другом репозитории.
3. **Инвентарь HUD (книжка) вырезан полностью**, но серверный инвентарь MYRP/Helix оформлен как в Aneurism IV: чёрный фон, модель персонажа в центре, **24 слота кольцом вокруг** (`inv_slot.png` из `data.unity3d`). При наведении слот подсвечивается, у курсора сверху-справа выводится `empty` белым или название предмета красным. Шрифт подсказки — **точная копия игрового** `Special Elite` (TMP `SpecialElite SDF Atlas` → `resource/fonts/SpecialElite-Regular.ttf`), НЕ подбирать другой. Движение/перетаскивание осталось нативным Helix. Код — в `myrp_factionselect/cl_plugin.lua` (репозиторий `suda-moi-proecti`).
4. **Инвентарь и книжка-счётчик вырезаны полностью.** Нет файла `aniv_hud_inventory.lua`, нет панели `INVENTORY`, нет книжки с Ψ под рацией, нет состояния `inventory`, нет `ANIV_SetInventory`, нет хуков `ANIV_InventoryChanged`/`ANIV_ItemDropped`, мост больше не подаёт предметы. Старые API-функции инвентаря — пустые заглушки для совместимости. Конвара `aniv_hud_inventory_key` больше нет.
5. **Фракционная рация:** выключена при старте; `F3` разблокирует курсор;
   клик по рации включает её; `X` открывает фракционный чат; второй клик
   возвращает обычный чат.

---

## 3. Визуальная спецификация (не менять «на глаз»)

- Референс 1920×1080. `S = clamp(ScrH()/1080, 0.55, 1.65) * aniv_hud_scale`.
- Всё в целых пикселях через `ANIV.Snap()`. UV явный, `noclamp` + `$pointsample`.
- **Радио:** `x=22*S, y=16*S, w=250*S, h≈278*S`; LCD UV из measurements.json
  (371×413: `u0=93/371, v0=254/413, u1=233/371, v1=340/413`).
- **Книга:** `x=radio.x+56*S`, `y=radio.y+radio.h+10*S`, `126×158`, символ Ψ.
- **Полосы:** капсула `265×39`, interior `x20/y8/w225/h23`, gap `8`,
  ряд по центру внизу `y=ScrH()-39*S-30*S`. Фон — `bar_frame.png`,
  заливка — `bar_noise.png` с tint `#C42C24` (blood) / `#3460E2` (air),
  ширина `iw*value/100`; незаполненное — серый шум. Текст `BLOOD`/`AIR`
  заглавными, Silkscreen `15*S`, белый `#EEEEE6`, обводка 1px.
- **Подсказки Grab/Search:** `y=0.57*ScrH`, иконки + 7px + текст.
- **CRT:** скан-линии каждые 2–3px, alpha 10–20, виньетка, конвар `aniv_hud_crt`.
- Никогда не показывать розово-чёрный чекербоард — fallback на плоский цвет.

---

## 4. Рация: конечный автомат

Старт: `radioActive=false`, `radioChatOpen=false`, `cursorUnlocked=false`, `muted=true`.

| Действие | Переход | LCD (4 строки) |
|---|---|---|
| Старт | OFF | `MUTED.` / `Click to turn on.` / `F3: unlock cursor` / `Local chat active.` |
| `F3` | toggle курсора | без изменений |
| Клик по корпусу | ON | `UNMUTED.` / `Click to turn off.` / `Press X to talk.` / `Faction channel.` |
| `X` при ON | ввод | `BROADCASTING` / `Type your message.` / `Enter to send.` / `Esc to cancel.` + красная точка |
| `Enter` | отправить, закрыть ввод | ON |
| `Esc` | закрыть ввод, **НЕ выключать рацию** | ON |
| Повторный клик | OFF, обычный чат вернулся | START |

Пока рация ON, клиентский `PlayerSay` возвращает `""` и открывает инпут с текстом.
Обычный чат возвращается **только** кликом по рации.

---

## 5. Конвары и команды

| Конвар | Дефолт | Назначение |
|---|---|---|
| `aniv_hud_radio_key` | `F3` | toggle курсора |
| `aniv_hud_radio_chat_key` | `X` | фракционный чат при ON |
| `aniv_hud_broadcast_key` | `C` | визуальный hold-индикатор |
| `aniv_hud_faction_chat` | `1` | отправка в серверный канал |
| `aniv_hud_ui_key` | `TAB` | временный курсор |
| `aniv_hud_interact_key` | `E` | Grab/Search |
| `aniv_hud_free_cursor` | `0` | постоянный курсор (тест) |
| `aniv_hud_ads_click` | `0` | курсор при прицеливании |
| `aniv_hud_prompt_preview` | `0` | обе подсказки сразу |
| `aniv_hud_prompt_dist` | `110` | дальность подсказок |
| `aniv_hud_icon_labels` | `0` | подписи legacy-иконок |
| `aniv_hud_bars_enabled` | `1` | 2 полосы ↔ 4 иконки |
| `aniv_hud_scale` | `1` | масштаб от 1080p |
| `aniv_hud_crt` | `1` | CRT |
| `aniv_hud_enabled` | `1` | общий флаг |

Команды: `togglehud`, `aniv_hud_toggle`, `aniv_hud_radio on|off`,
`aniv_hud_reset`, `aniv_hud_debug`, `aniv_hud_materials`, `myrp_aniv_hud_status`.

---

## 6. Публичный API и хуки (не ломать)

`ANIV.SetStat/GetStat`, `SetBlood/SetAir/SetSanity/SetMoisture/SetNourishment/SetSepsis`,
`SetRadioActive/ToggleRadio/IsRadioActive`, `SetRadioChatOpen/IsRadioChatOpen`,
`ToggleCursorUnlocked/IsCursorUnlocked`, `SetMuted/ToggleMute` (алиас: `muted == not radioActive`),
`SetBroadcasting`, `ToggleHUD` (старые функции инвентаря — пустые заглушки),
`MatReady/RefreshMaterials`, `DrawTex/DrawTexTiled/DrawTexUV/DrawIcon`,
`GetWidgetRects/GetRadioChatRect/GetBarRects`.

Хуки: `ANIV_StatChanged`, `ANIV_RadioStateChanged`, `ANIV_RadioChatStateChanged`,
`ANIV_CursorUnlockedChanged`, `ANIV_MuteChanged`,
`ANIV_Interact`, `ANIV_ItemDropped`, `ANIV_RadioMessageReceived`,
`ANIV_HUDVisibilityChanged`.

---

## 7. Сеть рации (сервер авторитетен)

- `ANIV_RadioChat`: клиент → сервер, только `net.WriteString(text)`.
- Сервер: trim, ≤160 символов, anti-spam 0.5 c, фракция =
  `ply:GetCharacter():GetFaction()` (fallback `Team()`), получатели — те же
  `ix.faction.indices[index]`, лог `[ANIV][RADIO] <ник> [uid]: <текст>`.
- `ANIV_RadioChatReceive`: `WriteEntity`, `uid`, `name`, `r/g/b` как `WriteUInt(8)`, `text`.
- Клиент: `chat.AddText` с префиксом `[RADIO · NAME]`, звук `buttons/blip1.wav`,
  хук `ANIV_RadioMessageReceived`.
- `combine` не слышит `resistance` (как Cortex/Scum в вики).

---

## 8. Откуда текстуры и как их пересоздать

- Рация: вики `File:Walkie_talkie_(1).png`; иконки — из `data.unity3d` (UnityPy)
  и game-icons.net.
- `bar_frame.png` / `bar_noise.png` вырезаны из `docs/refs/hud_bars_reference.png`
  скриптом `tools/make_bar_textures.py`. **Не перегенерируй процедурно.**
- `ui_button_bg.png` / `ui_panel.png` / `icon_check.png` извлечены из
  `ANEURISM IV_Data/data.unity3d` скриптом `tools/extract_unity_ui.py` (UnityPy).
- Шрифты Silkscreen/VT323 — OFL-аналоги (в игре TMP-атлас).
- Ассеты ANEURISM IV — авторский материал Vellocet Software, только личные проекты.

---

## 9. Исправленные ошибки — НЕ ПОВТОРЯТЬ

1. **VMT без VTF:** `Material(".../name")` возвращает валидный материал с текстурой
   `_error`; `IsError()` не ловит. Загрузка через `.png` первым + `MatReady()`.
2. **Multi-return в аргументах:** `InRect(gui.MousePos(), ...)` обрезает 2 значения
   до 1 → `h=nil`. Всегда `local mx, my = ...`.
3. **`IsSpec()` есть не везде:** `(ply.IsSpec and ply:IsSpec())`.
4. **Кириллица не через `KEY_*`:** только `DTextEntry`.
5. **`MakePopup()` меняет мышь:** после закрытия `uiMode=nil; UpdateCursor()`.
6. **BOM от PowerShell `Set-Content -Encoding UTF8`:** писать через
   `[IO.File]::WriteAllText($p,$txt,(New-Object Text.UTF8Encoding($false)))`.
7. **Без `resource.AddFile` клиент видит шашечки:** зарегистрировано 30 файлов,
   плюс `sv_allowdownload 1` на сервере.
8. **Lua не обновляется без рестарта/переподключения.**

---

## 10. Чек-лист перед сдачей

- [ ] Прочитал `docs/PROMPT_ANEURISM_IV_UI.md`, `measurements.json` и этот файл.
- [ ] Бэкап каждого изменяемого файла.
- [ ] Lua 5.1: нет `&&`, `||`, `continue` (GMod `!`/`!=` допустимы); нет BOM.
- [ ] Синтаксис проверен: `node <temp>/luacheck/check.js <path>` (luaparse).
- [ ] Нет `InRect(gui.MousePos(), ...)` / `InRect(CursorPos(), ...)`.
- [ ] Новые материалы грузятся `.png` первыми, `MatReady()` не обходится.
- [ ] Полосы: только BLOOD и AIR, текст не вылезает за капсулу.
- [ ] Рация стартует OFF; `Esc` не выключает; второй клик возвращает чат.
- [ ] Сообщение только своей фракции; есть лог `[ANIV][RADIO]`.
- [ ] `aniv_hud_materials`: везде `ready=true`, имени `_error` нет.
- [ ] `aniv_hud_debug`: `radio/radioChat/cursorUnlocked` как ожидалось.
- [ ] HUD одинаков на 1280×720 / 1920×1080 / 2560×1440.
- [ ] Мост снимает `MYRP.CustomHUD.Paint`, но не трогает чужие хуки.
- [ ] Файлы синхронизированы в `D:\steamcmd` и `D:\steamcmd2`, хэши совпадают.
- [ ] Отчёт пользователю: что менял, как проверял, что перезапустить.

---

## 11. Быстрые ответы

**Шашечки, хотя файлы скачаны?** VMT без VTF — читай п.9.1.
**Где точные UV?** `docs/refs/measurements.json`.
**X не работает?** Рация должна быть ON; X — чат, не голос.
**Как поменять клавиши?** Конвары п.5, не правь код.
**Трогать `myrp_hud`?** Нет; мост снимает только один хук.
**Удалить VMT?** Нет — они зарегистрированы, загрузка идёт через PNG.
**Где меню взаимодействия?** В репозитории `suda-moi-proecti`, не здесь.

---

## 12. Известные отличия от оригинала

- Вместо 7 шкал — только BLOOD и AIR (по просьбе пользователя); legacy-4-иконки
  доступны через `aniv_hud_bars_enabled 0`.
- LCD адаптирован под фракционную рацию; положение/шрифт/цвет — 1:1.
- Голосовая трансляция заменена текстовым фракционным чатом.
- Шрифты — OFL-аналоги, не родной TMP-атлас игры.

---

## 13. Хронология правок по просьбе пользователя (не откатывать!)

| Коммит | Что сделано и почему |
|---|---|
| `320d2dc` | Первый импорт аддона + этот чеклист |
| `2d53142` | Добавлены 6 полос stat'ов по картинке |
| `a9d2ccf` | Полосы переделаны на настоящие спрайты игры, оставлены **только BLOOD и AIR** |
| `1e02b2c` | В меню взаимодействия добавлены настоящие `ui_button_bg.png` / `ui_panel.png` из `data.unity3d` |
| `9cb9a4e` | Меню взаимодействия: **только кнопки**, без панели/заголовков/подсказок |
| `2612193` | Чеклист переписан, добавлен `tools/extract_unity_ui.py` |
| `8c81345` | Книжка открывалась на `C`, `Q` убран (затем это стало неактуально) |
| `aebcb9a` | **VGUI-инвентарь удалён полностью** |
| `21f60f9` | **Книжка-счётчик и весь инвентарь вырезаны полностью** — текущее состояние |

Главное: пользователь неоднократно просил **убирать лишнее**. Если сомневаешься — не добавляй
новые панели/меню/счётчики в HUD. Текущий HUD = рация + 2 полосы + подсказки + CRT.
