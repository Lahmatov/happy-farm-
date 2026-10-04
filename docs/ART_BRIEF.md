# ТЗ на новую графику: «пышная и приятная ферма»

Для другого ИИ или художника. Текущая графика в репозитории — рабочий MVP (рисуется кодом,
плоская, с толстой тёмной обводкой). Задача: заменить её на более красивую, сочную, «пышную»,
**не меняя имена файлов и геометрию**, чтобы картинки встали в игру без переделки кода.

Что приложено:

| Файл | Зачем |
|---|---|
| `docs/art-template-tile.png` | Шаблон геометрии (холст 128x128, ромб-грядка, центр, глубина). Накладывать на каждую картинку для плиток |
| `docs/mvp-sprites-sheet.png` | Все текущие спрайты с именами: образец состава набора и композиции |
| `docs/scene.png` | Как сейчас выглядит игра целиком |
| `app/assets/sprites/*.png` | Текущие файлы. Новые кладутся поверх под теми же именами |

---

## 1. Технический контракт (нарушение = картинки «поедут» или тест упадёт)

### 1.1 Камера и плитки

- Изометрия 2:1 (диметрия, камера примерно 30° над землёй). Не вид сверху, не вид сбоку.
- Свет сверху-слева, тени падают вправо-вниз. Одинаково на всех картинках.
- Плитка земли — ромб. В логических единицах холста 128x128:
  центр **(64, 88)**, ширина ромба **124**, высота **62**, боковые грани (толщина «плиты») **10** (у `soil_locked` и `soil_next` 9).
  Нижняя точка плиты по расчёту выходит на 1 единицу за холст (88 + 31 + 10 = 129) и в текущих
  картинках обрезается краем; это нормально, так можно и оставить.
  В процентах холста: центр (50 %, 68,75 %), полуширина 48,4 %, полувысота 24,2 %.
- Соседние плитки в игре стоят вплотную, со сдвигом (±62, ±31) логических единиц, поэтому ромбы
  должны **касаться рёбрами без зазоров и без наложения**.
- Нажатие в игре определяется именно этим ромбом (с запасом 8 %). Если нарисовать плитку другой формы,
  попадание пальцем будет «мимо».

### 1.2 Слои (важно!)

Игра рисует слои друг на друге в одном прямоугольнике, без смещений:

```
грядка:  soil_dry | soil_wet | soil_locked | soil_next   +   crop_<культура>_<0..3>
загон:   pen   +   animal_<животное>
```

Поэтому:

- `crop_*` содержат **только растения**: без земли, без плиты, без большой тени. Допустим лёгкий
  контактный полутень у корней.
- `animal_*` содержат **только животное**: без загона, соломы и забора.
- Растения и животные стоят «на ромбе»; вверх могут подниматься до верхнего края холста.
- **Все картинки на холсте 128x128 (soil_*, pen, crop_*, animal_*) должны иметь ОДИНАКОВЫЙ размер в
  пикселях и быть квадратными.** Рекомендую 512x512 (4x). 
  Тест сейчас проверяет это только для части файлов (`soil_*`, `pen`, `crop_corn_3`, `animal_cow`), но требование
  относится ко всем перечисленным. Не обрезать лишнее по краям («trim»): холст фиксирован.

### 1.3 Формат файлов

- PNG с прозрачным фоном (RGBA). Без текста, водяных знаков, рамок, фона.
- Имена файлов точно как в списке ниже (регистр, подчёркивания).
- Размер файла разумный: до ~400 КБ на картинку (в приложении 40+ картинок).

### 1.4 Пропорции и «точка на земле» для остальных картинок

Игра масштабирует картинку в прямоугольник заданной пропорции и ставит её так, чтобы «точка на земле»
оказалась в нужном месте. **Пропорции менять нельзя** (картинку растянет). Размер в пикселях любой, но
с теми же пропорциями.

| Файл | Пропорции (ш x в) | Точка на земле (от левого верха) | Заметка |
|---|---|---|---|
| `decor_tree` | 128 x 160 (4:5) | 50 % по x, 91 % по y | основание ствола |
| `decor_bush` | 80 x 60 (4:3) | 50 %, 83 % | |
| `decor_flowers` | 66 x 56 | 50 %, 93 % | |
| `decor_barn` | 180 x 160 (9:8) | 50 %, 94 % | центр основания дома |
| `decor_tuft` | 36 x 26 | не важна | мелкий пучок травы, рисуется ~70 раз по экрану |
| `bubble_crop`, `bubble_egg`, `bubble_wool`, `bubble_milk` | 1:1 | — | облачко над грядкой/животным |
| `icon_coin`, `icon_star` | 1:1 | — | значки в панели и списках |
| `fx_sparkle` | 1:1 | — | блеск на спелых грядках |

