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
    cluster_centers float[] := ARRAY[0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9];
    cluster_size integer := 2500;
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

\set ivfflat_lists 100

-- Create IVFFlat index with different list sizes to test various scenarios
CREATE INDEX idx_ivfflat_l2 ON ivfflat_benchmark
USING ivfflat (embedding vector_l2_ops)
WITH (lists = :ivfflat_lists);

CREATE INDEX idx_ivfflat_ip ON ivfflat_benchmark
USING ivfflat (embedding vector_ip_ops)
WITH (lists = :ivfflat_lists);

CREATE INDEX idx_ivfflat_cosine ON ivfflat_benchmark
USING ivfflat (embedding vector_cosine_ops)
WITH (lists = :ivfflat_lists);

-- Force index to be used and gather statistics
ANALYZE ivfflat_benchmark;

\echo "Data Size:"
SELECT pg_size_pretty(pg_total_relation_size('ivfflat_benchmark')) AS benchmark_size;

\echo "List Recommendation:"
SELECT
    COUNT(*) as total_rows,
    sqrt(COUNT(*))::integer as suggested_lists
FROM ivfflat_benchmark;

-- Configure for benchmarking
SET enable_seqscan = OFF;
SET enable_indexscan = ON;
SET ivfflat.smart_probes_distance_threshold = 2.0;


/*
EXPLAIN ANALYZE SELECT *
FROM ivfflat_benchmark v
ORDER BY v.embedding <-> '[0.9039646,0.9010112,0.9065078,0.90712094,0.902763,0.9062566,0.90227586,0.90845644,0.90905124,0.90413564,0.9091468,0.90402406,0.9073526,0.90856963,0.90729284,0.9089268,0.9029817,0.90699965,0.9097149,0.9078772,0.90919346,0.9078481,0.90569913,0.9088807,0.9047945,0.9088986,0.9049961,0.90802896,0.9086448,0.9051082,0.9071104,0.9084795,0.9070391,0.9047063,0.90871966,0.90645576,0.9081397,0.9037355,0.90710104,0.90409577,0.90188175,0.9094159,0.90786433,0.90898997,0.9073209,0.9057574,0.90591663,0.9088093,0.9035977,0.9075275,0.90915436,0.9049728,0.90811414,0.9054835,0.9096969,0.9074746,0.9025596,0.9052071,0.9095393,0.90336376,0.9095343,0.90493244,0.9076231,0.90642273,0.90926164,0.90509105,0.90854293,0.902448,0.90692204,0.9045389,0.9099099,0.9024901,0.90433425,0.9054089,0.9017052,0.9034479,0.9037238,0.90392745,0.9010495,0.9034535,0.9098131,0.90804094,0.9093028,0.90404063,0.9089259,0.90965426,0.90927285,0.9025135,0.90666753,0.9086201,0.90605813,0.9039171,0.90752625,0.90933055,0.90812284,0.90565115,0.90133154,0.90312225,0.9017979,0.9087515,0.9061068,0.9049567,0.90820295,0.90273297,0.9077692,0.90646356,0.9042801,0.9061615,0.9093412,0.9062175,0.909054,0.9077273,0.9062414,0.90602416,0.90117973,0.9094154,0.90574974,0.9029169,0.90335697,0.9047827,0.90667367,0.90110517,0.9060709,0.9076397,0.9089548,0.9046137,0.90690947,0.90961933]'
LIMIT 25;
*/

DROP VIEW IF EXISTS ivfflat_benchmark_view;
CREATE VIEW ivfflat_benchmark_view AS
SELECT *
FROM ivfflat_benchmark v
ORDER BY v.embedding <-> '[0.9039646,0.9010112,0.9065078,0.90712094,0.902763,0.9062566,0.90227586,0.90845644,0.90905124,0.90413564,0.9091468,0.90402406,0.9073526,0.90856963,0.90729284,0.9089268,0.9029817,0.90699965,0.9097149,0.9078772,0.90919346,0.9078481,0.90569913,0.9088807,0.9047945,0.9088986,0.9049961,0.90802896,0.9086448,0.9051082,0.9071104,0.9084795,0.9070391,0.9047063,0.90871966,0.90645576,0.9081397,0.9037355,0.90710104,0.90409577,0.90188175,0.9094159,0.90786433,0.90898997,0.9073209,0.9057574,0.90591663,0.9088093,0.9035977,0.9075275,0.90915436,0.9049728,0.90811414,0.9054835,0.9096969,0.9074746,0.9025596,0.9052071,0.9095393,0.90336376,0.9095343,0.90493244,0.9076231,0.90642273,0.90926164,0.90509105,0.90854293,0.902448,0.90692204,0.9045389,0.9099099,0.9024901,0.90433425,0.9054089,0.9017052,0.9034479,0.9037238,0.90392745,0.9010495,0.9034535,0.9098131,0.90804094,0.9093028,0.90404063,0.9089259,0.90965426,0.90927285,0.9025135,0.90666753,0.9086201,0.90605813,0.9039171,0.90752625,0.90933055,0.90812284,0.90565115,0.90133154,0.90312225,0.9017979,0.9087515,0.9061068,0.9049567,0.90820295,0.90273297,0.9077692,0.90646356,0.9042801,0.9061615,0.9093412,0.9062175,0.909054,0.9077273,0.9062414,0.90602416,0.90117973,0.9094154,0.90574974,0.9029169,0.90335697,0.9047827,0.90667367,0.90110517,0.9060709,0.9076397,0.9089548,0.9046137,0.90690947,0.90961933]'
LIMIT 25;

DO $$
DECLARE
    probes float[] := ARRAY[5, 8, 10];
    i float;
    iterations integer := 10000;
    smart_probes text;
BEGIN
    FOREACH smart_probes IN ARRAY ARRAY['ON', 'OFF']
    LOOP
        EXECUTE 'SET ivfflat.smart_probes = ' || smart_probes;

        FOREACH i IN ARRAY probes
        LOOP
            EXECUTE 'SET ivfflat.probes = ' || i;

            PERFORM run_benchmark(
                'ivfflat_l2_distance (probes = ' || i || ', smart_probes = ' || smart_probes || ')',
                'idx_ivfflat_l2',
                128,
                iterations,
                $sql$
                    SELECT * FROM ivfflat_benchmark_view;
                $sql$
            );
        END LOOP;
    END LOOP;
END;
$$;

-- Clean up
DROP TABLE ivfflat_benchmark CASCADE;
