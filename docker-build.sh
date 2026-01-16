#!/bin/bash

echo "🐳 Docker Build & Test Script for Call Me App"
echo "=============================================="
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
IMAGE_NAME="call-me-app"
TAG="v0.1"
CONTAINER_NAME="call-me-test"
PORT=3000

echo -e "${BLUE}Step 1: Building Docker image with buildx...${NC}"
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t ${IMAGE_NAME}:${TAG} \
  -t ${IMAGE_NAME}:latest \
  --load \
  .

if [ $? -ne 0 ]; then
  echo -e "${RED}✗ Build failed!${NC}"
  exit 1
fi

echo -e "${GREEN}✓ Build successful!${NC}"
echo ""

echo -e "${BLUE}Step 2: Stopping any existing containers...${NC}"
docker stop ${CONTAINER_NAME} 2>/dev/null || true
docker rm ${CONTAINER_NAME} 2>/dev/null || true

echo -e "${GREEN}✓ Cleanup complete${NC}"
echo ""

echo -e "${BLUE}Step 3: Running container for testing...${NC}"
docker run -d \
  --name ${CONTAINER_NAME} \
  -p ${PORT}:3000 \
  -e NODE_ENV=production \
  ${IMAGE_NAME}:${TAG}

if [ $? -ne 0 ]; then
  echo -e "${RED}✗ Failed to start container!${NC}"
  exit 1
fi

echo -e "${GREEN}✓ Container started${NC}"
echo ""

echo -e "${BLUE}Step 4: Waiting for app to be ready...${NC}"
sleep 3

echo -e "${BLUE}Step 5: Testing the app...${NC}"
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:${PORT})

if [ "$HTTP_STATUS" == "200" ]; then
  echo -e "${GREEN}✓ App is responding (HTTP $HTTP_STATUS)${NC}"
else
  echo -e "${RED}✗ App test failed (HTTP $HTTP_STATUS)${NC}"
  docker logs ${CONTAINER_NAME}
  exit 1
fi

echo ""
echo -e "${GREEN}=============================================="
echo "✓ Docker build & test successful!"
echo "=============================================="${NC}
echo ""
echo "Container Info:"
echo "  Name:    ${CONTAINER_NAME}"
echo "  Image:   ${IMAGE_NAME}:${TAG}"
echo "  Port:    http://localhost:${PORT}"
echo ""
echo "Useful commands:"
echo "  View logs:    docker logs ${CONTAINER_NAME}"
echo "  Stop:         docker stop ${CONTAINER_NAME}"
echo "  Remove:       docker rm ${CONTAINER_NAME}"
echo "  Shell:        docker exec -it ${CONTAINER_NAME} sh"
echo ""
echo "🎉 Open http://localhost:${PORT} in your browser!"
