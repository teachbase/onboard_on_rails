# Необязательный CSS-селектор и viewport-позиционирование

Дата: 2026-04-13

## Проблема

Сейчас CSS-селектор обязателен для каждого шага тура (`validates :selector, presence: true`). Из-за этого невозможно показать модальное окно, баннер или выдвижную панель без привязки к конкретному элементу на странице. Особенно проблематично для темы "Модальное окно" — модалка должна показываться по центру экрана, а не рядом с элементом.

## Решение

Убрать обязательность CSS-селектора. Когда селектор не указан, все темы позиционируются относительно viewport, а позиция зависит от настройки "Расположение" (placement) шага.

## Изменения

### 1. Модель Step (`app/models/onboard_on_rails/step.rb`)

Убрать `validates :selector, presence: true`. Селектор становится необязательным для всех тем.

Убрать сообщение об ошибке для `selector.blank` из `ru.yml` (`config/locales/ru.yml`, строка 24).

### 2. PositioningEngine — новый метод `positionViewport` (`app/assets/javascripts/onboard_on_rails/client.js`)

Добавить метод `positionViewport(tooltip, placement)` в объект `PositioningEngine`. Метод устанавливает `position: fixed` и позиционирует элемент относительно viewport:

| placement | position |
|-----------|----------|
| `top`     | верх по центру горизонтали, отступ `MARGIN` сверху |
| `bottom`  | низ по центру горизонтали, отступ `MARGIN` снизу |
| `left`    | слева по центру вертикали, отступ `MARGIN` слева |
| `right`   | справа по центру вертикали, отступ `MARGIN` справа |
| `center`  | центр экрана |

Используется `MARGIN: 12` (существующая константа). Центрирование по осям через CSS `transform: translate`.

### 3. TourRenderer — интеграция (`app/assets/javascripts/onboard_on_rails/client.js`)

**`TourRenderer.show`** — убрать ранний `return` когда нет `targetEl` и placement не `center` (строка 230). Без этой проверки рендерер продолжит работу: оверлей создастся без clip-path (сплошной затемнённый фон), хайлайт не вызовется (проверка `if (!el) return` уже есть в `highlightTarget`).

**`TourRenderer.createTooltip`** — заменить ветку без `targetEl` (строки 305-309): вместо захардкоженного center-позиционирования вызывать `PositioningEngine.positionViewport(this.tooltip, step.placement)`.

**`TourManager.showStep`** — изменить логику показа (строки 387-389): если `step.selector` пустой — сразу вызывать `showFn()` без ожидания элемента. Если `step.selector` задан — текущая логика с `querySelector` / `waitForSelector`.

### 4. Админ-форма (`app/views/onboard_on_rails/admin/steps/_form.html.erb`)

Добавить подсказку под полем селектора о viewport-позиционировании.

### 5. Локали

**`config/locales/en.yml`** — добавить ключ `selector_empty` в `hints`:
```
selector_empty: "If left empty, the step will be positioned relative to the viewport"
```

**`config/locales/ru.yml`** — добавить ключ `selector_empty` в `hints`:
```
selector_empty: "Если не указан, шаг будет позиционироваться относительно видимой части экрана"
```

## Что НЕ меняется

- CSS-стили тем (`client.css`) — JS-позиционирование перезаписывает CSS-позицию, поэтому стили тем (`oor-theme-modal`, `oor-theme-banner`, `oor-theme-slideout`) не нужно менять. Они продолжат работать при наличии селектора через существующий `PositioningEngine.position()`.
- Обработчик `resize/scroll` — уже защищён проверкой `if (this.targetEl)`, `position: fixed` не зависит от скролла.
- API, контроллеры, сервисы — не затрагиваются.
- Поле селектора и кнопка "Выбрать" в форме — остаются, просто необязательны.
