# Design overview

- We have one k8s service that has as selector pointin to deployment-A.
- We spawn deployment-B and check that all PODS work with Liveness k8s property.
- Benchmark starts against the service that points to Deployment-B
- Next we switch the service to point to selector of Deployment-B

# Bootstrap

## Create local k8s cluster
Use kind (https://kind.sigs.k8s.io/) to create a local k8s cluster over Docker.

````
kind create cluster --config=kind-cluster/config.yaml
````
## Deploy 1st web app version
Create webserver docker image with the app code that is in /src:
```
make build
```
Make the image available to kind cluster nodes
```
kind load docker-image nginx-lokalise:v0.1.0
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
Make the new image available to kind cluster nodes:
```
kind load docker-image nginx-lokalise:v0.2.0
```
Run deploy:
```
make bluegreen
```
From your browser try:

http://localhost:30950/

## Test green deployment before get traffic
I am doing two tests before switching green to blue:

The deployment manifest has a Liveness probe to check each nginx can serve traffic. We can add check_health there:
```
(...)
    livenessProbe:
      exec:
        command:
        - cat
        - /tmp/check_health
```
I am doing in "make bluegreen"  
```
wrk -t10 -c40 -d10s http://127.0.0.1:30951/index.html
```
