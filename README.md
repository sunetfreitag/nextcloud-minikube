# Setting up a Nextcloud with minikube

The aim of this documentation is to show how to deploy a Nextcloud instance in a
minikube environment, and how to use it for development.

## Basic setup

We will be working on a dedicated directory, e.g. `~/nextcloud-minikube/`. All the commands
will be assumed to be executed there (unless stated otherwise) and all needed
files will be assumed to be placed there.

## Setting up the bare minikube environment

This has been tested in Ubuntu 22.04 and archlinux 2023-03-01 VMs.

Prerequisites of software:

 * kubectl (tested with version 1.26.1 (server) and 1.28.2 (client))
 * Minikube (tested with version 1.31.2)
 * Docker (tested with version 24.0.5)
 * helm (tested with version 3.12.0)

We need the Docker daemon running.

First we start from a clean state:

    $ minikube stop && minikube delete

Then we set docker as the minikube driver, and start the minikube env:

    $ minikube config set driver docker
    $ minikube start --kubernetes-version=v1.26.1 --memory=5g

Then we enable ingress and create a namespace named `nextcloud`. If you want to
change the name, you have to reflect the changes in the `values.yaml` for helm,
described below.

    $ minikube addons enable ingress
    $ kubectl create ns nextcloud

## Setting up the Nextcloud instance

We check out the code for the Helm charts.

    $ git clone git@github.com:sunetfreitag/nextcloud-minikube

The root folder contains a file `values.yaml`, and we might want to adapt some of the values:

`nextcloud.localdomain.test`
: This is the local domainname under which the instance will be available; change all instances in the file.

`nextcloud.nextcloud.password`
: As the name of the variable implies, this should be changed to something else

We can leave the rest of the values as provided.

At this point we can check the minikube IP:

    $ minikube ip
    192.168.49.2

Once we are happy with the `values.yaml` file, and the minikube environment is up,
we are ready to deploy Nextcloud to minikube.

We use the provided script `build-all-dependencies-with-helm.sh`:

    $ bash build-all-dependencies-with-helm.sh

If this complains about missing Helm repos you may need to add them, e.g. if the nextcloud or owncloud repos are missing:

    $ helm repo add nextcloud https://nextcloud.github.io/helm/

And finally we  deploy the Nextcloud to the newly created environment.

    $ helm upgrade -n nextcloud nxkube ./charts/all/ -i --values values.yaml

After a while (a few minutes), the following pods should be up and running:

    $ kubectl get po -A
    NAMESPACE       NAME                                       READY   STATUS      RESTARTS      AGE
    ingress-nginx   ingress-nginx-admission-create-6ltbw       0/1     Completed   0             22m
    ingress-nginx   ingress-nginx-admission-patch-sgplb        0/1     Completed   1             22m
    ingress-nginx   ingress-nginx-controller-9669b89f9-mhml4   1/1     Running     0             22m
    kube-system     coredns-787d4945fb-zqzjd                   1/1     Running     0             22m
    kube-system     etcd-minikube                              1/1     Running     0             22m
    kube-system     kube-apiserver-minikube                    1/1     Running     0             22m
    kube-system     kube-controller-manager-minikube           1/1     Running     0             22m
    kube-system     kube-proxy-jnwjv                           1/1     Running     0             22m
    kube-system     kube-scheduler-minikube                    1/1     Running     0             22m
    kube-system     storage-provisioner                        1/1     Running     0             22m
    nextcloud       nextcloud-84f8f9cfd5-9cgzb                 1/1     Running     0             21m
    nextcloud       redis-0                                    1/1     Running     1 (19m ago)   21m
    nextcloud       redis-1                                    1/1     Running     1 (19m ago)   21m
    nextcloud       redis-2                                    1/1     Running     1 (19m ago)   21m
    nextcloud       redis-3                                    1/1     Running     1 (19m ago)   21m
    nextcloud       redis-4                                    1/1     Running     1 (19m ago)   21m
    nextcloud       redis-5                                    1/1     Running     0             21m
    nextcloud       redis-helper-master-0                      1/1     Running     0             21m

## Setting up NextCloud

We will host the NextCloud instance under `nextcloud.localdomain.test`,
so first, in `/etc/hosts`, we point that name to minikube's IP.

    192.168.49.2 nextcloud.localdomain.test

## Check the Nextcloud pod
You can check the status of the nextcloud pod with
    kubectl -n nextcloud describe pod nextcloud-84f8f9cfd5-9cgzb

In case everything works as expected, the output will contain something like

    Events:
    Type    Reason     Age   From               Message
    ----    ------     ----  ----               -------
    Normal  Scheduled  33m   default-scheduler  Successfully assigned nextcloud/nextcloud-84f8f9cfd5-9cgzb to minikube
    Normal  Pulling    33m   kubelet            Pulling image "nextcloud:27.0.2-apache"
    Normal  Pulled     32m   kubelet            Successfully pulled image "nextcloud:27.0.2-apache" in 55.209012554s (55.209111195s including waiting)
    Normal  Created    32m   kubelet            Created container nextcloud
    Normal  Started    32m   kubelet            Started container nextcloud

## Nextcloud pod logs
The logs of a pod can be followed by
    kubectl -n nextcloud logs nextcloud-84f8f9cfd5-9cgzb -f

which will give you some traces and hints when you access Nextcloud

    192.168.49.1 - - [20/Sep/2023:22:37:32 +0000] "GET / HTTP/1.1" 302 1741 "-" "Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/117.0"
    192.168.49.1 - - [20/Sep/2023:22:37:32 +0000] "GET /login HTTP/1.1" 200 7720 "-" "Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/117.0"
    192.168.49.1 - - [20/Sep/2023:22:37:32 +0000] "GET /dist/files_sharing-main.js?v=fe808fe5-0 HTTP/1.1" 200 796 "-" "Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/117.0"
    192.168.49.1 - - [20/Sep/2023:22:37:32 +0000] "GET /apps/theming/js/theming.js?v=fe808fe5-0 HTTP/1.1" 200 536 "-" "Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/117.0"
    10.244.0.1 - - [20/Sep/2023:22:37:33 +0000] "GET /status.php HTTP/1.1" 200 1905 "-" "kube-probe/1.26"
    10.244.0.1 - - [20/Sep/2023:22:37:33 +0000] "GET /status.php HTTP/1.1" 200 1909 "-" "kube-probe/1.26"
    192.168.49.1 - - [20/Sep/2023:22:37:32 +0000] "GET /cron.php HTTP/1.1" 200 861 "-" "Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/117.0"
    10.244.0.1 - - [20/Sep/2023:22:37:43 +0000] "GET /status.php HTTP/1.1" 200 1907 "-" "kube-probe/1.26"
    10.244.0.1 - - [20/Sep/2023:22:37:43 +0000] "GET /status.php HTTP/1.1" 200 1909 "-" "kube-probe/1.26"

## Access the file system of the Nextcloud pod
The file system of the Nextcloud pod can be accessed with
    kubectl exec -ti -n nextcloud nextcloud-84f8f9cfd5-9cgzb -- bash