-- IVFFlat Scan Function Call Optimization Benchmark
-- This script measures search performance improvements from direct distance function calls

-- Clean up any existing test data
DROP TABLE IF EXISTS ivfflat_benchmark CASCADE;

-- Create test table with vectors
CREATE TABLE ivfflat_benchmark (
    id SERIAL PRIMARY KEY,
    embedding vector(128)
);

\echo "Inserting test clustered data into ivfflat_benchmark."
DO $$
DECLARE
    cluster_centers float[] := ARRAY[0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9];
    cluster_size integer := 100000;
    i float;
BEGIN
    FOREACH i IN ARRAY cluster_centers
    LOOP
        INSERT INTO ivfflat_benchmark (embedding)
        SELECT generate_nearby_random_floats(128, i)::vector(128)
        FROM generate_series(1, cluster_size);
    END LOOP;
END;
$$;

-- Create IVFFlat index with different list sizes to test various scenarios
CREATE INDEX idx_ivfflat_l2 ON ivfflat_benchmark
USING ivfflat (embedding vector_l2_ops)
WITH (lists = 100);

CREATE INDEX idx_ivfflat_ip ON ivfflat_benchmark
USING ivfflat (embedding vector_ip_ops)
WITH (lists = 100);

CREATE INDEX idx_ivfflat_cosine ON ivfflat_benchmark
USING ivfflat (embedding vector_cosine_ops)
WITH (lists = 100);

-- Force index to be used and gather statistics
ANALYZE ivfflat_benchmark;

\echo "Data Size:"
SELECT pg_size_pretty(pg_total_relation_size('ivfflat_benchmark')) AS benchmark_size;

-- Configure for benchmarking
SET enable_seqscan = OFF;
SET enable_indexscan = ON;
SET ivfflat.smart_probes_distance_threshold = 2.0;

-- Test L2 distance with smart_probes = OFF
SET ivfflat.smart_probes = OFF;
\echo "Testing L2 distance with smart_probes = OFF"

EXPLAIN ANALYZE WITH query_vector AS (
    SELECT generate_nearby_random_floats(128, 1.0)::vector as vec
)
SELECT *
FROM ivfflat_benchmark v, query_vector q
ORDER BY v.embedding <-> q.vec
LIMIT 25;

DO $$
DECLARE
    probes float[] := ARRAY[5, 15, 20, 30, 50, 100];
    i float;
BEGIN
    FOREACH i IN ARRAY probes
    LOOP
        EXECUTE 'SET ivfflat.probes = ' || i;

        PERFORM run_benchmark(
            'ivfflat_l2_distance (probes = ' || i || ', smart_probes = OFF)',
            'idx_ivfflat_l2',
            128,
            1000,
            $sql$
                WITH query_vector AS (
                    SELECT generate_nearby_random_floats(128, random())::vector as vec
                )
                SELECT id
                FROM ivfflat_benchmark v, query_vector q
                ORDER BY v.embedding <-> q.vec
                LIMIT 25;
            $sql$
        );
    END LOOP;
END;
$$;

-- Test L2 distance with smart_probes = ON
SET ivfflat.smart_probes = ON;
\echo "Testing L2 distance with smart_probes = ON"

DO $$
DECLARE
    probes float[] := ARRAY[5, 15, 20, 30, 50, 100];
    i float;
BEGIN
    FOREACH i IN ARRAY probes
    LOOP
        EXECUTE 'SET ivfflat.probes = ' || i;

        PERFORM run_benchmark(
            'ivfflat_l2_distance (probes = ' || i || ', smart_probes = ON)',
            'idx_ivfflat_l2',
            128,
            1000,
            $sql$
                WITH query_vector AS (
                    SELECT generate_nearby_random_floats(128, random())::vector as vec
                )
                SELECT id
                FROM ivfflat_benchmark v, query_vector q
                ORDER BY v.embedding <-> q.vec
                LIMIT 25;
            $sql$
        );
    END LOOP;
END;
$$;

-- Clean up
DROP TABLE ivfflat_benchmark CASCADE;
