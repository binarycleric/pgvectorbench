CREATE OR REPLACE FUNCTION generate_vector_string(dimensions integer)
RETURNS text AS $$
BEGIN
    RETURN '[' || string_agg(random()::text, ',') || ']'
    FROM generate_series(1, dimensions);
END;
$$ LANGUAGE plpgsql;

-- Function to generate vector strings with various whitespace patterns
CREATE OR REPLACE FUNCTION generate_vector_string_with_whitespace(dimensions integer, whitespace_pattern text)
RETURNS text AS $$
DECLARE
    result text;
    i integer;
    val text;
BEGIN
    result := '[';

    FOR i IN 1..dimensions LOOP
        val := random()::text;
        IF i = 1 THEN
            result := result || whitespace_pattern || val;
        ELSE
            result := result || whitespace_pattern || ',' || whitespace_pattern || val;
        END IF;
    END LOOP;

    result := result || whitespace_pattern || ']';
    RETURN result;
END;
$$ LANGUAGE plpgsql;

CREATE TEMP TABLE temp_vectors_128 AS
SELECT generate_vector_string(128) as vec_str;

CREATE TEMP TABLE temp_vectors_1024 AS
SELECT generate_vector_string(1024) as vec_str;

CREATE TEMP TABLE temp_vectors_10240 AS
SELECT generate_vector_string(10240) as vec_str;

-- Pre-generate vectors with different whitespace patterns
CREATE TEMP TABLE temp_whitespace_vectors AS
SELECT
    generate_vector_string_with_whitespace(128, '') as vec_str_minimal,
    generate_vector_string_with_whitespace(128, ' ') as vec_str_single_space,
    generate_vector_string_with_whitespace(128, '  ') as vec_str_double_space,
    generate_vector_string_with_whitespace(128, '   ') as vec_str_triple_space,
    generate_vector_string_with_whitespace(128, '    ') as vec_str_tab_like,
    generate_vector_string_with_whitespace(128, E'\t') as vec_str_tab,
    generate_vector_string_with_whitespace(128, E'\n') as vec_str_newline,
    generate_vector_string_with_whitespace(128, E'\r\n') as vec_str_crlf,
    generate_vector_string_with_whitespace(128, ' \t\n\r') as vec_str_mixed;

-- Whitespace parsing benchmarks
SELECT run_benchmark(
    'whitespace_minimal',
    'vector_in_whitespace',
    128,
    10000,
    $$
    SELECT vector_in((SELECT vec_str_minimal FROM temp_whitespace_vectors LIMIT 1)::cstring, 0, 128) as v
    $$
);

SELECT run_benchmark(
    'whitespace_single_space',
    'vector_in_whitespace',
    128,
    10000,
    $$
    SELECT vector_in((SELECT vec_str_single_space FROM temp_whitespace_vectors LIMIT 1)::cstring, 0, 128) as v
    $$
);

SELECT run_benchmark(
    'whitespace_double_space',
    'vector_in_whitespace',
    128,
    10000,
    $$
    SELECT vector_in((SELECT vec_str_double_space FROM temp_whitespace_vectors LIMIT 1)::cstring, 0, 128) as v
    $$
);

SELECT run_benchmark(
    'whitespace_triple_space',
    'vector_in_whitespace',
    128,
    10000,
    $$
    SELECT vector_in((SELECT vec_str_triple_space FROM temp_whitespace_vectors LIMIT 1)::cstring, 0, 128) as v
    $$
);

SELECT run_benchmark(
    'whitespace_tab_like',
    'vector_in_whitespace',
    128,
    10000,
    $$
    SELECT vector_in((SELECT vec_str_tab_like FROM temp_whitespace_vectors LIMIT 1)::cstring, 0, 128) as v
    $$
);

SELECT run_benchmark(
    'whitespace_tab',
    'vector_in_whitespace',
    128,
    10000,
    $$
    SELECT vector_in((SELECT vec_str_tab FROM temp_whitespace_vectors LIMIT 1)::cstring, 0, 128) as v
    $$
);

SELECT run_benchmark(
    'whitespace_newline',
    'vector_in_whitespace',
    128,
    10000,
    $$
    SELECT vector_in((SELECT vec_str_newline FROM temp_whitespace_vectors LIMIT 1)::cstring, 0, 128) as v
    $$
);

SELECT run_benchmark(
    'whitespace_crlf',
    'vector_in_whitespace',
    128,
    10000,
    $$
    SELECT vector_in((SELECT vec_str_crlf FROM temp_whitespace_vectors LIMIT 1)::cstring, 0, 128) as v
    $$
);

--SELECT run_benchmark(
--    'whitespace_mixed',
--    'vector_in_whitespace',
--    128,
--    10000,
--    $$
--    SELECT vector_in((SELECT vec_str_mixed FROM temp_whitespace_vectors LIMIT 1)::cstring, 0, 128) as v
--    $$
--);

-- Test with larger vectors and whitespace
CREATE TEMP TABLE temp_whitespace_vectors_large AS
SELECT
    generate_vector_string_with_whitespace(1024, '') as vec_str_minimal,
    generate_vector_string_with_whitespace(1024, ' ') as vec_str_single_space,
    generate_vector_string_with_whitespace(1024, '  ') as vec_str_double_space,
    generate_vector_string_with_whitespace(1024, ' \t\n\r') as vec_str_mixed;

SELECT run_benchmark(
    'whitespace_large_minimal',
    'vector_in_whitespace_large',
    1024,
    1000,
    $$
    SELECT vector_in((SELECT vec_str_minimal FROM temp_whitespace_vectors_large LIMIT 1)::cstring, 0, 1024) as v
    $$
);

--SELECT run_benchmark(
--    'whitespace_large_mixed',
--    'vector_in_whitespace_large',
--    1024,
--    1000,
--    $$
--    SELECT vector_in((SELECT vec_str_mixed FROM temp_whitespace_vectors_large LIMIT 1)::cstring, 0, 1024) as v
--    $$
--);

-- Test extreme whitespace patterns
SELECT run_benchmark(
    'whitespace_extreme',
    'vector_in_whitespace_extreme',
    128,
    1000,
    $$
    SELECT vector_in('     [     1.0     ,     2.0     ,     3.0     ]     '::cstring, 0, 3) as v
    $$
);

-- Test whitespace with scientific notation
SELECT run_benchmark(
    'whitespace_scientific',
    'vector_in_whitespace_scientific',
    128,
    1000,
    $$
    SELECT vector_in(' [ 1.0e-10 , 2.0e+10 , 3.0e0 ] '::cstring, 0, 3) as v
    $$
);

DROP FUNCTION generate_vector_string;
DROP FUNCTION generate_vector_string_with_whitespace;