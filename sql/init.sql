DROP SCHEMA public CASCADE;
CREATE SCHEMA public;

------------------------------------------------------------
-- Setup Simple Attribute Data
------------------------------------------------------------
CREATE TABLE bases (
  base_id        serial PRIMARY KEY,
  active         boolean NOT NULL DEFAULT true,
  title          text NOT NULL,
  normalized     text NULL
);

CREATE TABLE nozzles (
  nozzle_id      serial PRIMARY KEY,
  active         boolean NOT NULL DEFAULT true,
  title          text NOT NULL,
  size           integer NOT NULL
);

CREATE TABLE price_points (
  price_point_id serial PRIMARY KEY,
  active         boolean NOT NULL DEFAULT true,
  amount         integer NOT NULL,
  currency       text NOT NULL,
  measure        text NOT NULL,
  title          text NOT NULL
);

CREATE TABLE volumes (
  volume_id      serial PRIMARY KEY,
  active         boolean NOT NULL DEFAULT true,
  measure        text NOT NULL
);

CREATE TABLE weights (
  weight_id      serial PRIMARY KEY,
  active         boolean NOT NULL DEFAULT true,
  measure        text NOT NULL
);

------------------------------------------------------------
-- Setup Complex Attribute Data
------------------------------------------------------------

CREATE TABLE material_types (
  material_type_id     serial PRIMARY KEY,
  active               boolean NOT NULL DEFAULT true,
  base                 int NOT NULL REFERENCES bases(base_id),
  title                text NOT NULL,
  normalized           text NULL
);

CREATE TABLE brands (
  brand_id       serial PRIMARY KEY,
  active         boolean NOT NULL DEFAULT true,
  title          text NOT NULL,
  material_type  serial NOT NULL REFERENCES material_types(material_type_id)
);

CREATE TABLE colors (
  color_id       serial PRIMARY KEY,
  active         boolean NOT NULL DEFAULT true,
  images         text[] NULL,
  title          text NOT NULL,
  normalized     text NOT NULL
);

------------------------------------------------------------
-- Setup Materials, Printers, Orders & Items
------------------------------------------------------------
CREATE TYPE statuses AS ENUM ('init', 'pending', 'processing', 'fulfilled');

CREATE TABLE materials (
  material_id    serial PRIMARY KEY,
  batch_id       int NULL,
  active         boolean NOT NULL DEFAULT true,
  attributes     integer[] NULL,
  compliant      boolean NOT NULL DEFAULT true,
  title          text NOT NULL,
  sku            text NOT NULL,
  added_at       timestamptz NOT NULL DEFAULT NOW(),
  opened_at      timestamptz NULL,
  amount_total   int NULL,
  amount_used    int NULL
);

CREATE TABLE printers (
  printer_id     serial PRIMARY KEY,
  active         boolean NOT NULL DEFAULT true,
  attributes     integer[] NULL,
  accessories    integer[] NULL,
  created_at     timestamptz NOT NULL DEFAULT NOW(),
  dimensions     jsonb NULL,
  title          text NOT NULL,
  hours_online   int NULL,
  hours_printed  int NULL,
  -- materials   handled in the printers_materials table
  resolution     jsonb NULL
);
-- Associate all printer materials available
CREATE TABLE printers_materials (
  printers_id     INTEGER REFERENCES printers(printer_id) ON UPDATE CASCADE ON DELETE CASCADE,
  materials_id    INTEGER REFERENCES materials(material_id) ON UPDATE CASCADE ON DELETE CASCADE,
  materials_order SMALLINT,
  PRIMARY KEY (printers_id, materials_id)
);
-- Keep things orderly.
CREATE UNIQUE INDEX idx_printers_coll_materials_order ON printers_materials (printers_id, materials_order);

-- TODO: confirm printers materials
CREATE TABLE items (
  item_id        serial PRIMARY KEY,
  active         boolean NOT NULL DEFAULT true,
  attributes     integer[] NULL,
  cost           integer NULL,
  title          text NOT NULL,
  -- materials   handled in the items_materials table
  model          jsonb NULL,
  -- printers    handled in the items_printers table
  resolutions    integer[] NULL,
  status         statuses NOT NULL DEFAULT 'init'::statuses,
  started_at     timestamptz NOT NULL DEFAULT NOW(),
  ended_at       timestamptz NULL
);
-- Associate all item materials available
CREATE TABLE items_materials (
  items_id        INTEGER REFERENCES items(item_id) ON UPDATE CASCADE ON DELETE CASCADE,
  materials_id    INTEGER REFERENCES materials(material_id) ON UPDATE CASCADE ON DELETE CASCADE,
  materials_order SMALLINT,
  PRIMARY KEY (items_id, materials_id)
);
-- Keep things orderly.
CREATE UNIQUE INDEX idx_items_coll_materials_order ON items_materials (items_id, materials_order);
-- Associate all item printers available
CREATE TABLE items_printers (
  items_id        INTEGER REFERENCES items(item_id) ON UPDATE CASCADE ON DELETE CASCADE,
  printers_id     INTEGER REFERENCES printers(printer_id) ON UPDATE CASCADE ON DELETE CASCADE,
  printers_order  SMALLINT,
  PRIMARY KEY (items_id, printers_id)
);
-- Keep things orderly.
CREATE UNIQUE INDEX idx_items_coll_printers_order ON items_printers (items_id, printers_order);


