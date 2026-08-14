.PHONY: up down logs seed backend-dev frontend-get api-health

up:
	docker compose up -d --build

down:
	docker compose down

logs:
	docker compose logs -f api

seed:
	cd backend && npm run seed

backend-dev:
	cd backend && npm install && npx prisma generate && npm run start:dev

frontend-get:
	cd frontend && flutter pub get

api-health:
	curl -s http://localhost:3000/health || true

# Builds (sur machine avec Flutter)
apk:
	cd frontend && flutter build apk --dart-define=API_BASE_URL=$(API_URL)

apk-release:
	cd frontend && flutter build apk --release --dart-define=API_BASE_URL=$(API_URL)

web:
	cd frontend && flutter build web --dart-define=API_BASE_URL=$(API_URL)
