SELECT run_benchmark(
    'small_vectors',
    'vector_concat',
    16,
    10000,
    $$
    SELECT v1 || v2 as concatenated
    FROM small_vectors
    LIMIT 100;
    $$
);

SELECT run_benchmark(
    'medium_vectors',
    'vector_concat',
    128,
    10000,
    $$
    SELECT v1 || v2 as concatenated
    FROM medium_vectors
    LIMIT 100;
    $$
);

SELECT run_benchmark(
    'large_vectors',
    'vector_concat',
    1024,
    10000,
    $$
    SELECT v1 || v2 as concatenated
    FROM large_vectors
    LIMIT 100;
    $$
);

SELECT run_benchmark(
    'very_large_vectors',
    'vector_concat',
    8192,
    10000,
    $$
    SELECT v1 || v2 as concatenated
    FROM very_large_vectors
    LIMIT 100;
    $$
);
