Проект: База данных для компании по разработке, производству и продаже этикеток и бирок с DataMatrix
1. Назначение и контекст
Компания занимается:
- проектированием макетов этикеток и бирок;
-	производством тиражей (на своих цехах и/или у подрядчиков);
-	реализацией продукции клиентам B2B;
-	контролем и учётом DataMatrix-кодов для прослеживаемости партий.
Цель базы данных:
-	централизованно хранить данные о продуктах (этикетки/бирки), материалах, клиентах, заказах, производственных партиях и DataMatrix-кодах;
-	позволять строить аналитику по продажам, производству, браку, закупкам и использованию DataMatrix.

2. Основные сущности и процессы
2.1. Справочники
-	product_categories - группы продукций: термоэтикетки, бирки с петлёй, промышленные этикетки и т.д.
-	suppliers - поставщики сырья и материалов.
-	materials - материалы (бумага, плёнка и т.п.), которыми печатаются этикетки/бирки.
-	Manufacturers - производственные цеха или внешние подрядчики.
-	Customers - клиенты (торговые сети, производственные компании и т.д.).
2.2. Продукты и цены
-	products - конкретные виды этикеток/бирок (размер, материал, наличие DataMatrix и параметры кодирования).
-	prices - цены на продукты (общие, оптовые, спец-цены под клиента), с периодом действия.
2.3. Продажи и заказы
-	orders - заказы клиентов (покупки).
-	order_items - позиции заказов (какой продукт, в каком количестве, по какой цене).
2.4. Закупки и материалы
-	purchase_orders - заказы поставщикам на материалы.
-	purchase_order_items - позиции закупок (какой материал, сколько, по какой цене).
2.5. Производство и DataMatrix
-	production_orders - производственные заказы, привязанные к конкретным позициям клиентских заказов.
-	datamatrix_batches - партии DataMatrix-кодов, оформленные как диапазоны (range_start – range_end) с префиксом, привязанные к производственным заказам.

3. Схема данных (общее текстовое описание связей)
-	Один клиент (customers) может иметь много заказов (orders).
-	Один заказ (orders) содержит множество позиций (order_items), каждая позиция ссылается на один продукт (products).
-	Продукты относятся к одной категории (product_categories) и могут иметь один основной материал (materials).
-	Материалы закупаются у поставщиков (suppliers) через закупки (purchase_orders) и их позиции (purchase_order_items).
-	По каждой позиции заказа (order_items) можно создать один или несколько производственных заказов (production_orders), которые привязаны к определённому производителю/цеху (manufacturers).
-	Для каждого производственного заказа формируются одна или несколько партий DataMatrix-кодов (datamatrix_batches), каждая — диапазон кодов, который можно однозначно сопоставить конкретному клиенту, заказу и продукту.
-	Цены (prices) привязаны к продукту, опционально — к конкретному клиенту, и имеют период действия.

4. ER-диаграмма
5. <img width="1434" height="1138" alt="image_2025-11-10_12-07-30" src="https://github.com/user-attachments/assets/91feb703-5f8b-4287-8a60-2786165194f3" />

Описание таблиц и полей

