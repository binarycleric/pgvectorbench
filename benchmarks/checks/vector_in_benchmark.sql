-- Vector Input Function Performance Benchmark
-- This script benchmarks the performance of vector_in function
-- which parses string representations of vectors like [1.0, 2.0, 3.0]

-- Create test table for benchmarking
CREATE TABLE IF NOT EXISTS vector_in_benchmark (
    id SERIAL PRIMARY KEY,
    vector_str TEXT,
    vector_val vector(1536)  -- OpenAI embedding size
);

-- Generate test data with different vector sizes and formats
-- Small vectors (128 dimensions)
INSERT INTO vector_in_benchmark (vector_str)
SELECT '[' || string_agg(random()::text, ',') || ']'
FROM (
    SELECT generate_series(1, 128) as i
) t;

-- Medium vectors (512 dimensions)
INSERT INTO vector_in_benchmark (vector_str)
SELECT '[' || string_agg(random()::text, ',') || ']'
FROM (
    SELECT generate_series(1, 512) as i
) t;

-- Large vectors (1536 dimensions - OpenAI size)
INSERT INTO vector_in_benchmark (vector_str)
SELECT '[' || string_agg(random()::text, ',') || ']'
FROM (
    SELECT generate_series(1, 1536) as i
) t;

-- Very large vectors (4096 dimensions)
INSERT INTO vector_in_benchmark (vector_str)
SELECT '[' || string_agg(random()::text, ',') || ']'
FROM (
    SELECT generate_series(1, 4096) as i
) t;

-- Generate multiple test vectors for each size
-- Small vectors (10k test cases)
INSERT INTO vector_in_benchmark (vector_str)
SELECT '[' || string_agg(random()::text, ',') || ']'
FROM (
    SELECT generate_series(1, 128) as i
) t
CROSS JOIN generate_series(1, 10000);

-- Medium vectors (5k test cases)
INSERT INTO vector_in_benchmark (vector_str)
SELECT '[' || string_agg(random()::text, ',') || ']'
FROM (
    SELECT generate_series(1, 512) as i
) t
CROSS JOIN generate_series(1, 5000);

-- Large vectors (1k test cases)
INSERT INTO vector_in_benchmark (vector_str)
SELECT '[' || string_agg(random()::text, ',') || ']'
FROM (
    SELECT generate_series(1, 1536) as i
) t
CROSS JOIN generate_series(1, 1000);

-- Very large vectors (100 test cases)
INSERT INTO vector_in_benchmark (vector_str)
SELECT '[' || string_agg(random()::text, ',') || ']'
FROM (
    SELECT generate_series(1, 4096) as i
) t
CROSS JOIN generate_series(1, 100);

-- Benchmark 1: Direct vector_in function calls
\timing on

-- Test small vectors (128 dimensions)
SELECT COUNT(*) FROM (
    SELECT vector_in(vector_str::cstring, 0, 128) as v
    FROM vector_in_benchmark
    WHERE id <= 10000
) t;

-- Test medium vectors (512 dimensions)
SELECT COUNT(*) FROM (
    SELECT vector_in(vector_str::cstring, 0, 512) as v
    FROM vector_in_benchmark
    WHERE id > 10000 AND id <= 15000
) t;

-- Test large vectors (1536 dimensions)
SELECT COUNT(*) FROM (
    SELECT vector_in(vector_str::cstring, 0, 1536) as v
    FROM vector_in_benchmark
    WHERE id > 15000 AND id <= 16000
) t;

-- Test very large vectors (4096 dimensions)
SELECT COUNT(*) FROM (
    SELECT vector_in(vector_str::cstring, 0, 4096) as v
    FROM vector_in_benchmark
    WHERE id > 16000 AND id <= 16100
) t;

\timing off

-- Benchmark 2: Bulk INSERT performance
-- This tests vector_in in a real-world scenario

-- Create a table for bulk insert testing
CREATE TABLE IF NOT EXISTS bulk_insert_test (
    id SERIAL PRIMARY KEY,
    v vector(1536)
);

\timing on

-- Bulk insert with vector_in
INSERT INTO bulk_insert_test (v)
SELECT vector_in(vector_str::cstring, 0, 1536)
FROM vector_in_benchmark
WHERE id > 15000 AND id <= 16000;

