
# Default target
default:
    @just --list
    

# Application configuration
APP_NAME := "gcd"
BUILD_DIR := "bin"
VERSION := `git describe --tags --always --dirty 2>/dev/null || echo "dev"`
COMMIT := `git rev-parse --short HEAD 2>/dev/null || echo "unknown"`
BUILD_TIME := `date -u +"%Y-%m-%dT%H:%M:%SZ"`

# Linker flags for small, clean binaries (strips debug symbols & sets version metadata)
LDFLAGS := "-s -w -X main.version=" + VERSION + " -X main.commit=" + COMMIT + " -X main.date=" + BUILD_TIME


local-run file:
    go run main.go {{ file }}

local-build:
    go build .
local-cleantmp:
    rm -f Big_Buck_Bunny_360_10s_1MB.mp4 Big_Buck_Bunny_1080_10s_5MB.mp4 500MB-CZIPtestfile.org.zip 3dicons-png-dynamic-1.0.0.zip


local-verify select:
    {{ 
        if select == "1" 
        { 
            "md5sum ./Big_Buck_Bunny_360_10s_1MB.mp4 ./verify_file/Big_Buck_Bunny_360_10s_1MB.mp4" 
        } else { 
            "md5sum ./Big_Buck_Bunny_1080_10s_5MB.mp4 ./verify_file/Big_Buck_Bunny_1080_10s_5MB.mp4" 
        } 
    }}


build-clean:
    @rm -rf {{BUILD_DIR}}

build-all: build-clean
    @mkdir -p {{BUILD_DIR}}
    CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags "{{LDFLAGS}}" -o {{BUILD_DIR}}/{{APP_NAME}}-linux-amd64 .
    CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -ldflags "{{LDFLAGS}}" -o {{BUILD_DIR}}/{{APP_NAME}}-linux-arm64 .
    CGO_ENABLED=0 GOOS=darwin GOARCH=amd64 go build -ldflags "{{LDFLAGS}}" -o {{BUILD_DIR}}/{{APP_NAME}}-darwin-amd64 .
    CGO_ENABLED=0 GOOS=darwin GOARCH=arm64 go build -ldflags "{{LDFLAGS}}" -o {{BUILD_DIR}}/{{APP_NAME}}-darwin-arm64 .
    CGO_ENABLED=0 GOOS=windows GOARCH=amd64 go build -ldflags "{{LDFLAGS}}" -o {{BUILD_DIR}}/{{APP_NAME}}-windows-amd64.exe .

release: build-all
    @echo "==> Packaging archives..."
    @cd {{BUILD_DIR}} && \
    tar -czf {{APP_NAME}}-{{VERSION}}-linux-amd64.tar.gz {{APP_NAME}}-linux-amd64 && \
    tar -czf {{APP_NAME}}-{{VERSION}}-linux-arm64.tar.gz {{APP_NAME}}-linux-arm64 && \
    tar -czf {{APP_NAME}}-{{VERSION}}-darwin-amd64.tar.gz {{APP_NAME}}-darwin-amd64 && \
    tar -czf {{APP_NAME}}-{{VERSION}}-darwin-arm64.tar.gz {{APP_NAME}}-darwin-arm64 && \
    zip -q {{APP_NAME}}-{{VERSION}}-windows-amd64.zip {{APP_NAME}}-windows-amd64.exe
    @echo "==> Computing SHA256 checksums..."
    @cd {{BUILD_DIR}} && sha256sum *.tar.gz *.zip > checksums.txt