```sql
CREATE TABLE product_categories (
    id           BIGSERIAL PRIMARY KEY,
    name         VARCHAR(100) NOT NULL,
    parent_id    BIGINT REFERENCES product_categories(id)
                 ON UPDATE CASCADE ON DELETE SET NULL,
    description  TEXT
);

CREATE TABLE suppliers (
    id           BIGSERIAL PRIMARY KEY,
    name         VARCHAR(150) NOT NULL,
    inn          VARCHAR(20),
    contact_name VARCHAR(100),
    phone        VARCHAR(30),
    email        VARCHAR(100),
    address      VARCHAR(255),
    is_active    BOOLEAN DEFAULT TRUE
);

CREATE TABLE manufacturers (
    id           BIGSERIAL PRIMARY KEY,
    name         VARCHAR(150) NOT NULL,
    inn          VARCHAR(20),
    address      VARCHAR(255),
    contact_name VARCHAR(100),
    phone        VARCHAR(30),
    email        VARCHAR(100),
    is_internal  BOOLEAN DEFAULT TRUE
);

CREATE TABLE customers (
    id           BIGSERIAL PRIMARY KEY,
    name         VARCHAR(150) NOT NULL,
    type         VARCHAR(20) DEFAULT 'b2b',     -- b2b / b2c / distributor
    inn          VARCHAR(20),
    contact_name VARCHAR(100),
    phone        VARCHAR(30),
    email        VARCHAR(100),
    address      VARCHAR(255),
    is_active    BOOLEAN DEFAULT TRUE,
    created_at   TIMESTAMP DEFAULT NOW()
);

CREATE TABLE materials (
    id                BIGSERIAL PRIMARY KEY,
    name              VARCHAR(100) NOT NULL,
    type              VARCHAR(50),
    thickness_microns NUMERIC(6,2),
    supplier_id       BIGINT REFERENCES suppliers(id)
                      ON UPDATE CASCADE ON DELETE SET NULL,
    unit              VARCHAR(20) DEFAULT 'm2',
    sku               VARCHAR(50),
    is_active         BOOLEAN DEFAULT TRUE
);

CREATE TABLE products (
    id                   BIGSERIAL PRIMARY KEY,
    name                 VARCHAR(150) NOT NULL,
    category_id          BIGINT REFERENCES product_categories(id)
                         ON UPDATE CASCADE ON DELETE RESTRICT,
    material_id          BIGINT REFERENCES materials(id)
                         ON UPDATE CASCADE ON DELETE SET NULL,
    code                 VARCHAR(50) NOT NULL UNIQUE,   -- артикул
    width_mm             NUMERIC(5,2),
    height_mm            NUMERIC(5,2),
    is_datamatrix        BOOLEAN DEFAULT TRUE,
    dm_encoding_standard VARCHAR(50),
    dm_module_size_mm    NUMERIC(4,3),
    description          TEXT,
    is_custom            BOOLEAN DEFAULT FALSE,
    created_at           TIMESTAMP DEFAULT NOW(),
    updated_at           TIMESTAMP DEFAULT NOW()
);

  CREATE TABLE prices (
    id          BIGSERIAL PRIMARY KEY,
    product_id  BIGINT NOT NULL REFERENCES products(id)
                ON UPDATE CASCADE ON DELETE CASCADE,
    customer_id BIGINT REFERENCES customers(id)
                ON UPDATE CASCADE ON DELETE CASCADE,
    price_type  VARCHAR(20) DEFAULT 'retail',   -- retail / wholesale / contract
    currency    VARCHAR(3)  DEFAULT 'RUB',
    value       NUMERIC(12,2) NOT NULL,
    min_qty     INT DEFAULT 1,
    valid_from  DATE NOT NULL,
    valid_to    DATE,
    CHECK (value >= 0)
);

CREATE TABLE orders (
    id             BIGSERIAL PRIMARY KEY,
    customer_id    BIGINT NOT NULL REFERENCES customers(id)
                   ON UPDATE CASCADE ON DELETE RESTRICT,
    order_date     DATE DEFAULT CURRENT_DATE,
    status         VARCHAR(20) DEFAULT 'new',   -- new/in_production/ready/shipped/cancelled
    total_amount   NUMERIC(14,2) DEFAULT 0,
    currency       VARCHAR(3) DEFAULT 'RUB',
    payment_status VARCHAR(20) DEFAULT 'unpaid', -- unpaid/partial/paid
    delivery_date  DATE,
    comment        TEXT,
    created_at     TIMESTAMP DEFAULT NOW(),
    updated_at     TIMESTAMP DEFAULT NOW()
);

CREATE TABLE order_items (
    id               BIGSERIAL PRIMARY KEY,
    order_id         BIGINT NOT NULL REFERENCES orders(id)
                     ON UPDATE CASCADE ON DELETE CASCADE,
    product_id       BIGINT NOT NULL REFERENCES products(id)
                     ON UPDATE CASCADE ON DELETE RESTRICT,
    quantity         INT NOT NULL,
    unit_price       NUMERIC(12,2) NOT NULL,
    discount_percent NUMERIC(5,2) DEFAULT 0,
    line_total       NUMERIC(14,2),
    dm_required      BOOLEAN DEFAULT TRUE,
    dm_standard      VARCHAR(50),
    comment          TEXT,
    CHECK (quantity > 0),
    CHECK (discount_percent >= 0 AND discount_percent <= 100)
);

CREATE TABLE purchase_orders (
    id           BIGSERIAL PRIMARY KEY,
    supplier_id  BIGINT NOT NULL REFERENCES suppliers(id)
                 ON UPDATE CASCADE ON DELETE RESTRICT,
    order_date   DATE DEFAULT CURRENT_DATE,
    status       VARCHAR(20) DEFAULT 'new', -- new/in_transit/received/cancelled
    total_amount NUMERIC(14,2) DEFAULT 0,
    currency     VARCHAR(3) DEFAULT 'RUB',
    created_at   TIMESTAMP DEFAULT NOW()
);

CREATE TABLE purchase_order_items (
    id                BIGSERIAL PRIMARY KEY,
    purchase_order_id BIGINT NOT NULL REFERENCES purchase_orders(id)
                      ON UPDATE CASCADE ON DELETE CASCADE,
    material_id       BIGINT NOT NULL REFERENCES materials(id)
                      ON UPDATE CASCADE ON DELETE RESTRICT,
    quantity          NUMERIC(12,3) NOT NULL,
    unit_price        NUMERIC(12,2) NOT NULL,
    line_total        NUMERIC(14,2),
    CHECK (quantity > 0),
    CHECK (unit_price >= 0)
);


CREATE TABLE production_orders (
    id                  BIGSERIAL PRIMARY KEY,
    order_item_id       BIGINT NOT NULL REFERENCES order_items(id)
                        ON UPDATE CASCADE ON DELETE RESTRICT,
    manufacturer_id     BIGINT NOT NULL REFERENCES manufacturers(id)
                        ON UPDATE CASCADE ON DELETE RESTRICT,
    planned_qty         INT NOT NULL,
    produced_qty        INT,
    scrap_qty           INT,
    status              VARCHAR(20) DEFAULT 'planned', -- planned/in_progress/done/cancelled
    planned_start_date  DATE,
    planned_end_date    DATE,
    actual_start_date   DATE,
    actual_end_date     DATE,
    CHECK (planned_qty > 0)
);

CREATE TABLE datamatrix_batches (
    id                  BIGSERIAL PRIMARY KEY,
    production_order_id BIGINT NOT NULL REFERENCES production_orders(id)
                        ON UPDATE CASCADE ON DELETE CASCADE,
    code_prefix         VARCHAR(50),
    range_start         BIGINT NOT NULL,
    range_end           BIGINT NOT NULL,
    printed_at          TIMESTAMP DEFAULT NOW(),
    status              VARCHAR(20) DEFAULT 'generated', -- generated/printed/used/cancelled
    CHECK (range_end >= range_start)
);
```

