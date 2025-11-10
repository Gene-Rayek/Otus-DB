Проект: База данных для компании по разработке, производству и продаже этикеток и бирок с DataMatrix
1. Назначение и контекст
Компания занимается:
•	проектированием макетов этикеток и бирок;
•	производством тиражей (на своих цехах и/или у подрядчиков);
•	реализацией продукции клиентам B2B;
•	контролем и учётом DataMatrix-кодов для прослеживаемости партий.
Цель базы данных:
•	централизованно хранить данные о продуктах (этикетки/бирки), материалах, клиентах, заказах, производственных партиях и DataMatrix-кодах;
•	позволять строить аналитику по продажам, производству, браку, закупкам и использованию DataMatrix.
2. Основные сущности и процессы
2.1. Справочники
•	product_categories - группы продукций: термоэтикетки, бирки с петлёй, промышленные этикетки и т.д.
•	suppliers - поставщики сырья и материалов.
•	materials - материалы (бумага, плёнка и т.п.), которыми печатаются этикетки/бирки.
•	Manufacturers - производственные цеха или внешние подрядчики.
•	Customers - клиенты (торговые сети, производственные компании и т.д.).
2.2. Продукты и цены
•	products - конкретные виды этикеток/бирок (размер, материал, наличие DataMatrix и параметры кодирования).
•	prices - цены на продукты (общие, оптовые, спец-цены под клиента), с периодом действия.
2.3. Продажи и заказы
•	orders - заказы клиентов (покупки).
•	order_items - позиции заказов (какой продукт, в каком количестве, по какой цене).
2.4. Закупки и материалы
•	purchase_orders - заказы поставщикам на материалы.
•	purchase_order_items - позиции закупок (какой материал, сколько, по какой цене).
2.5. Производство и DataMatrix
•	production_orders - производственные заказы, привязанные к конкретным позициям клиентских заказов.
•	datamatrix_batches - партии DataMatrix-кодов, оформленные как диапазоны (range_start – range_end) с префиксом, привязанные к производственным заказам.

3. Схема данных (общее текстовое описание связей)
•	Один клиент (customers) может иметь много заказов (orders).
•	Один заказ (orders) содержит множество позиций (order_items), каждая позиция ссылается на один продукт (products).
•	Продукты относятся к одной категории (product_categories) и могут иметь один основной материал (materials).
•	Материалы закупаются у поставщиков (suppliers) через закупки (purchase_orders) и их позиции (purchase_order_items).
•	По каждой позиции заказа (order_items) можно создать один или несколько производственных заказов (production_orders), которые привязаны к определённому производителю/цеху (manufacturers).
•	Для каждого производственного заказа формируются одна или несколько партий DataMatrix-кодов (datamatrix_batches), каждая — диапазон кодов, который можно однозначно сопоставить конкретному клиенту, заказу и продукту.
•	Цены (prices) привязаны к продукту, опционально — к конкретному клиенту, и имеют период действия.

4. ER-диаграмма
5. <img width="1434" height="1138" alt="image_2025-11-10_12-07-30" src="https://github.com/user-attachments/assets/91feb703-5f8b-4287-8a60-2786165194f3" />

Описание таблиц и полей

- Справочники

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

- Цены и продажи

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

-- =========================
-- Закупки материалов
-- =========================

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


- Производство и DataMatrix


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

