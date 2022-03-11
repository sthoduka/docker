# Build and deploy images
# Copyright b-it-bots, Hochschule Bonn-Rhein-Sieg

DEPLOYMENT=""
CONTAINER_REGISTRY=""
PUBLISH="all"

if [ $# -eq 0 ]
then
  echo "Usage: bash build-and-deploy.sh"
  echo " "
  echo "options:"
  echo "-h, --help                    show brief help"
  echo "-c, --cuda                    cuda image tag e.g. 11.3.1-cudnn8-runtime-ubuntu20.04, default: 11.3.1-cudnn8-runtime-ubuntu20.04"
  echo "-d, --deployment              deployment (dev or prod), default: is empty or not published to registry"
  echo "-r, --registry                container registry e.g. ghcr.io for GitHub container registry, default: docker hub"
  echo "-p, --publish                 option whether to publish <all> or <latest> (default: all), all means publish all tags"
  exit 0
fi

while test $# -gt 0; do
  case "$1" in
    -h|--help)
      echo "Usage: bash build-and-deploy.sh"
      echo " "
      echo "options:"
      echo "-h, --help                show brief help"
      echo "-c, --cuda                cuda image tag e.g. 11.3.1-cudnn8-runtime-ubuntu20.04, default: 11.3.1-cudnn8-runtime-ubuntu20.04"
      echo "-d, --deployment          deployment (dev or prod), default: is empty or not published to registry"
      echo "-r, --registry            container registry e.g. ghcr.io for GitHub container registry, default: docker hub"
      echo "-p, --publish             option whether to publish <all> tags or <latest> tags only (default: all)"
      exit 0
      ;;
    -c|--cuda)
      CUDA_VERSION="$2"
      shift
      shift
      ;;
    -d|--deployment)
      DEPLOYMENT="$2"
      shift
      shift
      ;;
    -r|--registry)
      CONTAINER_REGISTRY="$2"
      shift
      shift
      ;;
    -p|--publish)
      PUBLISH="$2"
      shift
      shift
      ;;
    *)
      break
      ;;
  esac
done

if [ -z "$CUDA_VERSION" ]
then
  echo "Cuda version is not set, setting it to default 11.3.1-cudnn8-runtime-ubuntu20.04"
  CUDA_VERSION=11.3.1-cudnn8-runtime-ubuntu20.04
fi
echo "Cuda image version: $CUDA_VERSION"

echo "Image version: $VERSION"
if [ -z "$CONTAINER_REGISTRY" ]
then
  echo "Container registry is not set!. Using docker hub registry"
  CONTAINER_REG_OWNER=bitbots
else
  echo "Using $CONTAINER_REGISTRY registry"
  OWNER=b-it-bots/docker
  CONTAINER_REG_OWNER=$CONTAINER_REGISTRY/$OWNER
fi

echo "Container registry/owner = $CONTAINER_REG_OWNER"

echo "Deployment: $DEPLOYMENT"

function gpu_notebook {
  cd gpu-notebook
  GPU_NOTEBOOK_TAG=$CONTAINER_REG_OWNER/gpu-notebook:$CUDA_VERSION 

  #prepare docker file
  bash generate_dockerfile.sh

  docker build -t $GPU_NOTEBOOK_TAG --build-arg ROOT_CONTAINER=nvidia/cuda:$CUDA_VERSION .build/ 
  if docker run --gpus all -it --rm -d -p 8880:8888 $GPU_NOTEBOOK_TAG ; then echo "$GPU_NOTEBOOK_TAG is running"; else echo "Failed to run $GPU_NOTEBOOK_TAG" && exit 1; fi

  if [ "$PUBLISH" = "all" ]
  then
    echo "Pushing $GPU_NOTEBOOK_TAG"
    docker push $GPU_NOTEBOOK_TAG
  else
    echo "None is published"
  fi

}

# build docker
gpu_notebook