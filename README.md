# Blue-green design overview

1. We have one k8s service-blue that has as selector pointing to deployment-blue (app v0.1.0).
2. We spawn service-green and deployment-green (app v0.2.0) and check that all PODS work with Liveness k8s property.
3. Benchmark with wrk starts against the service-green that points to Deployment-green.
4. Next we switch the service-blue to point to selector of Deployment-green.
5. Delete deployment-blue and service-green.

# Bootstrap
## Requirements in your local

docker, kubectl, kind (https://kind.sigs.k8s.io/), wrk, make.

## Create local k8s cluster
Create a local k8s cluster over Docker.

````
kind create cluster --config=kind-cluster/config.yaml
````
## Deploy 1st web app version
Create webserver docker image with the app code that is in /src, we will call it v0.1.0:
```
make build
```
Spawn blue k8s deployment
```
kubectl create namespace lokalise
kubectl apply -f ./manifests -n lokalise
```
Check PODS are running
```
kubectl get pods -n lokalise
```
From your browser try:

http://localhost:30950/

## Blue green deploy

Change contents of src/index.html

Change makefile var: NEW_VERSION=v0.2.0

Build new image: 
```
make build
```
Run deploy:
```
make bluegreen
```
From your browser try:

http://localhost:30950/

## Test green deployment before get traffic
I am doing two tests before switching green to blue:

1. The deployment manifest has a livenessProbe to check each nginx can serve traffic.
2. wrk benchmark in script k8s-blue-green-rollout.sh
```
wrk -t10 -c40 -d10s http://127.0.0.1:30951/index.html
```
