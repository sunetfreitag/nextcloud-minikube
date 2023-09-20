#!/bin/bash
minikube stop 
minikube delete
minikube config set driver docker
minikube start --kubernetes-version=v1.26.1 --memory=5g
minikube addons enable ingress
kubectl create ns nextcloud
