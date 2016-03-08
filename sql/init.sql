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

-- MATERIALS
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

-- PRINTERS
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
  resolution     jsonb NULL
  -- materials   handled in the printers_materials table
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

-- ITEMS
CREATE TABLE items (
  item_id        serial PRIMARY KEY,
  active         boolean NOT NULL DEFAULT true,
  attributes     integer[] NULL,
  cost           integer NULL,
  title          text NOT NULL,
  model          jsonb NULL,
  resolutions    integer[] NULL,
  status         statuses NOT NULL DEFAULT 'init'::statuses,
  started_at     timestamptz NOT NULL DEFAULT NOW(),
  ended_at       timestamptz NULL
  -- materials   handled in the items_materials table
  -- printers    handled in the items_printers table
);
-- Associate all item materials available
CREATE TABLE items_materials (
  items_id        INTEGER REFERENCES items(item_id) ON UPDATE CASCADE ON DELETE CASCADE,
  materials_id    INTEGER REFERENCES materials(material_id) ON UPDATE CASCADE ON DELETE CASCADE,
  materials_order SMALLINT,
  PRIMARY KEY (items_id, materials_id)
);
-- Associate all item printers available
CREATE TABLE items_printers (
  items_id        INTEGER REFERENCES items(item_id) ON UPDATE CASCADE ON DELETE CASCADE,
  printers_id     INTEGER REFERENCES printers(printer_id) ON UPDATE CASCADE ON DELETE CASCADE,
  printers_order  SMALLINT,
  PRIMARY KEY (items_id, printers_id)
);
-- Keep things orderly.
CREATE UNIQUE INDEX idx_items_coll_materials_order ON items_materials (items_id, materials_order);
CREATE UNIQUE INDEX idx_items_coll_printers_order ON items_printers (items_id, printers_order);

-- ORDERS
CREATE TABLE orders (
  order_id       serial PRIMARY KEY,
  active         boolean NOT NULL DEFAULT true,
  attributes     integer[] NULL,
  title          text NOT NULL,
  status         statuses NOT NULL DEFAULT 'init'::statuses,
  started_at     timestamptz NOT NULL DEFAULT NOW(),
  ended_at       timestamptz NULL,
  billing        jsonb NULL,
  card           jsonb NULL,
  fulfilment     jsonb NULL,
  shipping       jsonb NULL
  -- items       handled in the orders_items table
  -- materials   handled in the orders_materials table
  -- printers    handled in the orders_printers table
);
-- Associate all order items available
CREATE TABLE orders_items (
  orders_id       INTEGER REFERENCES orders(order_id) ON UPDATE CASCADE ON DELETE CASCADE,
  items_id        INTEGER REFERENCES items(item_id) ON UPDATE CASCADE ON DELETE CASCADE,
  items_order     SMALLINT,
  PRIMARY KEY (orders_id, items_id)
);
-- Associate all order materials available
CREATE TABLE orders_materials (
  orders_id       INTEGER REFERENCES orders(order_id) ON UPDATE CASCADE ON DELETE CASCADE,
  materials_id    INTEGER REFERENCES materials(material_id) ON UPDATE CASCADE ON DELETE CASCADE,
  materials_order SMALLINT,
  PRIMARY KEY (orders_id, materials_id)
);
-- Associate all order printers available
CREATE TABLE orders_printers (
  orders_id       INTEGER REFERENCES orders(order_id) ON UPDATE CASCADE ON DELETE CASCADE,
  printers_id     INTEGER REFERENCES printers(printer_id) ON UPDATE CASCADE ON DELETE CASCADE,
  printers_order  SMALLINT,
  PRIMARY KEY (orders_id, printers_id)
);
-- Keep things orderly.
CREATE UNIQUE INDEX idx_orders_coll_items_order ON orders_items (orders_id, items_order);
CREATE UNIQUE INDEX idx_orders_coll_materials_order ON orders_materials (orders_id, materials_order);
CREATE UNIQUE INDEX idx_orders_coll_printers_order ON orders_printers (orders_id, printers_order);

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


