CREATE TABLE "entities" (
  "id" BIGINT PRIMARY KEY,
  "entity_type" varchar(30),
  "ref_id" BIGINT,
  "name" varchar(150),
  "inn" varchar(20),
  "is_active" boolean
);

CREATE TABLE "contacts" (
  "id" BIGINT PRIMARY KEY,
  "entity_id" BIGINT,
  "full_name" varchar(100),
  "position" varchar(100),
  "comment" text,
  "is_primary" boolean
);

CREATE TABLE "contact_channels" (
  "id" BIGINT PRIMARY KEY,
  "contact_id" BIGINT,
  "channel_type" varchar(30),
  "label" varchar(50),
  "value" text,
  "is_primary" boolean
);

CREATE TABLE "product_categories" (
  "id" BIGINT PRIMARY KEY,
  "name" varchar(100),
  "parent_id" BIGINT,
  "description" text
);

CREATE TABLE "suppliers" (
  "id" BIGINT PRIMARY KEY,
  "name" varchar(150),
  "inn" varchar(20),
  "contact_name" varchar(100),
  "phone" varchar(30),
  "email" varchar(100),
  "address" varchar(255),
  "is_active" boolean
);

CREATE TABLE "manufacturers" (
  "id" BIGINT PRIMARY KEY,
  "name" varchar(150),
  "inn" varchar(20),
  "address" varchar(255),
  "contact_name" varchar(100),
  "phone" varchar(30),
  "email" varchar(100),
  "is_internal" boolean
);

CREATE TABLE "customers" (
  "id" BIGINT PRIMARY KEY,
  "name" varchar(150),
  "type" varchar(20),
  "inn" varchar(20),
  "contact_name" varchar(100),
  "phone" varchar(30),
  "email" varchar(100),
  "address" varchar(255),
  "is_active" boolean,
  "created_at" timestamp
);

CREATE TABLE "materials" (
  "id" BIGINT PRIMARY KEY,
  "name" varchar(100),
  "type" varchar(50),
  "thickness_microns" numeric(6,2),
  "supplier_id" BIGINT,
  "unit" varchar(20),
  "sku" varchar(50),
  "is_active" boolean
);

CREATE TABLE "products" (
  "id" BIGINT PRIMARY KEY,
  "name" varchar(150),
  "category_id" BIGINT,
  "material_id" BIGINT,
  "code" varchar(50),
  "width_mm" numeric(5,2),
  "height_mm" numeric(5,2),
  "is_datamatrix" boolean,
  "dm_encoding_standard" varchar(50),
  "dm_module_size_mm" numeric(4,3),
  "description" text,
  "is_custom" boolean,
  "created_at" timestamp,
  "updated_at" timestamp
);

CREATE TABLE "prices" (
  "id" BIGINT PRIMARY KEY,
  "product_id" BIGINT,
  "customer_id" BIGINT,
  "price_type" varchar(20),
  "currency" varchar(3),
  "value" numeric(12,2),
  "min_qty" int,
  "valid_from" date,
  "valid_to" date
);

CREATE TABLE "orders" (
  "id" BIGINT PRIMARY KEY,
  "customer_id" BIGINT,
  "order_date" date,
  "status" varchar(20),
  "total_amount" numeric(14,2),
  "currency" varchar(3),
  "payment_status" varchar(20),
  "delivery_date" date,
  "comment" text,
  "created_at" timestamp,
  "updated_at" timestamp
);

CREATE TABLE "order_items" (
  "id" BIGINT PRIMARY KEY,
  "order_id" BIGINT,
  "product_id" BIGINT,
  "quantity" int,
  "unit_price" numeric(12,2),
  "discount_percent" numeric(5,2),
  "line_total" numeric(14,2),
  "dm_required" boolean,
  "dm_standard" varchar(50),
  "comment" text
);

CREATE TABLE "purchase_orders" (
  "id" BIGINT PRIMARY KEY,
  "supplier_id" BIGINT,
  "order_date" date,
  "status" varchar(20),
  "total_amount" numeric(14,2),
  "currency" varchar(3),
  "created_at" timestamp
);

