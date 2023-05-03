CREATE TABLE IF NOT EXISTS "schema_migrations" ("version" INTEGER PRIMARY KEY, "inserted_at" TEXT);
CREATE TABLE IF NOT EXISTS "embeddings" ("id" INTEGER PRIMARY KEY AUTOINCREMENT, "source" TEXT NOT NULL, "content" TEXT NOT NULL, "embedding" BLOB NOT NULL) STRICT;
CREATE TABLE sqlite_sequence(name,seq);
INSERT INTO schema_migrations VALUES(20230502114423,'2023-05-03T05:29:51');