5. Примеры бизнес-задач

5.1. Аналитика по продажам этикеток с DataMatrix

Задача:
Определить, какие клиенты и какие типы этикеток (категории) приносят больше всего выручки по продукции с DataMatrix за выбранный период.

Используем таблицы:
- orders
- order_items
- products
- product_categories
- customers

Пример запроса:

```sql
SELECT c.name AS customer_name,
       SUM(oi.line_total) AS revenue_dm
FROM orders o
JOIN order_items oi ON o.id = oi.order_id
JOIN products p ON oi.product_id = p.id
JOIN customers c ON o.customer_id = c.id
WHERE p.is_datamatrix = TRUE
  AND o.status NOT IN ('cancelled')
  AND o.order_date BETWEEN '2025-01-01' AND '2025-12-31'
GROUP BY c.id, c.name
ORDER BY revenue_dm DESC
LIMIT 10;
```
Бизнес-ценность:
позволяет понять, какие клиенты являются ключевыми по продукции с маркировкой
помогает настраивать персональные цены и скидки.

5.2. Прослеживаемость партии DataMatrix-кодов до клиента и заказа

Задача:
По диапазону DataMatrix (или по ID партии) определить:
- какому клиенту;
- по какому заказу;
- какой продукт (этикетка/бирка);
- в каком количестве были произведены и поставлены эти коды.

Используем таблицы:
- datamatrix_batches
- production_orders
- order_items
- orders
- customers
- products

Пример запроса:
```sql
SELECT d.id                  AS batch_id,
       d.code_prefix,
       d.range_start,
       d.range_end,
       o.id                  AS order_id,
       o.order_date,
       c.name                AS customer_name,
       p.name                AS product_name,
       oi.quantity
FROM datamatrix_batches d
JOIN production_orders po ON d.production_order_id = po.id
JOIN order_items oi       ON po.order_item_id = oi.id
JOIN orders o             ON oi.order_id = o.id
JOIN customers c          ON o.customer_id = c.id
JOIN products p           ON oi.product_id = p.id
WHERE d.id = :batch_id;
```
Бизнес-ценность:
- выполнение требований по прослеживаемости (регуляторы, аудит);
- быстрый отклик при рекламациях: понять, в какие поставки попала спорная партия.

