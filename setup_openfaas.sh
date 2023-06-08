#!/bin/bash

set -ex

echo "#################################"
echo "Installing OpenFaas"
kubectl apply -f https://raw.githubusercontent.com/openfaas/faas-netes/master/namespaces.yml
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
helm repo add openfaas https://openfaas.github.io/faas-netes/
helm upgrade openfaas --install openfaas/openfaas     --namespace openfaas      --set functionNamespace=openfaas-fn     --set generateBasicAuth=true     --set openfaasPRO=false     --set faasnetes.httpProbe=false     --set faasnetes.livenessProbe.timeoutSeconds=5 --set faasnetes.livenessProbe.periodSeconds=70      --set faasnetes.readinessProbe.periodSeconds=70
curl -sSL https://cli.openfaas.com | sudo -E sh
wget -O crd.yaml https://raw.githubusercontent.com/openfaas/faas-netes/master/artifacts/crds/openfaas.com_profiles.yaml
echo "Experimental try profile with openfaas-fn as well"
cat <<EOF | kubectl apply -f -
          kind: Profile
          apiVersion: openfaas.com/v1
          metadata:
            name: test
            namespace: openfaas
          spec:
            # Configuration values can be set as key-value properties
              runtimeClassName: gvisor
EOF

curl -sSL https://cli.openfaas.com | sudo -E sh
#faas-cli login --password $(kubectl -n openfaas get secret basic-auth -o jsonpath="{.data.basic-auth-password}" | base64 --decode) --gateway $HOSTNAME:31112

helm uninstall -n openfaas openfaas
git clone https://github.com/deepaksirone/faas-netes.git
pushd ./faas-netes
git checkout gvisor
kubectl apply -f ./yaml_runc
popd

sleep 20

faas-cli login --password $(kubectl -n openfaas get secret basic-auth -o jsonpath="{.data.basic-auth-password}" | base64 --decode) --gateway $HOSTNAME:31112
echo "#### Now copy gVisor and seclambda to /usr/local/bin on all nodes and move the default docker image store ####"

