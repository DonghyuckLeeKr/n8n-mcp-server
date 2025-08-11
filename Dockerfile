# Stage 1: Build
FROM node:20 AS builder
WORKDIR /app

COPY package*.json ./
RUN npm ci --ignore-scripts

COPY . .
RUN npm run build

RUN npm prune --omit=dev

# Stage 2: Runtime
FROM node:20-slim
WORKDIR /app

# 빌드 산출물/모듈/메타
COPY --from=builder /app/build ./build
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package*.json ./

# (선택) 포트 표기 — 실제 리스닝은 PORT로
EXPOSE 8000

# supergateway 설치
RUN npm i -g supergateway

# 디버그 겸 버전 출력 후, stdio→SSE 변환 게이트웨이 띄우기
ENTRYPOINT ["sh","-lc","supergateway --version && supergateway --stdio \"node build/index.js\" --outputTransport sse --port ${PORT} --ssePath /sse --messagePath /message --verbose"]