5.3. Эффективность производственных цехов и уровень брака

Задача:
Оценить, у каких производителей/цехов выше процент брака по определённым продуктам или в целом за период.

Используем таблицы:
- production_orders
- manufacturers

Пример запроса:
```sql
SELECT m.name AS manufacturer,
       SUM(po.produced_qty) AS total_produced,
       SUM(po.scrap_qty)    AS total_scrap,
       ROUND(
         (SUM(po.scrap_qty)::numeric / NULLIF(SUM(po.produced_qty), 0)) * 100,
         2
       ) AS scrap_percent
FROM production_orders po
JOIN manufacturers m ON po.manufacturer_id = m.id
WHERE po.actual_end_date BETWEEN '2025-01-01' AND '2025-12-31'
GROUP BY m.id, m.name
ORDER BY scrap_percent DESC;
```
контроль качества производства;
- выбор более надёжных подрядчиков;
- принятие решений о модернизации оборудования.

  5.4. Аналитика по закупкам материалов и зависимость от поставщиков

Задача:
Проанализировать, у каких поставщиков закупается больше всего материалов, и какие материалы критичны для DataMatrix-продукции.

Используем таблицы:
- purchase_orders
- purchase_order_items
- suppliers
- materials
- (опционально) products — для анализа связки материал ⇄ продукт с DataMatrix.

Пример: объём закупок по поставщикам за 6 месяцев
```sql
SELECT s.name AS supplier_name,
       SUM(poi.line_total) AS total_purchases
FROM purchase_orders po
JOIN purchase_order_items poi ON po.id = poi.purchase_order_id
JOIN suppliers s              ON po.supplier_id = s.id
WHERE po.order_date >= CURRENT_DATE - INTERVAL '6 months'
  AND po.status = 'received'
GROUP BY s.id, s.name
ORDER BY total_purchases DESC;
```
Бизнес-ценность:
- управление рисками: если зависимость от одного поставщика слишком велика;
- аргументы для переговоров по ценам.

5.5. Популярность материалов в продуктах с DataMatrix

Задача:
Определить, какие материалы чаще всего используются в продуктах с DataMatrix, чтобы планировать запасы и закупки.

Используем таблицы:
- products
- materials

Пример запроса:
```sql
SELECT m.name AS material_name,
       COUNT(*) AS dm_product_count
FROM products p
JOIN materials m ON p.material_id = m.id
WHERE p.is_datamatrix = TRUE
GROUP BY m.id, m.name
ORDER BY dm_product_count DESC;
```
Бизнес-ценность:
- планирование складских запасов;
- приоритизация поисков альтернативных материалов.

5.6. Аналитика по клиентам: кто покупает кастомные продукты

Задача:
Узнать, какие клиенты чаще всего заказывают нестандартные (custom) этикетки/бирки, требующие индивидуальных макетов и настроек.

Используем таблицы:
- orders
- order_items
- products
- customers

Пример:
```sql
SELECT c.name AS customer_name,
       COUNT(*) AS custom_orders_count,
       SUM(oi.line_total) AS revenue_custom
FROM orders o
JOIN order_items oi ON o.id = oi.order_id
JOIN products p    ON oi.product_id = p.id
JOIN customers c   ON o.customer_id = c.id
WHERE p.is_custom = TRUE
  AND o.status NOT IN ('cancelled')
GROUP BY c.id, c.name
ORDER BY custom_orders_count DESC;
```
Бизнес-ценность:
- выделение клиентов, которым важно индивидуальное обслуживание;
- возможность предлагать им дополнительные услуги по дизайну и сопровождению.

Описание всех таблиц и полей

1. Таблица product_categories — категории продуктов

Категории этикеток/бирок (например, «Термоэтикетки», «Бирки с петлёй»).

| Поле          | Тип                                         | Назначение                                      |
| ------------- | ------------------------------------------- | ----------------------------------------------- |
| `id`          | BIGSERIAL, PK                               | Уникальный идентификатор категории.             |
| `name`        | VARCHAR(100)                                | Название категории (например, «Термоэтикетки»). |
| `parent_id`   | BIGINT, FK → `product_categories.id` (NULL) | Родительская категория (для иерархии).          |
| `description` | TEXT                                        | Описание категории, комментарии.                |

