#!/bin/bash

set -e

benchmark(){
    echo "[DEPLOY TEST] Benchmark test to green environment (TODO check results and stop deployment if http failures)"
    rm -rf output.txt
    wrk -t10 -c40 -d10s http://127.0.0.1:30951/index.html | tee output.txt
    # Parsing the output of wrk
    errors_connect=$(cat output.txt| grep errors | awk '{print $4}' | sed 's/,//')
    errors_read=$(cat output.txt| grep errors | awk '{print $6}' | sed 's/,//')
    errors_write=$(cat output.txt| grep errors | awk '{print $8}' | sed 's/,//')
    errors_timeout=$(cat output.txt| grep errors | awk '{print $10}' | sed 's/,//')

    cat << EOF
[DEPLOY TEST RESULT] $WRK Socket errors results:
...$(tput setaf 1)errors_connect=$(tput setab 7)$errors_connect$(tput sgr 0)
...$(tput setaf 1)errors_read=$(tput setab 7)$errors_read$(tput sgr 0)
...$(tput setaf 1)errors_write=$(tput setab 7)$errors_write$(tput sgr 0)
...$(tput setaf 1)errors_timeout=$(tput setab 7)$errors_timeout$(tput sgr 0)

$(tput setaf 3)TODO: Adding a stop if errors in the wrk output is adding an "if", I haven't done to not confuse when you run it.$(tput sgr 0)
EOF
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
}

SERVICE_NAME=$1
DEPLOYMENT_NAME=$2
NEW_VERSION=$3
HEALTH_COMMAND=$4
HEALTH_SECONDS=$5
NAMESPACE=$6
URL=$7

mainloop