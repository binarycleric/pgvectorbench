-- K-means Prefetch Optimization Benchmark
-- This script benchmarks the performance improvements from prefetch optimization
-- in the ComputeNewCenters function and related k-means operations.

-- Create IVFFlat index to trigger k-means clustering
-- This will exercise the ComputeNewCenters function with prefetch optimization

SET work_mem = '32MB';
SET maintenance_work_mem = '1GB';

CREATE TABLE kmeans_benchmark (
    id integer,
    v1 vector(1536) STORAGE EXTENDED
);

INSERT INTO kmeans_benchmark (id, v1)
SELECT i, generate_random_floats(1536)
FROM generate_series(1, 100000) i;

SELECT
    'kmeans_benchmark' as table_name,
    pg_size_pretty(pg_total_relation_size('kmeans_benchmark')) as size_pretty,
    ROUND(pg_total_relation_size('kmeans_benchmark') / 1024.0 / 1024.0 / 1024.0, 2) as size_gb;

\timing on

-- Benchmark 1: Index creation time (this exercises k-means clustering)


-- Test with different list sizes to exercise different k-means scenarios
-- Small number of lists = more iterations, larger k-means workload
CREATE INDEX CONCURRENTLY idx_kmeans_small_lists ON kmeans_benchmark
USING ivfflat (v1 vector_l2_ops) WITH (lists = 10);

DROP INDEX idx_kmeans_small_lists;

-- Test with different list sizes to exercise different k-means scenarios
-- Small number of lists = more iterations, larger k-means workload
CREATE INDEX CONCURRENTLY idx_kmeans_medium_lists ON kmeans_benchmark
USING ivfflat (v1 vector_l2_ops) WITH (lists = 100);

DROP INDEX idx_kmeans_medium_lists;

-- Large number of lists
CREATE INDEX CONCURRENTLY idx_kmeans_large_lists ON kmeans_benchmark
USING ivfflat (v1 vector_l2_ops) WITH (lists = 1000);

DROP INDEX idx_kmeans_large_lists;

\timing off

-- Benchmark 2: Query performance with different probe counts
-- This tests the overall system performance including k-means overhead

-- Generate a test query vector
SELECT generate_random_floats(1536)::vector AS query_vector \gset

-- Test with different probe counts
\timing on

-- Low probe count (more k-means work)
SELECT id, v1 <-> :'query_vector' as distance
FROM kmeans_benchmark
ORDER BY v1 <-> :'query_vector'
LIMIT 10;

-- Medium probe count
SET ivfflat.probes = 10;
SELECT id, v1 <-> :'query_vector' as distance
FROM kmeans_benchmark
ORDER BY v1 <-> :'query_vector'
LIMIT 10;

-- High probe count
SET ivfflat.probes = 50;
SELECT id, v1 <-> :'query_vector' as distance
FROM kmeans_benchmark
ORDER BY v1 <-> :'query_vector'
LIMIT 10;

\timing off

-- Benchmark 3: Memory usage and cache performance
-- Monitor system resources during index creation

-- Check memory usage before
SELECT pg_size_pretty(pg_relation_size('kmeans_benchmark')) as table_size;

-- Create index and monitor memory
CREATE INDEX CONCURRENTLY idx_kmeans_final ON kmeans_benchmark
USING ivfflat (v1 vector_l2_ops) WITH (lists = 100);

-- Check memory usage after
SELECT pg_size_pretty(pg_relation_size('idx_kmeans_final')) as index_size;

-- Benchmark 4: Concurrent performance
-- Test multiple concurrent queries to stress the system

-- Start multiple concurrent sessions and run:
-- SELECT id, v <-> array_to_vector(array_fill(random()::float, ARRAY[1536])) as distance
-- FROM kmeans_benchmark
-- ORDER BY v <-> array_to_vector(array_fill(random()::float, ARRAY[1536]))
-- LIMIT 10;

-- Cleanup
DROP INDEX IF EXISTS idx_kmeans_final;
DROP TABLE IF EXISTS kmeans_benchmark;

-- Performance Analysis Queries
-- Run these to analyze the performance impact:

-- 1. Check if prefetch optimization is working:
-- Look for reduced cache misses in system monitoring tools
-- Monitor CPU cache hit rates during index creation

-- 2. Compare before/after performance:
-- Run this script before and after applying prefetch optimization
-- Compare the timing results

-- 3. System-level monitoring:
-- Use tools like perf, vtune, or similar to measure:
-- - Cache miss rates
-- - Memory bandwidth utilization
-- - CPU utilization patterns

-- Expected improvements:
-- - 5-15% faster index creation for large datasets
-- - Reduced cache misses during k-means clustering
-- - Better performance under memory pressure
-- - More consistent performance across different vector sizes