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