2. Таблица suppliers — поставщики

Организации, поставляющие материалы, сырьё и т.п.

| Поле           | Тип           | Назначение                                       |
| -------------- | ------------- | ------------------------------------------------ |
| `id`           | BIGSERIAL, PK | Идентификатор поставщика.                        |
| `name`         | VARCHAR(150)  | Название организации.                            |
| `inn`          | VARCHAR(20)   | ИНН / налоговый номер.                           |
| `contact_name` | VARCHAR(100)  | Основное контактное лицо.                        |
| `phone`        | VARCHAR(30)   | Телефон.                                         |
| `email`        | VARCHAR(100)  | Email.                                           |
| `address`      | VARCHAR(255)  | Адрес (юр./факс/физический).                     |
| `is_active`    | BOOLEAN       | Признак, работаете ли сейчас с этим поставщиком. |

3. Таблица manufacturers — производители / цеха

Внутренние цеха или внешние подрядчики, где печатаются этикетки.

| Поле           | Тип           | Назначение                                        |
| -------------- | ------------- | ------------------------------------------------- |
| `id`           | BIGSERIAL, PK | Идентификатор производителя или цеха.             |
| `name`         | VARCHAR(150)  | Название («Основной цех печати», «Подрядчик Х»).  |
| `inn`          | VARCHAR(20)   | ИНН (если юр. лицо).                              |
| `address`      | VARCHAR(255)  | Адрес производства.                               |
| `contact_name` | VARCHAR(100)  | Контактное лицо.                                  |
| `phone`        | VARCHAR(30)   | Телефон.                                          |
| `email`        | VARCHAR(100)  | Email.                                            |
| `is_internal`  | BOOLEAN       | TRUE — внутренний цех, FALSE — внешний подрядчик. |

4. Таблица customers — покупатели

Клиенты, которые заказывают этикетки/бирки.

| Поле           | Тип           | Назначение                                 |
| -------------- | ------------- | ------------------------------------------ |
| `id`           | BIGSERIAL, PK | Идентификатор клиента.                     |
| `name`         | VARCHAR(150)  | Название организации или ФИО.              |
| `type`         | VARCHAR(20)   | Тип клиента (`b2b`, `b2c`, `distributor`). |
| `inn`          | VARCHAR(20)   | ИНН (для юр. лиц).                         |
| `contact_name` | VARCHAR(100)  | Контактное лицо.                           |
| `phone`        | VARCHAR(30)   | Телефон.                                   |
| `email`        | VARCHAR(100)  | Email.                                     |
| `address`      | VARCHAR(255)  | Адрес доставки / юр. адрес.                |
| `is_active`    | BOOLEAN       | Активный клиент или нет.                   |
| `created_at`   | TIMESTAMP     | Дата создания записи о клиенте.            |

5. Таблица materials — материалы

Материалы, на которых печатаются этикетки/бирки.

| Поле                | Тип                         | Назначение                                   |
| ------------------- | --------------------------- | -------------------------------------------- |
| `id`                | BIGSERIAL, PK               | Идентификатор материала.                     |
| `name`              | VARCHAR(100)                | Название («Термо бумага 58 г/м²»).           |
| `type`              | VARCHAR(50)                 | Тип материала (бумага, пластик, текстиль).   |
| `thickness_microns` | NUMERIC(6,2)                | Толщина в микронах.                          |
| `supplier_id`       | BIGINT, FK → `suppliers.id` | Основной поставщик этого материала.          |
| `unit`              | VARCHAR(20)                 | Единица измерения (например, m2, рулон, кг). |
| `sku`               | VARCHAR(50)                 | Внутренний код/артикул материала.            |
| `is_active`         | BOOLEAN                     | Признак использования материала сейчас.      |

6. Таблица products — продукты (этикетки/бирки)

Конкретные типы этикеток и бирок.

