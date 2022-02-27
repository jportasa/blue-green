#!/bin/bash

benchmark(){
    echo "[DEPLOY TEST] Benchmark test to green environment (TODO check results and stop deployment if http failures)"
    rm -rf output.txt
    wrk -t10 -c40 -d10s http://127.0.0.1:30951/index.html
    # TODO process output values and compare with limits
}

cancel(){
    echo "[DEPLOY FAILED] Removing new color"
    kubectl delete deployment $DEPLOYMENT_NAME-$NEW_VERSION --namespace=${NAMESPACE}
    exit 1
}

mainloop(){

    echo "[DEPLOY INFO] Locating current version"
    CURRENT_VERSION=$(kubectl get service ${SERVICE_NAME}-blue -o=jsonpath='{.spec.selector.version}' --namespace=${NAMESPACE})

    if [ "$CURRENT_VERSION" == "$NEW_VERSION" ]; then
       echo "[DEPLOY NOP] NEW_VERSION is same as CURRENT_VERSION. Both are at $CURRENT_VERSION. Change NEW_VERSION var in makefile"
       exit 0
    fi

    echo "[DEPLOY NEW COLOR] Creating next version with service so that we can do tests"
    kubectl get deployment $DEPLOYMENT_NAME-$CURRENT_VERSION -o=yaml --namespace=${NAMESPACE} | sed -e "s/$CURRENT_VERSION/$NEW_VERSION/g" | kubectl apply --namespace=${NAMESPACE} -f -
    kubectl get service ${SERVICE_NAME}-green -o=yaml --namespace=${NAMESPACE} | sed -e "s/$CURRENT_VERSION/$NEW_VERSION/g" | kubectl apply --namespace=${NAMESPACE} -f -

    echo "[DEPLOY INFO] Waiting for new color to come up"
    kubectl rollout status deployment/$DEPLOYMENT_NAME-$NEW_VERSION --namespace=${NAMESPACE}

    benchmark

    echo "[DEPLOY SWITCH] Routing traffic to new color"
    kubectl get service $SERVICE_NAME-blue -o=yaml --namespace=${NAMESPACE} | sed -e "s/$CURRENT_VERSION/$NEW_VERSION/g" | kubectl apply --namespace=${NAMESPACE} -f -

    echo "[DEPLOY CLEANUP] Removing previous color (service and deployment)"
    kubectl delete deployment $DEPLOYMENT_NAME-$CURRENT_VERSION --namespace=${NAMESPACE}
    kubectl delete service ${SERVICE_NAME}-green --namespace=${NAMESPACE}
}

SERVICE_NAME=$1
DEPLOYMENT_NAME=$2
NEW_VERSION=$3
HEALTH_COMMAND=$4
HEALTH_SECONDS=$5
NAMESPACE=$6
URL=$7

mainloop