Если новая картинка получилась с другими пропорциями, это можно исправить в коде
(`app/lib/src/iso.dart`, `_decorSizes`), но сообщите об этом разработчику, а не меняйте молча.

---

## 2. Стиль: «пышно и приятно»

Что хочется почувствовать: сытая, солнечная, уютная ферма. Всё круглое, пухлое, сочное, дорогое
на вид, как в хорошей мобильной казуальной игре. Чем больше мелких приятных деталей, тем лучше,
но силуэт каждого объекта должен читаться на расстоянии (ромб-грядка на экране около 75 pt шириной).

Чем отличается от текущего MVP:

- Вместо плоской заливки и толстой чёрной обводки: мягкие градиенты, объём, глянцевые блики на плодах,
  мягкая окружающая тень (ambient occlusion), тонкий контур **цветом темнее самого объекта**, не чёрный.
- Растения заметно **крупнее и гуще**, листья широкие, плоды крупные и блестящие.
- Земля с фактурой: комочки, камушки, росинки, пробивающаяся травка по краю.
- Палитра: насыщенные, но гармоничные цвета; зелёные с тёпло-жёлтыми бликами; тёплый общий свет.
- Мелочи, которые добавляют «пышности»: маленькие цветочки, бабочки, капли росы, лепестки,
  пятна света и тени на земле.

### 2.1 Мастер-промт (добавлять в начало каждого запроса)

```
Lush, plump, juicy casual farm game art, 2.5D isometric (2:1 dimetric, camera about 30 degrees
above the ground), soft 3D-rendered cartoon look, chubby rounded shapes, bright saturated but
harmonious colours, rich fresh greens with warm yellow-green highlights, glossy specular
highlights on fruit and leaves, soft ambient occlusion, soft cast shadow to the lower right
(light from the upper left), thin darker-tone outline in the same hue family (not black),
generous charming detail, cheerful and cozy, premium mobile game quality, clean cutout on a
fully transparent background, single subject, no text, no watermark, no border, no frame.
```

### 2.2 Негативный промт

```
photorealistic, dark, grim, thick black outlines, flat vector, blurry, noisy, jpeg artifacts,
text, letters, numbers, logo, watermark, signature, frame, border, background scene, ground
plane larger than the tile, multiple objects, cropped, fisheye, top-down orthographic view,
side-on view, inconsistent light direction, real brand or character likeness
```

### 2.3 Как получить точную геометрию от генератора картинок

Нейросети плохо попадают в точные размеры. Рабочий порядок:

1. Генерировать крупно (например, 1024x1024) по промту ниже.
2. Наложить на `docs/art-template-tile.png`, подогнать масштаб и положение так, чтобы ромб совпал.
3. Вырезать фон, экспортировать на холст 512x512 с прозрачностью, без автообрезки.
4. Для стадий роста одной культуры брать предыдущую стадию как референс (img2img / reference),
   чтобы растение было «тем же самым», а не новым каждый раз.
5. Один и тот же сид/стиль-референс на весь набор, иначе картинки не сойдутся по стилю.

---

## 3. Список картинок и промты

В каждом промте ниже подразумевается мастер-промт из п. 2.1 и негативный из п. 2.2. Сначала всегда
идёт описание объекта, затем строка «Geometry».

### A. Земля (4 файла, холст 512x512)

Общая строка Geometry для всех плиток:
`Geometry: isometric 2:1 tile, the top face is a diamond centred at 50% x and 68.75% y of a square
canvas, 96.9% of canvas width and 48.4% of canvas height, with 10/128 of canvas height of visible
side faces below; edges must be straight so neighbouring tiles join with no gaps.`

| Файл | Промт |
|---|---|
| `soil_dry` | A thick isometric slab of freshly tilled farm soil, rich warm brown, five parallel furrows with soft rounded ridges and darker grooves, crumbly clumps, a few tiny pebbles, side faces showing layered earth, tiny grass blades poking along the rim. Dry look. |
| `soil_wet` | The same tilled soil slab but freshly watered: darker chocolate brown, moist glossy sheen, tiny water droplets and small glints, deeper furrow shadows. Same furrow layout as `soil_dry`. |
| `soil_locked` | An isometric slab overgrown with lush green grass instead of soil: tufts, clover, a few small white daisies and dandelions, two small grey stones. Slightly muted so it reads as unavailable. No signs, no text. |
| `soil_next` | Same as `soil_locked`, plus a small wooden signpost with a golden padlock on the sign, standing near the tile centre, rising above the tile. This marks the next plot the player can buy. |

### B. Культуры (5 культур x 4 стадии = 20 файлов, холст 512x512)

