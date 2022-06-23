#!/bin/sh

set -o errexit

MONITORING_TMP=${TEMP_DIR}/monitoring
mkdir -p $MONITORING_TMP

function enable_monitoring() {
  kubectl create namespace dapr-monitoring
  kubectl create namespace dapr-system
  helm repo add --force-update elastic https://helm.elastic.co
  helm repo update
  helm install elasticsearch elastic/elasticsearch -n dapr-monitoring --set replicas=1
  
  echo "Waiting for elasticsearch start-up..."
  # One replica, so only wait for index 0
  kubectl wait --namespace=dapr-monitoring --for=condition=ready pod --timeout=600s -l statefulset.kubernetes.io/pod-name=elasticsearch-master-0

  # TODO: Load metricbeat and filebeat via helm chart.

  helm install kibana elastic/kibana -n dapr-monitoring

  echo "Waiting for kibana start-up..."
  kubectl wait --for=condition=Ready pods -l=app=kibana -n dapr-monitoring --timeout=600s

  source_url=https://docs.dapr.io/docs

  configMap=fluentd-config-map.yaml
  configMapPath=${MONITORING_TMP}/${configMap}
  wget ${source_url}/${configMap} -O ${configMapPath}
  kubectl apply -f ${configMapPath}

  daprFile=fluentd-dapr-with-rbac.yaml
  daprFilePath=${MONITORING_TMP}/${daprFile}
  wget ${source_url}/${daprFile} -O ${daprFilePath}
  kubectl apply -f ${daprFilePath}

  kubectl wait --for=condition=Ready pods -l=k8s-app=fluentd-logging -n kube-system --timeout=600s

  helm repo add --force-update dapr https://dapr.github.io/helm-charts/
  helm repo update
  helm install dapr dapr/dapr --namespace dapr-system --set global.logAsJson=true

  echo "Waiting for dapr-system start-up..."
  kubectl wait --for=condition=Ready pods -l=app=dapr-dashboard -n dapr-system --timeout=120s
  kubectl wait --for=condition=Ready pods -l=app=dapr-operator -n dapr-system --timeout=120s
  kubectl wait --for=condition=Ready pods -l=app=dapr-placement-server -n dapr-system --timeout=120s
  kubectl wait --for=condition=Ready pods -l=app=dapr-sentry -n dapr-system --timeout=120s
  kubectl wait --for=condition=Ready pods -l=app=dapr-sidecar-injector -n dapr-system --timeout=120s

  nohup kubectl port-forward svc/kibana-kibana 5601 -n dapr-monitoring > ${MONITORING_TMP}/port-forward.log 2>&1 &
}
