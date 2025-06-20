-- Small vectors (16 dimensions)
SELECT run_benchmark(
    'small_vectors_identical',
    'l2_distance',
    16,
    10000,
    $$
    SELECT l2_distance(v1, v1)
    FROM small_vectors
    LIMIT 1;
    $$
);

SELECT run_benchmark(
    'small_vectors_opposite',
    'l2_distance',
    16,
    10000,
    $$
    SELECT l2_distance(
        v1,
        reverse_vector(v1)
    )
    FROM small_vectors
    LIMIT 1;
    $$
);

SELECT run_benchmark(
    'small_vectors_orthogonal',
    'l2_distance',
    16,
    10000,
    $$
    SELECT l2_distance(
        (array_agg((CASE WHEN i % 2 = 0 THEN 0.5 ELSE -0.5 END)::float4))::vector,
        (array_agg((CASE WHEN i % 2 = 1 THEN 0.5 ELSE -0.5 END)::float4))::vector
    )
    FROM generate_series(1, 16) i
    LIMIT 1;
    $$
);

-- Medium vectors (128 dimensions)
SELECT run_benchmark(
    'medium_vectors_identical',
    'l2_distance',
    128,
    1000,
    $$
    SELECT l2_distance(
        v1,
        v1
    )
    FROM medium_vectors
    LIMIT 1;
    $$
);

SELECT run_benchmark(
    'medium_vectors_opposite',
    'l2_distance',
    128,
    1000,
    $$
    SELECT l2_distance(
        v1,
        reverse_vector(v1)
    )
    FROM medium_vectors
    LIMIT 1;
    $$
);

SELECT run_benchmark(
    'medium_vectors_orthogonal',
    'l2_distance',
    128,
    1000,
    $$
    SELECT l2_distance(
        (array_agg((CASE WHEN i % 2 = 0 THEN 0.5 ELSE -0.5 END)::float4))::vector,
        (array_agg((CASE WHEN i % 2 = 1 THEN 0.5 ELSE -0.5 END)::float4))::vector
    )
    FROM generate_series(1, 128) i
    LIMIT 1;
    $$
);

-- Large vectors (1024 dimensions)
SELECT run_benchmark(
    'large_vectors_identical',
    'l2_distance',
    1024,
    1000,
    $$
    SELECT l2_distance(
        v1,
        v1
    )
    FROM large_vectors
    LIMIT 1;
    $$
);

SELECT run_benchmark(
    'large_vectors_opposite',
    'l2_distance',
    1024,
    1000,
    $$
    SELECT l2_distance(
        v1,
        reverse_vector(v1)
    )
    FROM large_vectors
    LIMIT 1;
    $$
);

SELECT run_benchmark(
    'large_vectors_orthogonal',
    'l2_distance',
    1024,
    1000,
    $$
    SELECT l2_distance(
        (array_agg((CASE WHEN i % 2 = 0 THEN 0.5 ELSE -0.5 END)::float4))::vector,
        (array_agg((CASE WHEN i % 2 = 1 THEN 0.5 ELSE -0.5 END)::float4))::vector
    )
    FROM generate_series(1, 1024) i
    LIMIT 1;
    $$
);

-- Very large vectors (4096 dimensions)
SELECT run_benchmark(
    'very_large_vectors_identical',
    'l2_distance',
    4096,
    1000,
    $$
    SELECT l2_distance(
        v1,
        v1
    )
    FROM very_large_vectors
    LIMIT 1;
    $$
);

SELECT run_benchmark(
    'very_large_vectors_opposite',
    'l2_distance',
    4096,
    1000,
    $$
    SELECT l2_distance(
        v1,
        reverse_vector(v1)
    )
    FROM very_large_vectors
    LIMIT 1;
    $$
);

SELECT run_benchmark(
    'very_large_vectors_orthogonal',
    'l2_distance',
    4096,
    1000,
    $$
    SELECT l2_distance(
        (array_agg((CASE WHEN i % 2 = 0 THEN 0.5 ELSE -0.5 END)::float4))::vector,
        (array_agg((CASE WHEN i % 2 = 1 THEN 0.5 ELSE -0.5 END)::float4))::vector
    )
    FROM generate_series(1, 4096) i
    LIMIT 1;
    $$
);

-- Special cases
SELECT run_benchmark(
    'zero_vectors',
    'l2_distance',
    128,
    1000,
    $$
    SELECT l2_distance(
        (array_agg(0::float4))::vector,
        (array_agg(0::float4))::vector
    )
    FROM generate_series(1, 128) i
    LIMIT 1;
    $$
);

SELECT run_benchmark(
    'extreme_values',
    'l2_distance',
    128,
    1000,
    $$
    SELECT l2_distance(
        (array_agg(1e38::float4))::vector,
        (array_agg(1e38::float4))::vector
    )
    FROM generate_series(1, 128) i
    LIMIT 1;
    $$
);
