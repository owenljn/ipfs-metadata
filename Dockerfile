# Setup go
FROM golang:1.23 AS builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o /ipfs-metadata .

# Build the app image
FROM alpine:3.17

RUN adduser -D appuser
WORKDIR /home/appuser

COPY --from=builder /ipfs-metadata /usr/local/bin/ipfs-metadata

# Copy the .env file into the same working directory
COPY --from=builder /app/.env ./.env

# Copy the data folder so the CSV is accessible
COPY --from=builder /app/data ./data

USER appuser
EXPOSE 8080

ENTRYPOINT ["ipfs-metadata"]