Имена: `crop_<id>_<стадия>.png`, где `<id>`: `radish`, `wheat`, `carrot`, `strawberry`, `corn`.

Стадии (одинаково для всех культур):

- `_0` — только что взошло: 2-3 крошечных листика у каждого места посадки.
- `_1` — молодые растения, листья распускаются.
- `_2` — почти взрослое, плодов ещё нет или они зелёные/маленькие.
- `_3` — **спелое, готово к сбору**: плоды самые крупные, яркие, глянцевые. Должно сразу бросаться в глаза.

Расположение (пересчитано по `tools/sprites/art.mjs`, в логических единицах холста 128x128; основание
каждого растения, то есть точка на земле):

- Обычные культуры: **5 мест посадки**: центр **(64, 90)** и четыре точки
  **(81,3; 81,4), (46,7; 81,4), (81,3; 98,6), (46,7; 98,6)**. Это прямоугольник вокруг центра
  (±17,3 по x и ±8,6 по y), примерно на полпути от центра к серединам рёбер ромба, а не к углам.
  Растения за счёт размера заходят дальше, но их основания стоят именно здесь.
- Кукуруза: **3 места**, потому что стебли высокие. Основания в точках (69,1; 79,8), (79,4; 97,7) и
  (41,0; 87,4).
- Растения не должны сильно выходить за левый и правый углы ромба (x = 2 и x = 126); вверх могут
  подниматься высоко. Передние растения (ниже на экране) перекрывают задние.

Строка Geometry для культур:
`Geometry: ONLY the plants, no soil, no tile, no ground. Five plant bases: one at the centre of an
isometric diamond (50% x, 68.75% y of a square canvas) and four around it at about +-13.5% x and +-6.75% y
of the canvas from the centre (a small rectangle, not near the diamond corners). Corn: three plant bases
spread across the tile. Plants may rise up to the top edge and must stay within the diamond's left and
right corners (96.9% of canvas width); transparent background so the plants can be layered over a soil tile.`

| Культура | Описание для промта |
|---|---|
| `radish` | Plump radishes: broad ruffled green leaves; at stage 3 big round glossy crimson-red radish tops with white tips pushing out of the ground. |
| `wheat` | Tufts of wheat: slender stalks changing from fresh green to golden; at stage 3 heavy golden ears with visible grains, gently bowed. |
| `carrot` | Carrots: tall feathery fine-cut green fronds; at stage 3 fat glossy orange carrot crowns bulging out of the soil. |
| `strawberry` | Strawberry bushes: trefoil serrated leaves; stage 2 covered in small white five-petal flowers; stage 3 many plump glossy red strawberries with yellow seeds and green caps. |
| `corn` | Corn plants: tall sturdy stalks with long arching leaves; stage 3 large golden-yellow cobs wrapped in green husks with silky tassels, clearly visible (do not hide the cobs behind leaves). |

### C. Загон и животные (4 файла, холст 512x512)

| Файл | Промт |
|---|---|
| `pen` | An isometric farm pen: a golden straw-bedded floor tile with scattered straw and a few feeding details, a charming wooden post-and-rail fence only along the two BACK edges (upper-left and upper-right edges of the diamond), the front two edges open. Slab sides visible. Same Geometry line as the soil tiles. |
| `animal_chicken` | A cute plump white hen with a red comb and wattle, orange beak and legs, soft feathers, standing, **facing left** (towards the lower left), full body, feet near 75% of canvas height. |
| `animal_sheep` | A cute fluffy sheep with thick cloud-like cream-white wool and a dark soft face and legs, standing, **facing left**, full body. |
| `animal_cow` | A cute dairy cow with black-and-white patches, pink muzzle, small horns, a bell on a collar, standing, **facing left**, full body. |

Строка Geometry для животных:
`Geometry: ONLY the animal, no pen, no straw, no ground; standing on an isometric diamond centred at
50% x and 68.75% y of a square canvas; feet around 75% of canvas height; the animal is about 55-67% of
canvas width including its outline (hen smallest, cow largest); transparent background.`

Животные в одном масштабе друг относительно друга: корова самая крупная, курица самая мелкая, овца между ними.

### D. Облачка, значки, эффекты

| Файл | Размер | Промт |
|---|---|---|
| `bubble_crop` | 1:1 | A round speech-bubble icon with a small tail at the bottom, white glossy, containing a small green sprout with two leaves. Means "ready to harvest". |
| `bubble_egg` | 1:1 | The same bubble style containing a cream egg with a soft highlight. |
| `bubble_wool` | 1:1 | The same bubble style containing a pink ball of yarn. |
| `bubble_milk` | 1:1 | The same bubble style containing a milk bottle with a blue cap. |
| `icon_coin` | 1:1 | A shiny gold coin, embossed rim, a star emblem in the middle, strong highlight, clean silhouette that reads at 20 px. |
| `icon_star` | 1:1 | A glossy green five-point rounded star used as the level badge, with a bright highlight; the middle must stay free (the level number is drawn over it). |
| `fx_sparkle` | 1:1 | A four-point soft golden-white sparkle with a small second sparkle, glowing. |

