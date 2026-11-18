-- Permanent survey parcels. Center is floor elevation, size is the X/Z ownership boundary.
-- Append new IDs. Keep retired IDs in the ledger.
return {
	{id="SPACE-01", key="Exchange", name="Пассаж Сирены", status="Prepared", group="MainHub", center={-61,-4,0}, size={34,36},
		purpose="Крытая торговая терраса", growth="Торговые места вдоль западной стены", links="Крыша, SPACE-04, SPACE-06, SPACE-07"},
	{id="SPACE-02", key="FieldOffice", name="Пост картографа", status="Prepared", group="MainHub", center={61,-4,0}, size={34,36},
		purpose="Приём экспедиций и будущее место NPC", growth="Стойка и рабочие места в восточном крыле", links="Крыша, SPACE-03, SPACE-05, SPACE-08"},
	{id="SPACE-03", key="GlacierPrism", name="Призматическая долина", status="Dormant", group="FutureLocations", center={154,1,-142}, size={100,88},
		purpose="Причал кристаллического мира", growth="Застройка внутренней долины, продолжение на северо-восток", links="SPACE-02, смотровая кромка, SPACE-05"},
	{id="SPACE-04", key="SpiralSound", name="Спиральная бухта", status="Dormant", group="FutureLocations", center={-148,3,-146}, size={108,88},
		purpose="Приёмник сигнала далёкой галактики", growth="Экспедиционный двор и выход на северо-запад", links="SPACE-01, смотровая кромка, SPACE-06"},
	{id="SPACE-05", key="BeltHarbor", name="Астероидная гавань", status="Dormant", group="FutureLocations", center={257,-3,2}, size={96,104},
		purpose="Грузовой причал пояса астероидов", growth="Восточный край под грузовую линию", links="SPACE-02, SPACE-03, SPACE-08"},
	{id="SPACE-06", key="Umbra", name="Теневая седловина", status="Dormant", group="FutureLocations", center={-257,-2,4}, size={100,96},
		purpose="Порог тёмной планеты", growth="Западная чаша под самостоятельный мир", links="SPACE-01, SPACE-04, SPACE-07"},
	{id="SPACE-07", key="WestBench", name="Западная терраса", status="Reserved", group="ReservedAreas", center={-144,-5,124}, size={112,84},
		purpose="Свободная строительная терраса", growth="Продление к юго-западному уступу", links="SPACE-01, SPACE-06"},
	{id="SPACE-08", key="EastShelf", name="Восточный шельф", status="Reserved", group="ReservedAreas", center={145,-5,126}, size={112,88},
		purpose="Свободная площадка для будущего режима", growth="Продление к юго-восточному уступу", links="SPACE-02, SPACE-05"},
}
