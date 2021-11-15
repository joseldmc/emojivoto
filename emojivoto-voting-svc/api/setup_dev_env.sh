#!/bin/bash

CONTAINER_ID=''

AMBASSADOR_API_KEY=''

run_dev_container() {
    echo 'Running dev container (and downloading if necessary)'

    # check if dev container is already running and kill if so
    CONTAINER_ID=$(docker inspect --format="{{.Id}}" "/voting-demo")
    if [ ! -z "$CONTAINER_ID" ]
    then
        docker kill $CONTAINER_ID
    fi

    # run the dev container, exposing 8081 gRPC port and volume mounding code directory
    CONTAINER_ID=$(docker run -d -p8083:8083 -p8081:8081 --name voting-demo --cap-add=NET_ADMIN --device /dev/net/tun:/dev/net/tun --pull always --rm -it -e AMBASSADOR_API_KEY=$AMBASSADOR_API_KEY  -v ~/Library/Application\ Support:/root/.host_config -v $(pwd):/opt/emojivoto/emojivoto-voting-svc/api datawire/telepresence-emojivoto-go-demo)
    
    # wait for container init
    sleep 10s
}

connect_to_k8s() {
    echo 'Extracting KUBECONFIG from container and connecting to cluster'
    docker cp $CONTAINER_ID:/opt/telepresence-demo-cluster.yaml ./temp.yaml
    export KUBECONFIG=./temp.yaml

    echo 'Connected to cluster. Listing services in default namespace'
    kubectl get svc
}

install_telepresence() {
    echo 'Configuring Telepresence'
    if [ ! command -v telepresence &> /dev/null ]
    then
        echo "Installing Telepresence"
        sudo curl -fL https://app.getambassador.io/download/tel2/darwin/amd64/latest/telepresence -o /usr/local/bin/telepresence
        sudo chmod a+x /usr/local/bin/telepresence
    else
        echo "Telepresence already installed"
    fi    
}

connect_local_dev_env_to_remote() {
    echo 'Connecting local dev env to remote K8s cluster'
    telepresence intercept voting --port 8081:8080
}

open_editor() {
    echo 'Opening editor'
    code .
}

run_dev_container
connect_to_k8s
install_telepresence
connect_local_dev_env_to_remote
open_editor