| Поле                   | Тип                                  | Назначение                                         |
| ---------------------- | ------------------------------------ | -------------------------------------------------- |
| `id`                   | BIGSERIAL, PK                        | Идентификатор продукта.                            |
| `name`                 | VARCHAR(150)                         | Название («Этикетка 40×40 мм, термо, DataMatrix»). |
| `category_id`          | BIGINT, FK → `product_categories.id` | Категория продукта.                                |
| `material_id`          | BIGINT, FK → `materials.id`          | Основной материал.                                 |
| `code`                 | VARCHAR(50)                          | Внутренний артикул/код продукта.                   |
| `width_mm`             | NUMERIC(5,2)                         | Ширина этикетки, мм.                               |
| `height_mm`            | NUMERIC(5,2)                         | Высота этикетки, мм.                               |
| `is_datamatrix`        | BOOLEAN                              | Есть ли DataMatrix на продукте.                    |
| `dm_encoding_standard` | VARCHAR(50)                          | Стандарт кодирования (например, GS1).              |
| `dm_module_size_mm`    | NUMERIC(4,3)                         | Размер модуля DataMatrix, мм.                      |
| `description`          | TEXT                                 | Описание, примечания.                              |
| `is_custom`            | BOOLEAN                              | Индивидуальный продукт под клиента или типовой.    |
| `created_at`           | TIMESTAMP                            | Дата создания продукта.                            |
| `updated_at`           | TIMESTAMP                            | Дата последнего изменения.                         |

7. Таблица prices — цены

История цен и спец-цены для клиентов.

| Поле          | Тип                                | Назначение                                                    |
| ------------- | ---------------------------------- | ------------------------------------------------------------- |
| `id`          | BIGSERIAL, PK                      | Идентификатор записи цены.                                    |
| `product_id`  | BIGINT, FK → `products.id`         | Продукт, к которому относится цена.                           |
| `customer_id` | BIGINT, FK → `customers.id` (NULL) | Клиент, для которого действует спец-цена (NULL — общая цена). |
| `price_type`  | VARCHAR(20)                        | Тип цены (`retail`, `wholesale`, `contract`).                 |
| `currency`    | VARCHAR(3)                         | Валюта (RUB, EUR и т.п.).                                     |
| `value`       | NUMERIC(12,2)                      | Цена за единицу.                                              |
| `min_qty`     | INTEGER                            | Минимальное количество для этой цены.                         |
| `valid_from`  | DATE                               | Дата начала действия цены.                                    |
| `valid_to`    | DATE (NULL)                        | Дата окончания (NULL — до отмены/изменения).                  |

8. Таблица orders — заказы (покупки клиентов)

Шапка заказа клиента.

| Поле             | Тип                         | Назначение                                                        |
| ---------------- | --------------------------- | ----------------------------------------------------------------- |
| `id`             | BIGSERIAL, PK               | Номер заказа.                                                     |
| `customer_id`    | BIGINT, FK → `customers.id` | Клиент, который сделал заказ.                                     |
| `order_date`     | DATE                        | Дата оформления заказа.                                           |
| `status`         | VARCHAR(20)                 | Статус (`new`, `in_production`, `ready`, `shipped`, `cancelled`). |
| `total_amount`   | NUMERIC(14,2)               | Итоговая сумма заказа.                                            |
| `currency`       | VARCHAR(3)                  | Валюта заказа.                                                    |
| `payment_status` | VARCHAR(20)                 | Статус оплаты (`unpaid`, `partial`, `paid`).                      |
| `delivery_date`  | DATE (NULL)                 | Планируемая дата отгрузки.                                        |
| `comment`        | TEXT                        | Комментарий менеджера/клиента.                                    |
| `created_at`     | TIMESTAMP                   | Дата создания записи.                                             |
| `updated_at`     | TIMESTAMP                   | Дата последнего изменения.                                        |

9. Таблица order_items — позиции заказов

Строки в заказе: какие продукты и в каком количестве.

| Поле               | Тип                        | Назначение                                                                            |
| ------------------ | -------------------------- | ------------------------------------------------------------------------------------- |
| `id`               | BIGSERIAL, PK              | Идентификатор позиции.                                                                |
| `order_id`         | BIGINT, FK → `orders.id`   | Заказ, к которому относится позиция.                                                  |
| `product_id`       | BIGINT, FK → `products.id` | Продукт в позиции.                                                                    |
| `quantity`         | INTEGER                    | Количество (шт./рулонов).                                                             |
| `unit_price`       | NUMERIC(12,2)              | Цена за единицу на момент заказа.                                                     |
| `discount_percent` | NUMERIC(5,2)               | Скидка в процентах.                                                                   |
| `line_total`       | NUMERIC(14,2)              | Сумма по позиции (пересчитывается триггером).                                         |
| `dm_required`      | BOOLEAN                    | Требуется ли печатать/генерировать DataMatrix для этой позиции.                       |
| `dm_standard`      | VARCHAR(50)                | Стандарт кодирования для этой партии (может отличаться от стандартного для продукта). |
| `comment`          | TEXT                       | Особые требования по дизайну/данным.                                                  |

