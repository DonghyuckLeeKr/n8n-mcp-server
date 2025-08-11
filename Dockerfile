# Stage 1: Build
FROM node:20 AS builder
WORKDIR /app

# 1) deps만 먼저 복사해 캐시 최적화
COPY package*.json ./
RUN npm ci --ignore-scripts

# 2) 전체 소스 복사 후 빌드
COPY . .
RUN npm run build

# 3) 런타임만 남기기
RUN npm prune --omit=dev

# Stage 2: Runtime
FROM node:20-slim
WORKDIR /app

# 빌드 산출물/모듈/메타 복사
COPY --from=builder /app/build ./build
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package*.json ./

# 실행 파일 권한
RUN chmod +x build/index.js

# (선택) 문서용 노출 포트 — 실제로는 Railway가 PORT 환경변수로 지정
EXPOSE 8000

# ⚠️ 중요: Railway의 PORT로 SSE 모드로 실행
# JSON 배열 CMD는 ${PORT} 같은 셸 확장이 안 되므로 sh -lc로 감쌉니다.
ENTRYPOINT ["sh","-lc","node build/index.js --transport sse --host 0.0.0.0 --port ${PORT} --sse-path /sse"]
