#lang north

-- @revision: 5ee13f54ba2821002e08628895500cfb
-- @parent: efed79200bf19e497ce82c46ae7c7999
-- @description: create "short_urls" table.
-- @up {
CREATE TABLE short_urls(
  id serial PRIMARY KEY,
  code TEXT NOT NULL UNIQUE,
  url TEXT NOT NULL,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  create_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
)
-- }

-- @down {
DROP TABLE short_urls;
-- }
