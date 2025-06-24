SELECT
    function_name,
    test_name,
    -- vector_size,
    -- iterations,
    -- round((min_time * 1000)::numeric, 3) as "Minimum Time (ms)",
    round((median_time * 1000)::numeric, 3) as "Median Time (ms)",
    round((p95_time * 1000)::numeric, 3) as "95th Percentile (ms)",
    round((p99_time * 1000)::numeric, 3) as "99th Percentile (ms)",
    -- round((max_time * 1000)::numeric, 3) as "Maximum Time (ms)",
    round((stddev_time * 1000)::numeric, 3) as "Standard Deviation (ms)"
FROM benchmark_results
ORDER BY function_name, vector_size, test_name;
