run:
	./scripts/run_all.sh

down:
	docker compose down

reset:
	docker compose down -v