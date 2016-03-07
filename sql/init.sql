DROP SCHEMA public CASCADE;
CREATE SCHEMA public;

------------------------------------------------------------
-- Setup Simple Attribute Data
------------------------------------------------------------
-- TODO: confirm
CREATE TABLE bases (
  id             serial PRIMARY KEY,
  active         boolean NOT NULL DEFAULT true,
  name           text NOT NULL,
  normalized     text NULL
);

-- TODO: confirm
CREATE TABLE nozzles (
  id             serial PRIMARY KEY,
  active         boolean NOT NULL DEFAULT true,
  name           text NOT NULL,
  size           integer NOT NULL
);

-- TODO: confirm
CREATE TABLE price_points (
  id             serial PRIMARY KEY,
  active         boolean NOT NULL DEFAULT true,
  amount         integer NOT NULL,
  currency       text NOT NULL,
  measure        text NOT NULL,
  name           text NOT NULL
);

-- TODO: confirm
CREATE TABLE volumes (
  id             serial PRIMARY KEY,
  active         boolean NOT NULL DEFAULT true,
  measure        text NOT NULL
);

-- TODO: confirm
CREATE TABLE weights (
  id             serial PRIMARY KEY,
  active         boolean NOT NULL DEFAULT true,
  measure        text NOT NULL
);

------------------------------------------------------------
-- Setup Complex Attribute Data
------------------------------------------------------------
-- TODO: confirm
CREATE TABLE brands (
  id             serial PRIMARY KEY,
  active         boolean NOT NULL DEFAULT true,
  name           text NOT NULL,
  material_type  int NOT NULL REFERENCES material_types(id)
);

-- TODO: confirm
CREATE TABLE colors (
  id             serial PRIMARY KEY,
  active         boolean NOT NULL DEFAULT true,
  images         text[] NULL,
  name           text NOT NULL,
  normalized     text NOT NULL
);

-- TODO: confirm
CREATE TABLE material_types (
  id             serial PRIMARY KEY,
  active         boolean NOT NULL DEFAULT true,
  base           int NOT NULL REFERENCES bases(id),
  name           text NOT NULL,
  normalized     text NULL
);

------------------------------------------------------------
-- Setup Materials, Printers, Orders & Items
------------------------------------------------------------

CREATE TYPE statuses AS ENUM ('init', 'pending', 'processing', 'fulfilled');
-- TODO: confirm printers materials
CREATE TABLE items (
  id             serial PRIMARY KEY,
  active         boolean NOT NULL DEFAULT true,
  attributes     integer[] NULL,
  cost           integer NULL,
  name           text NOT NULL,
  materials      integer[] ELEMENT REFERENCES materials,
  model          jsonb NULL,
  printers       integer[] ELEMENT REFERENCES printers,
  resolutions    integer[] NULL,
  status         statuses NOT NULL DEFAULT 'init'::statuses,
  started_at     timestamptz NOT NULL DEFAULT NOW(),
  ended_at       timestamptz NULL
);

-- TODO: confirm
CREATE TABLE materials (
  id             serial PRIMARY KEY,
  batch_id       int NULL,
  active         boolean NOT NULL DEFAULT true,
  attributes     integer[] NULL,
  compliant      boolean NOT NULL DEFAULT true,
  name           text NOT NULL,
  sku            text NOT NULL,
  added_at       timestamptz NOT NULL DEFAULT NOW(),
  opened_at      timestamptz NULL,
  amount_total   int NULL,
  amount_used    int NULL
);

-- TODO: confirm
CREATE TABLE printers (
  id             serial PRIMARY KEY,
  active         boolean NOT NULL DEFAULT true,
  attributes     integer[] NULL,
  accessories    integer[] NULL,
  created_at     timestamptz NOT NULL DEFAULT NOW(),
  dimensions     jsonb NULL,
  name           text NOT NULL,
  hours_online   int NULL,
  hours_printed  int NULL,
  materials      integer[] ELEMENT REFERENCES materials,
  resolution     jsonb NULL
);

-- TODO: confirm
CREATE TABLE orders (
  id             serial PRIMARY KEY,
  active         boolean NOT NULL DEFAULT true,
  attributes     integer[] NULL,
  name           text NOT NULL,
  items          integer[] ELEMENT REFERENCES items,
  materials      integer[] ELEMENT REFERENCES materials,
  printers       integer[] ELEMENT REFERENCES printers,
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
  id             serial PRIMARY KEY,
  active         boolean NOT NULL DEFAULT true,
  amount         integer NOT NULL,
  currency       text NULL,
  name           text NULL,
  type           subscript_type NOT NULL DEFAULT 'beta'::subscript_type
);

-- TODO: confirm
CREATE TABLE accounts (
  id                    bigserial PRIMARY KEY,
  created_at            timestamptz NOT NULL DEFAULT NOW(),
  admins                integer[] ELEMENT REFERENCES users,
  users                 integer[] ELEMENT REFERENCES users,
  printers              integer[] ELEMENT REFERENCES printers,
  materials             integer[] ELEMENT REFERENCES materials,
  name                  text NOT NULL,
  settings              jsonb NULL,
  stats                 jsonb NULL,
  subscription_id       int PRIMARY KEY NOT NULL REFERENCES subscriptions(id),
  subscription_start    timestamptz NOT NULL DEFAULT NOW(),
  subscription_end      timestamptz NULL
);

-- TODO: confirm items orders
CREATE TABLE users (
  id             bigserial PRIMARY KEY,
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

------------------------------------------------------------
-- Setup Authentication: Session & Masks
------------------------------------------------------------

CREATE TABLE sessions (
  id            uuid PRIMARY KEY,
  user_id       int  NOT NULL REFERENCES users(id),
  ip_address    inet NOT NULL,
  user_agent    text NULL,
  expired_at    timestamptz NOT NULL DEFAULT NOW() + INTERVAL '4 weeks',
  created_at    timestamptz NOT NULL DEFAULT NOW()
);

CREATE TABLE masks (
  user_id       int PRIMARY KEY NOT NULL REFERENCES users(id),
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
