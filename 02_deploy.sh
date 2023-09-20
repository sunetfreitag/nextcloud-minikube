#!/bin/bash
bash build-all-dependencies-with-helm.sh
helm upgrade -n nextcloud nxkube ./charts/all/ -i --values values.yaml