-- USERS
CREATE TABLE users (
  user_id        bigserial PRIMARY KEY,
  created_at     timestamptz NOT NULL DEFAULT NOW(),
  last_login     timestamptz NOT NULL DEFAULT NOW(),
  roles          roles NOT NULL DEFAULT 'MEMBER'::roles,
  first_name     text NOT NULL,
  last_name      text NULL,
  email          text NOT NULL,
  mask           text NOT NULL,
  settings       jsonb NULL,
  stats          jsonb NULL
  -- accounts    handled in the users_accounts table
  -- items       handled in the users_items table
  -- orders      handled in the users_orders table
);
-- Associate all users items available
CREATE TABLE users_items (
  users_id        INTEGER REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE CASCADE,
  items_id        INTEGER REFERENCES items(item_id) ON UPDATE CASCADE ON DELETE CASCADE,
  items_order     SMALLINT,
  PRIMARY KEY (users_id, items_id)
);
-- Associate all users orders available
CREATE TABLE users_orders (
  users_id         INTEGER REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE CASCADE,
  orders_id        INTEGER REFERENCES orders(order_id) ON UPDATE CASCADE ON DELETE CASCADE,
  orders_order     SMALLINT,
  PRIMARY KEY (users_id, orders_id)
);
-- Keep things orderly.
CREATE UNIQUE INDEX idx_users_coll_items_order ON users_items (users_id, items_order);
CREATE UNIQUE INDEX idx_users_coll_orders_order ON users_orders (users_id, orders_order);
-- Speed up lower(email) lookup
CREATE INDEX lower_email ON users (lower(email));


-- ACCOUNTS
CREATE TABLE accounts (
  account_id            bigserial PRIMARY KEY,
  created_at            timestamptz NOT NULL DEFAULT NOW(),
  title                 text NOT NULL,
  settings              jsonb NULL,
  stats                 jsonb NULL,
  subscription_id       integer NOT NULL REFERENCES subscriptions(subscription_id),
  subscription_start    timestamptz NOT NULL DEFAULT NOW(),
  subscription_end      timestamptz NULL
  -- users              handled in the accounts_users table
  -- printers           handled in the accounts_printers table
  -- materials          handled in the accounts_materials table
);
-- Associate all account users available
CREATE TABLE accounts_users (
  accounts_id     INTEGER REFERENCES accounts(account_id) ON UPDATE CASCADE ON DELETE CASCADE,
  users_id        INTEGER REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE CASCADE,
  users_order     SMALLINT,
  PRIMARY KEY (accounts_id, users_id)
);
-- Associate all accounts materials available
CREATE TABLE accounts_materials (
  accounts_id     INTEGER REFERENCES accounts(account_id) ON UPDATE CASCADE ON DELETE CASCADE,
  materials_id    INTEGER REFERENCES materials(material_id) ON UPDATE CASCADE ON DELETE CASCADE,
  materials_order SMALLINT,
  PRIMARY KEY (accounts_id, materials_id)
);
-- Associate all accounts printers available
CREATE TABLE accounts_printers (
  accounts_id     INTEGER REFERENCES accounts(account_id) ON UPDATE CASCADE ON DELETE CASCADE,
  printers_id     INTEGER REFERENCES printers(printer_id) ON UPDATE CASCADE ON DELETE CASCADE,
  printers_order  SMALLINT,
  PRIMARY KEY (accounts_id, printers_id)
);
-- Associate all users accounts available
CREATE TABLE users_accounts (
  users_id           INTEGER REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE CASCADE,
  accounts_id        INTEGER REFERENCES accounts(account_id) ON UPDATE CASCADE ON DELETE CASCADE,
  accounts_order     SMALLINT,
  PRIMARY KEY (users_id, accounts_id)
);
-- Keep things orderly.
CREATE UNIQUE INDEX idx_accounts_coll_users_order ON accounts_users (accounts_id, users_order);
CREATE UNIQUE INDEX idx_accounts_coll_materials_order ON accounts_materials (accounts_id, materials_order);
CREATE UNIQUE INDEX idx_accounts_coll_printers_order ON accounts_printers (accounts_id, printers_order);
CREATE UNIQUE INDEX idx_users_coll_accounts_order ON users_accounts (users_id, accounts_order);


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

CREATE VIEW active_sessions AS
  SELECT *
  FROM sessions
  WHERE expired_at > NOW()
;
