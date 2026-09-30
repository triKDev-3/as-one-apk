# Backend build status

**Last verified:** 2026-09-30 02:10 UTC

## Fixes applied on main

1. `sites.service.ts` — `prisma.appNotification` (not `notification`)
2. Dockerfile v4 — `npm install` only (no `npm ci` lock desync)
3. Json field cast via `Prisma.InputJsonValue`

## If Render still fails with old error

Clear build cache on Render dashboard, then **Manual Deploy → Deploy latest commit**.

The error log from `01:57` is **before** commit `9cb86e78` (02:00).
