#!/usr/bin/env bash
# Şemayı ve gizlilik kurallarını yerel bir Postgres'te sınar (Supabase'e bağlanmaz).
# Gerekenler: çalışan bir Postgres, psql, createdb, dropdb.
#   ./supabase/tests/run_local.sh
# Beklenen: 10_rls_test.sql çıktısındaki ERROR satırları yalnızca "RLS", "check constraint",
# "permission denied" ve "Oturum açık değil" olmalı; B'nin satırı 0, A'nın satırı 1 kalmalı.
set -euo pipefail
DB=${DB:-cuzdan_rls_test}
HERE=$(cd "$(dirname "$0")" && pwd)
dropdb --if-exists "$DB"
createdb "$DB"
psql -q -v ON_ERROR_STOP=1 -d "$DB" -f "$HERE/00_supabase_stub.sql"
for migration in "$HERE"/../migrations/*.sql; do
  psql -q -v ON_ERROR_STOP=1 -d "$DB" -f "$migration"
done
psql -d "$DB" -f "$HERE/10_rls_test.sql"
