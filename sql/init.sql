DROP SCHEMA public CASCADE;
CREATE SCHEMA public;

------------------------------------------------------------
-- Setup Baseline Attribute Data
------------------------------------------------------------
--TODO:

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

-- TODO: confirm printers materials
CREATE TABLE accounts (
  id                    bigserial PRIMARY KEY,
  created_at            timestamptz NOT NULL DEFAULT NOW(),
  admins                integer[] ELEMENT REFERENCES users,
  users                 integer[] ELEMENT REFERENCES users,
  printers              integer[],
  materials             integer[],
  name                  text NOT NULL,
  settings              jsonb NULL,
  stats                 jsonb NULL,
  subscription_id       int PRIMARY KEY NOT NULL REFERENCES subscriptions(id),
  subscription_start    timestamptz NOT NULL DEFAULT NOW(),
  subscription_end      NULL
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
  items          integer[],
  orders         integer[],
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
