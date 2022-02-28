#Dockerfile vars
alpver=1.21.6-alpine

#blue-green
NEW_VERSION=v0.1.0
SERVICE_NAME=nginx-lokalise
DEPLOYMENT_NAME=nginx-lokalise
HEALTH_COMMAND=null
HEALTH_SECONDS=5
NAMESPACE=lokalise
URL=localhost

#vars
IMAGENAME=nginx-lokalise
IMAGEFULLNAME=${IMAGENAME}:${NEW_VERSION}

.PHONY: build bluegreen

build:
	    @docker build --pull --build-arg ALP_VER=${alpver} -t ${IMAGEFULLNAME} .
	    kind load docker-image nginx-lokalise:${NEW_VERSION}

bluegreen:
	    @./k8s-blue-green-rollout.sh ${SERVICE_NAME} ${DEPLOYMENT_NAME} ${NEW_VERSION} ${HEALTH_COMMAND} ${HEALTH_SECONDS} ${NAMESPACE} ${URL}