Облачка и значки должны быть выдержаны в одном стиле друг с другом.

### E. Декор (5 файлов)

| Файл | Промт |
|---|---|
| `decor_tree` | A lush round apple tree with a thick trunk, layered rich green foliage with warm highlights, ripe red apples, soft ground shadow. Proportions 4:5, base of the trunk at 50% x, 91% y. |
| `decor_bush` | A plump flowering bush with small pink, yellow and white flowers, soft shadow. Proportions 4:3, base at 50% x, 83% y. |
| `decor_flowers` | A small patch of mixed wildflowers (pink, yellow, white, orange) with leaves. Proportions 66:56, base at 50% x, 93% y. |
| `decor_tuft` | A small tuft of fresh grass blades, 3-5 blades, soft. Proportions 36:26. Tiny and simple: it is drawn many times. |
| `decor_barn` | A charming red wooden barn, isometric, with a white-trimmed door and a small window, hay visible, warm light, soft shadow. Proportions 9:8, base centre at 50% x, 94% y. |

---

## 4. Дополнительно, чтобы стало «пышнее» (необязательно; требует правок кода, их сделает разработчик)

Присылайте под понятными именами, например `decor_pond`, `decor_haystack`, `decor_well`,
`decor_cart`, `decor_scarecrow`, `decor_fence_l`, `decor_fence_r`, `decor_path`, `decor_mushrooms`,
`fx_butterfly_0/1`, `fx_bird_0/1`. Для каждой: пропорции, точка на земле (как в п. 1.4) и примерная
высота. Сейчас игра этих файлов не использует: после получения картинок разработчик добавит их в сцену.

Интерфейс (набор для панелей, нужен код; сообщайте размеры):

- деревянная верхняя панель (растягиваемая 9-slice, 256x96) и нижняя панель;
- зелёная кнопка и жёлтая кнопка (обычная, нажатая, выключенная);
- карточка элемента списка (рамка), плашка монет, полоса опыта (фон и заполнение), значок уровня;
- фон экрана входа: вертикальная иллюстрация 1179x2556 (небо, холмы, ферма), без текста;
- иконка приложения 1024x1024 без прозрачности и без скруглений (iOS скруглит сам);
- заставка запуска.

Анимация (по желанию, потребует кода): покачивание спелых растений и «дыхание» животных,
2-4 кадра полосой, каждый кадр на холсте 128x128. Сначала статика, анимация потом.

---

## 5. Приёмка (чек-лист)

- [ ] Все имена файлов совпадают с `Sprites.names` в `app/lib/src/sprites.dart` (40 файлов).
- [ ] Холсты `soil_*`, `pen`, `crop_*`, `animal_*` одинакового квадратного размера (например, 512x512).
- [ ] Ромб на каждой плитке совпадает с шаблоном; соседние плитки стыкуются без щелей.
- [ ] `crop_*` без земли, `animal_*` без загона, фон везде прозрачный.
- [ ] Свет сверху-слева на всех картинках, стиль единый (положить рядом на `docs/scene.png` и сравнить).
- [ ] Спелая стадия (`_3`) каждой культуры сразу отличается от `_2`.
- [ ] Читается на малом размере: ромб на iPhone шириной 375 pt получается около 75 pt шириной (плитка 124 из 624 единиц ширины поля); уменьшить картинку до 150 px по ширине и посмотреть.
- [ ] Файлы PNG-24 с альфой, до ~400 КБ каждый.

Как проверить в игре (на компьютере с Flutter):

```
cd app
flutter test                     # проверит имена, размеры, что сцена не пустая
SCREENSHOT_DIR=/tmp flutter test test/scene_test.dart   # положит /tmp/scene.png: смотреть глазами
```

---

## 6. Юридическая гигиена для графики

- Не писать в промтах названия чужих игр, персонажей, студий и имена художников, не использовать чужие
  картинки как референс. Описывать словами, что нужно.
- Результаты не должны напоминать известных персонажей и логотипы. Никаких логотипов на картинках.
- Сохранять промты, сид и название сервиса для каждого файла.
- Проверить условия сервиса генерации: разрешено ли коммерческое использование результатов и кому
  принадлежат права. Для App Store это важно.
- Ассеты оригинальной «Счастливой фермы» и любых других игр не использовать, даже «для референса».