10. Таблица purchase_orders — заказы поставщикам

Закупка материалов.

| Поле           | Тип                         | Назначение                                             |
| -------------- | --------------------------- | ------------------------------------------------------ |
| `id`           | BIGSERIAL, PK               | Номер заказа поставщику.                               |
| `supplier_id`  | BIGINT, FK → `suppliers.id` | Поставщик, у которого закупаются материалы.            |
| `order_date`   | DATE                        | Дата оформления закупки.                               |
| `status`       | VARCHAR(20)                 | Статус (`new`, `in_transit`, `received`, `cancelled`). |
| `total_amount` | NUMERIC(14,2)               | Итоговая сумма закупки.                                |
| `currency`     | VARCHAR(3)                  | Валюта.                                                |
| `created_at`   | TIMESTAMP                   | Дата создания записи.                                  |

11. Таблица purchase_order_items — позиции закупок

Строки в заказе поставщику.

| Поле                | Тип                               | Назначение                                |
| ------------------- | --------------------------------- | ----------------------------------------- |
| `id`                | BIGSERIAL, PK                     | Идентификатор позиции закупки.            |
| `purchase_order_id` | BIGINT, FK → `purchase_orders.id` | Заказ поставщику.                         |
| `material_id`       | BIGINT, FK → `materials.id`       | Материал, который закупается.             |
| `quantity`          | NUMERIC(12,3)                     | Количество материала.                     |
| `unit_price`        | NUMERIC(12,2)                     | Цена за единицу.                          |
| `line_total`        | NUMERIC(14,2)                     | Сумма по позиции (quantity × unit_price). |

12. Таблица production_orders — производственные заказы

Производство тиража по конкретной позиции клиентского заказа.

| Поле                 | Тип                             | Назначение                                              |
| -------------------- | ------------------------------- | ------------------------------------------------------- |
| `id`                 | BIGSERIAL, PK                   | Номер производственного заказа.                         |
| `order_item_id`      | BIGINT, FK → `order_items.id`   | Позиция заказа клиента, под которую идёт производство.  |
| `manufacturer_id`    | BIGINT, FK → `manufacturers.id` | Цех/подрядчик, выполняющий заказ.                       |
| `planned_qty`        | INTEGER                         | Планируемый тираж.                                      |
| `produced_qty`       | INTEGER (NULL)                  | Фактически произведено.                                 |
| `scrap_qty`          | INTEGER (NULL)                  | Количество брака.                                       |
| `status`             | VARCHAR(20)                     | Статус (`planned`, `in_progress`, `done`, `cancelled`). |
| `planned_start_date` | DATE                            | Плановая дата начала.                                   |
| `planned_end_date`   | DATE (NULL)                     | Плановая дата окончания.                                |
| `actual_start_date`  | DATE (NULL)                     | Фактическое начало.                                     |
| `actual_end_date`    | DATE (NULL)                     | Фактическое завершение.                                 |

13. Таблица datamatrix_batches — партии DataMatrix-кодов

Диапазоны DataMatrix-кодов, привязанные к производственным заказам.

| Поле                  | Тип                                 | Назначение                                            |
| --------------------- | ----------------------------------- | ----------------------------------------------------- |
| `id`                  | BIGSERIAL, PK                       | Идентификатор партии DataMatrix.                      |
| `production_order_id` | BIGINT, FK → `production_orders.id` | Производственный заказ, к которому относится партия.  |
| `code_prefix`         | VARCHAR(50)                         | Общий префикс кода (если используется).               |
| `range_start`         | BIGINT                              | Начало диапазона серий (например, 1000000000).        |
| `range_end`           | BIGINT                              | Конец диапазона (например, 1000014999).               |
| `printed_at`          | TIMESTAMP                           | Время печати/генерации партии.                        |
| `status`              | VARCHAR(20)                         | Статус (`generated`, `printed`, `used`, `cancelled`). |




