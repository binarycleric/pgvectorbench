BENCHMARKS = $(wildcard benchmarks/checks/*.sql)
BENCHMARK_NAMES = $(patsubst benchmarks/checks/%.sql,%,$(BENCHMARKS))

benchmark: $(BENCHMARKS)
	@echo "Running benchmarks..."
	@psql -d postgres -c "SELECT 1 FROM pg_database WHERE datname = 'pgvector_benchmark'" | grep -q 1 || psql -d postgres -c "CREATE DATABASE pgvector_benchmark"
	@psql -d pgvector_benchmark -f benchmarks/init/setup.sql > /dev/null
	@for benchmark in $(BENCHMARKS); do \
		echo "\nRunning $$(basename $$benchmark)..."; \
		psql -d pgvector_benchmark -f $$benchmark > /dev/null; \
	done
	@echo "Generating results..."
	@psql -d pgvector_benchmark -f benchmarks/init/results.sql
	@psql -d pgvector_benchmark -f benchmarks/init/teardown.sql > /dev/null

.PHONY: benchmark