-- TODO: confirm
CREATE TABLE orders (
  order_id       serial PRIMARY KEY,
  active         boolean NOT NULL DEFAULT true,
  attributes     integer[] NULL,
  title          text NOT NULL,
  -- items          integer[] ELEMENT REFERENCES items,
  -- materials      integer[] ELEMENT REFERENCES materials,
  -- printers       integer[] ELEMENT REFERENCES printers,
  status         statuses NOT NULL DEFAULT 'init'::statuses,
  started_at     timestamptz NOT NULL DEFAULT NOW(),
  ended_at       timestamptz NULL,
  billing        jsonb NULL,
  card           jsonb NULL,
  fulfilment     jsonb NULL,
  shipping       jsonb NULL
);

------------------------------------------------------------
-- Setup Accounts, Users & Subscriptions
------------------------------------------------------------

CREATE TYPE roles AS ENUM ('ADMIN', 'OWNER', 'MEMBER', 'BANNED');
CREATE TYPE subscript_type AS ENUM ('beta', 'free', 'monthly', 'yearly');

-- TODO: change this to free once launched
CREATE TABLE subscriptions (
  subscription_id    serial PRIMARY KEY,
  active             boolean NOT NULL DEFAULT true,
  amount             integer NOT NULL,
  currency           text NULL,
  title              text NULL,
  type               subscript_type NOT NULL DEFAULT 'beta'::subscript_type
);


-- TODO: confirm items orders
CREATE TABLE users (
  user_id             bigserial PRIMARY KEY,
  accounts       integer[] PRIMARY KEY NOT NULL REFERENCES accounts(id),
  created_at     timestamptz NOT NULL DEFAULT NOW(),
  last_login     timestamptz NOT NULL DEFAULT NOW(),
  roles          role NOT NULL DEFAULT 'MEMBER'::roles,
  first_name     text NOT NULL,
  last_name      text NULL,
  email          text NOT NULL,
  mask           text NOT NULL,
  items          integer[] NULL,
  orders         integer[] NULL,
  settings       jsonb NULL,
  stats          jsonb NULL
);

-- Speed up lower(email) lookup
CREATE INDEX lower_email ON users (lower(email));

-- TODO: confirm
CREATE TABLE accounts (
  account_id            bigserial PRIMARY KEY,
  created_at            timestamptz NOT NULL DEFAULT NOW(),
  -- admins                integer[] ELEMENT REFERENCES users,
  -- users                 integer[] ELEMENT REFERENCES users,
  -- printers              integer[] ELEMENT REFERENCES printers,
  -- materials             integer[] ELEMENT REFERENCES materials,
  title                 text NOT NULL,
  settings              jsonb NULL,
  stats                 jsonb NULL,
  subscription_id       int PRIMARY KEY NOT NULL REFERENCES subscriptions(id),
  subscription_start    timestamptz NOT NULL DEFAULT NOW(),
  subscription_end      timestamptz NULL
);

------------------------------------------------------------
-- Setup Authentication: Session & Masks
------------------------------------------------------------

CREATE TABLE sessions (
  session_id    uuid PRIMARY KEY,
  user_id       int  NOT NULL REFERENCES users(user_id),
  ip_address    inet NOT NULL,
  user_agent    text NULL,
  expired_at    timestamptz NOT NULL DEFAULT NOW() + INTERVAL '4 weeks',
  created_at    timestamptz NOT NULL DEFAULT NOW()
);

CREATE TABLE masks (
  user_id       int PRIMARY KEY NOT NULL REFERENCES users(user_id),
  email         text NOT NULL,
  mask          text NOT NULL
);

-- Speed up user_id FK joins
CREATE INDEX masks__user_id ON masks (user_id);
CREATE INDEX sessions__user_id ON sessions (user_id);

-- CREATE VIEW active_sessions AS
--   SELECT *
--   FROM sessions
--   WHERE expired_at > NOW()
-- ;