\timing off

-- Benchmark 3: String parsing performance variations
-- Test different string formats and edge cases

-- Test with extra whitespace
\timing on
SELECT COUNT(*) FROM (
    SELECT vector_in(' [ 1.0 , 2.0 , 3.0 ] '::cstring, 0, 3) as v
    FROM generate_series(1, 10000) t
) t;
\timing off

-- Test with scientific notation
\timing on
SELECT COUNT(*) FROM (
    SELECT vector_in('[1.0e-10, 2.0e+10, 3.0e0]'::cstring, 0, 3) as v
    FROM generate_series(1, 10000) t
) t;
\timing off

-- Test with negative numbers
\timing on
SELECT COUNT(*) FROM (
    SELECT vector_in('[-1.0, -2.0, -3.0]'::cstring, 0, 3) as v
    FROM generate_series(1, 10000) t
) t;
\timing off

-- Benchmark 4: Concurrent performance
-- Test multiple concurrent vector_in operations

-- Create a function to simulate concurrent load
CREATE OR REPLACE FUNCTION concurrent_vector_in_test()
RETURNS void AS $$
DECLARE
    i INTEGER;
    v vector(5);
BEGIN
    FOR i IN 1..10000 LOOP
        v := vector_in('[1.0, 2.0, 3.0, 4.0, 5.0]'::cstring, 0, 5);
    END LOOP;
END;
$$ LANGUAGE plpgsql;

\timing on

-- Run concurrent test
SELECT concurrent_vector_in_test();

\timing off

-- Benchmark 5: Memory usage and garbage collection
-- Monitor memory usage during vector parsing

-- Check memory usage before
SELECT pg_size_pretty(pg_relation_size('vector_in_benchmark')) as table_size;

-- Force garbage collection and check memory
VACUUM ANALYZE vector_in_benchmark;

-- Benchmark 6: Error handling performance
-- Test performance with invalid inputs

\timing on

-- Test with invalid syntax (should be fast due to early error detection)
DO $$
DECLARE
    i INTEGER;
BEGIN
    FOR i IN 1..10000 LOOP
        BEGIN
            PERFORM vector_in('invalid'::cstring, 0, 3);
        EXCEPTION
            WHEN OTHERS THEN
                -- Expected error, continue
                NULL;
        END;
    END LOOP;
END $$;

\timing off

-- Benchmark 7: Comparison with array_to_vector
-- Compare vector_in performance with array_to_vector

\timing on

-- Test vector_in
SELECT COUNT(*) FROM (
    SELECT vector_in('[1.0, 2.0, 3.0]'::cstring, 0, 3) as v
    FROM generate_series(1, 10000) t
) t;

-- Test array_to_vector
SELECT COUNT(*) FROM (
    SELECT ARRAY[1.0, 2.0, 3.0]::vector as v
    FROM generate_series(1, 10000) t
) t;

\timing off

-- Cleanup
DROP TABLE IF EXISTS vector_in_benchmark;
DROP TABLE IF EXISTS bulk_insert_test;
DROP FUNCTION IF EXISTS concurrent_vector_in_test();

-- Performance Analysis Queries
-- Run these to analyze the performance impact:

-- 1. Check if vector_in is the bottleneck:
-- Look for high CPU usage during string parsing
-- Monitor memory allocation patterns

-- 2. Compare before/after performance:
-- Run this script before and after any optimizations
-- Compare the timing results for different vector sizes

-- 3. System-level monitoring:
-- Use tools like perf, vtune, or similar to measure:
-- - String parsing overhead
-- - Memory allocation patterns
-- - CPU utilization during parsing

-- Expected performance characteristics:
-- - Small vectors (128 dims): Very fast, mostly CPU-bound
-- - Medium vectors (512 dims): Moderate overhead, memory allocation becomes noticeable
-- - Large vectors (1536 dims): Significant parsing overhead, memory allocation impact
-- - Very large vectors (4096 dims): Heavy parsing overhead, memory bandwidth limited

-- Optimization opportunities:
-- - SIMD parsing for multiple float values
-- - Memory pool allocation for vector structures
-- - String parsing optimizations
-- - Batch processing for multiple vectors
