# ANEURISM IV HUD для Garry's Mod (v1.1.0)

Аддон воссоздаёт HUD игры **ANEURISM IV** (Vellocet Software) и добавляет
**фракционную рацию**: рация с динамическим LCD, книга-инвентарь, 4 пиксельные
иконки состояния, подсказки `Grab`/`Search` и CRT-оверлей.

> **Другая нейронка/разработчик:** перед правками обязательно прочитай
> [`CHECKLIST_AI.md`](CHECKLIST_AI.md) — там карта файлов, state machine рации,
> сетевой протокол, измерения и список уже исправлённых ошибок, которые нельзя повторить.
> Полная спецификация — [`docs/PROMPT_ANEURISM_IV_UI.md`](docs/PROMPT_ANEURISM_IV_UI.md).

## Установка

Корень этого репозитория — это и есть папка аддона. Скопируй его целиком в:

```
<garrysmod>/addons/aneurism_hud/
```

Внутри должны остаться `lua/`, `materials/`, `resource/`, `docs/`, `tools/`.
GMod сам подхватит `lua/autorun` и `resource/fonts`.

На выделенном сервере проверь, что в `cfg/server.cfg` есть:

```
sv_allowdownload 1
```

Иначе клиент не скачает текстуры/шрифты и увидит розово-чёрные шашечки.
Все 24 файла регистрируются через `resource.AddFile()` в
`lua/autorun/aniv_hud_resources.lua`.

### Интеграция с MYRP / Helix (опционально)

В `docs/integration/myrp_zz_aniv_hud/` лежит мост-плагин. Если сервер использует
гейммод `myrp`, скопируй эту папку в:

```
<garrysmod>/gamemodes/myrp/schema/plugins/myrp_zz_aniv_hud/
```

Он снимает старый HUD (`MYRP.CustomHUD.Paint`) и подаёт живые данные:
здоровье → blood, стамина → air/leg, `character data "sanity"` → sanity,
инвентарь персонажа → счётчик на книге.

## Фракционная рация

Рация **изначально выключена**. Обычный чат работает, пока она выключена.

| Действие | Клавиша |
|---|---|
| Разблокировать/заблокировать курсор | `F3` |
| Включить/выключить рацию | клик по корпусу рации |
| Написать в фракционный чат | `X` → ввод → `Enter` |
| Отменить ввод (рация остаётся включённой) | `Esc` |
| Вернуть обычный чат | повторный клик по рации |

Пока рация включена, обычный чат заблокирован; сообщения идут только игрокам
той же фракции (`combine` / `resistance` не слышат друг друга — как Cortex и Scum
в оригинальной игре). Сервер логирует: `[ANIV][RADIO] <ник> [combine]: <текст>`.

## Консоль

- `aniv_hud_debug` — текущее состояние (radio / radioChat / cursorUnlocked);
- `aniv_hud_materials` — готовность текстур и имя `$basetexture`;
- `aniv_hud_radio on|off` — управление рацией;
- `aniv_hud_reset`, `togglehud`, `aniv_hud_toggle`;
- `myrp_aniv_hud_status` — состояние моста (если установлен).

## Публичный API

```lua
ANIV.SetStat("blood", 62)      -- 0..100
ANIV.SetRadioActive(true)
ANIV.IsRadioActive()
ANIV.ToggleRadio()
ANIV.SetRadioChatOpen(true)
ANIV.ToggleCursorUnlocked()
ANIV.SetInventory({ "Ration", "Pipe" })
ANIV.ToggleHUD()
```

Хуки: `ANIV_StatChanged`, `ANIV_RadioStateChanged`, `ANIV_RadioChatStateChanged`,
`ANIV_RadioMessageReceived`, `ANIV_InventoryChanged`, `ANIV_Interact`, `ANIV_ItemDropped`.

## Источники и лицензии

- [ANEURISM IV Wiki — HUD](https://aneurism.wiki.gg/wiki/HUD),
  [Controller](https://aneurism.wiki.gg/wiki/Controller),
  [Gameplay Mechanics](https://aneurism.wiki.gg/wiki/Gameplay_Mechanics)
- Спрайт рации: `File:Walkie_talkie_(1).png` (371×413) с вики; иконки извлечены
  из `ANEURISM IV_Data` и набора game-icons.net.
- Шрифты `Silkscreen` и `VT323` — OFL.
- Ассеты ANEURISM IV — авторский материал Vellocet Software; использовать
  в личных проектах.
