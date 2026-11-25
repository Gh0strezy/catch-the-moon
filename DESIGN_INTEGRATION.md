# Орбитальная станция · интеграция

Текущий плейс — **CatchThePlanet.rbxlx**, проект Rojo — `default.project.json`. Восемь баз стоят на радиусе 174 студов от мировой оси Y. Азимут первой базы составляет 22,5° от +Z к +X, шаг между базами составляет 45°. Локальная +Z каждой базы направлена от центра станции.

```text
Workspace
  World
    CentralStation
      Concourse
      CentralSpawn / Arrival / SafeReturn
      FallResetZone
      Observatory / GreatRefractor
                  / RetractableRoof / PortLeaf, StarboardLeaf
    Bridges / Bridge_01 … Bridge_08
    PlayerBases / Base_01 … Base_08
      BaseOrigin
      LowerHull
      CatchZone / Casting apron / CastOrigin
      Floors / Floor_01
        FloorOrigin
        PlanetSlots / PlanetSlot_01 … PlanetSlot_10 / Emitter / PlanetAnchor
        ExpansionPoints / StackDatum / NextFloor
        VerticalAccess / ClimbRail / Landing
      NPCPoints / RouteDatum / NPCSpawn, NPCVisitorPoint, NPCEvaluationPoint
    SpaceEnvironment
  Observatory / Stations / Catch, Gym, Luck, Speed
              / Gallery                         [создаётся сервером]
ServerStorage / StationKit / FloorTemplate, SlotAppearance
StarterPlayer / StarterPlayerScripts / StationEffects
```

### Адреса и границы ответственности

| Система | Точка подключения | Контракт |
|---|---|---|
| База игрока | `World.PlayerBases.Base_XX` | Model с PrimaryPart `BaseOrigin`, числовым `BaseIndex` 1–8 и постоянным `ZoneId` SPACE-09–16. Выдачу владельцу, повторный вход и освобождение реализует сервер Лёхи. |
| Спавн и падение | `CentralSpawn.Arrival`, `Arrival.SafeReturn`, `CentralStation.FallResetZone` | Arrival — единственный нейтральный SpawnLocation. SafeReturn.WorldCFrame — безопасная позиция персонажа. У маркера FallResetZone атрибут TriggerY = −75. Обработчик падения может сравнивать с ним высоту игрока. |
| Лассо | `CatchZone["Casting apron"].CastOrigin` | WorldCFrame у наружной кромки, LookVector направлен в космос. Проверка расстояния, бросок и выбор цели принадлежат серверу игры. |
| Планета | `Floor_XX.PlanetSlots.PlanetSlot_YY.Emitter.PlanetAnchor` | WorldCFrame для PivotTo экспоната. В каждом этаже 10 независимых слотов, изначально открыты нечётные. В модели каждого слота есть SlotIndex и Unlocked. |
| Состояние слота | `require(ServerStorage.StationKit.SlotAppearance).setUnlocked(slot, true)` | Вызывать на сервере после решения игровой системы. Метод одновременно меняет обод, излучатель, защёлку и атрибут. Для закрытия передать false. Визуальное состояние не авторизует платежи или размещение. |
| Новый этаж | `FloorTemplate`, `Floor_XX.ExpansionPoints.StackDatum.NextFloor` | Клонировать серверный шаблон на следующий этаж с шагом 16 по мировой Y. Взять номер из подтверждённых серверных данных. Лестничные шахты, опоры и все десять точек совпадают по плану. |
| Оценщик | `NPCPoints.RouteDatum` | Три Attachment задают вход с внутреннего края, остановку в проходе и место оценки у стойки. К конкретной планете ведёт отдельный PlanetAnchor. NPC, маршрутизация, выдача денег и сохранение находятся в ведении Лёхи. |

Пример установки уже разрешённого второго этажа:

```luau
local kit = game:GetService("ServerStorage").StationKit
local floors = workspace.World.PlayerBases.Base_01.Floors
local upper = kit.FloorTemplate:Clone()
upper.Name = "Floor_02"
upper:SetAttribute("FloorIndex", 2)
upper:PivotTo(floors.Floor_01.ExpansionPoints.StackDatum.NextFloor.WorldCFrame)
upper.Parent = floors
```

Для повторных запросов игровому серверу следует сверять наличие и номер этажа перед созданием. Шаблон содержит лестницу и проём, поэтому верхний этаж сохраняет доступ снизу. Площадка лассо, маршрут NPC и нижний корпус принадлежат базе и создаются один раз.

### Совместимость

Телескоп, тренажёр и улучшения работают на центральной палубе через `Workspace.Observatory.Stations`. Сервер создаёт галерею к югу от центра и размещает там сохранённые экспонаты игроков. Слоты, площадки броска и точки оценщика на восьми периферийных базах подготовлены для подключения к профилям. Эффекты станции используют отдельный LocalScript и TweenService.

### Источники и проверка

`tools/station/hub.luau` строит обсерваторию, `berths.luau` — мост, базу и шаблон этажа, `space.luau` — фон со звёздами со всех шести сторон и дальние объекты. Статический декор закреплён, коллизии выделены на настилах, ограждениях и лестнице. Небесные пластины, точки привязки и раздвижные створки не участвуют в столкновениях.

`tests/station-smoke.luau` проверяет структуру, положение восьми баз, независимые состояния слотов и стык двух этажей. Затем настоящий клиент проходит восемь мостов до площадок броска и проверяет ход створок. `tests/studio-smoke.luau` отдельно проверяет прежний игровой цикл. Запускать оба через Studio CLI на отдельных копиях плейса.