CREATE TABLE "purchase_order_items" (
  "id" BIGINT PRIMARY KEY,
  "purchase_order_id" BIGINT,
  "material_id" BIGINT,
  "quantity" numeric(12,3),
  "unit_price" numeric(12,2),
  "line_total" numeric(14,2)
);

CREATE TABLE "production_orders" (
  "id" BIGINT PRIMARY KEY,
  "order_item_id" BIGINT,
  "manufacturer_id" BIGINT,
  "planned_qty" int,
  "produced_qty" int,
  "scrap_qty" int,
  "status" varchar(20),
  "planned_start_date" date,
  "planned_end_date" date,
  "actual_start_date" date,
  "actual_end_date" date
);

CREATE TABLE "datamatrix_batches" (
  "id" BIGINT PRIMARY KEY,
  "production_order_id" BIGINT,
  "code_prefix" varchar(50),
  "range_start" bigint,
  "range_end" bigint,
  "printed_at" timestamp,
  "status" varchar(20)
);

COMMENT ON COLUMN "entities"."entity_type" IS 'Тип: customer / supplier / manufacturer';

COMMENT ON COLUMN "entities"."ref_id" IS 'ID из соответствующей таблицы';

COMMENT ON COLUMN "contacts"."entity_id" IS 'Связь с entities';

COMMENT ON COLUMN "contact_channels"."contact_id" IS 'Связь с contacts';

COMMENT ON COLUMN "contact_channels"."channel_type" IS 'phone / email / address / telegram / website';

COMMENT ON COLUMN "product_categories"."parent_id" IS 'Родительская категория';

COMMENT ON COLUMN "customers"."type" IS 'b2b / b2c / distributor';

ALTER TABLE "contacts" ADD FOREIGN KEY ("entity_id") REFERENCES "entities" ("id");

ALTER TABLE "contact_channels" ADD FOREIGN KEY ("contact_id") REFERENCES "contacts" ("id");

ALTER TABLE "product_categories" ADD FOREIGN KEY ("parent_id") REFERENCES "product_categories" ("id");

ALTER TABLE "materials" ADD FOREIGN KEY ("supplier_id") REFERENCES "suppliers" ("id");

ALTER TABLE "products" ADD FOREIGN KEY ("category_id") REFERENCES "product_categories" ("id");

ALTER TABLE "products" ADD FOREIGN KEY ("material_id") REFERENCES "materials" ("id");

ALTER TABLE "prices" ADD FOREIGN KEY ("product_id") REFERENCES "products" ("id");

ALTER TABLE "prices" ADD FOREIGN KEY ("customer_id") REFERENCES "customers" ("id");

ALTER TABLE "orders" ADD FOREIGN KEY ("customer_id") REFERENCES "customers" ("id");

ALTER TABLE "order_items" ADD FOREIGN KEY ("order_id") REFERENCES "orders" ("id");

ALTER TABLE "order_items" ADD FOREIGN KEY ("product_id") REFERENCES "products" ("id");

ALTER TABLE "purchase_orders" ADD FOREIGN KEY ("supplier_id") REFERENCES "suppliers" ("id");

ALTER TABLE "purchase_order_items" ADD FOREIGN KEY ("purchase_order_id") REFERENCES "purchase_orders" ("id");

ALTER TABLE "purchase_order_items" ADD FOREIGN KEY ("material_id") REFERENCES "materials" ("id");

ALTER TABLE "production_orders" ADD FOREIGN KEY ("order_item_id") REFERENCES "order_items" ("id");

ALTER TABLE "production_orders" ADD FOREIGN KEY ("manufacturer_id") REFERENCES "manufacturers" ("id");

ALTER TABLE "datamatrix_batches" ADD FOREIGN KEY ("production_order_id") REFERENCES "production_orders" ("id");

ALTER TABLE "entities" ADD FOREIGN KEY ("ref_id") REFERENCES "customers" ("id");

ALTER TABLE "entities" ADD FOREIGN KEY ("ref_id") REFERENCES "suppliers" ("id");

ALTER TABLE "entities" ADD FOREIGN KEY ("ref_id") REFERENCES "manufacturers" ("id");
