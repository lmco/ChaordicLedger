#!/bin/sh

set -o errexit

$(return >/dev/null 2>&1)
if [ "$?" -eq "0" ]
then
    syslog "Sourcing monitoring functions."
fi

MONITORING_TMP=${TEMP_DIR}/monitoring
mkdir -p $MONITORING_TMP

function enable_monitoring() {
  # Reference: https://helm.elastic.co/

  kubectl create namespace dapr-monitoring
  kubectl create namespace dapr-system
  helm repo add --force-update elastic https://helm.elastic.co
  helm repo update
  
  # Download helm chart, replace image prefix with proxy variables, install.
  # This allows the use of proxies without affecting the image name and tag.
  helm pull elastic/elasticsearch --untar --untardir $MONITORING_TMP
  sed -i "s|docker.elastic.co/|$DOCKER_REGISTRY_PROXY$REGISTRY_ELASTIC_DOCKER|g" $MONITORING_TMP/elasticsearch/values.yaml
  helm install elasticsearch $MONITORING_TMP/elasticsearch -n dapr-monitoring --set replicas=1
  #helm install elasticsearch elastic/elasticsearch -n dapr-monitoring --set replicas=1

  syslog "Waiting for elasticsearch start-up..."
  # One replica, so only wait for index 0
  kubectl wait --namespace=dapr-monitoring --for=condition=ready pod --timeout=600s -l statefulset.kubernetes.io/pod-name=elasticsearch-master-0

  helm pull elastic/kibana --untar --untardir $MONITORING_TMP
  sed -i "s|docker.elastic.co/|$DOCKER_REGISTRY_PROXY$REGISTRY_ELASTIC_DOCKER|g" $MONITORING_TMP/kibana/values.yaml
  helm install kibana $MONITORING_TMP/kibana -n dapr-monitoring
  #helm install kibana elastic/kibana -n dapr-monitoring

  syslog "Waiting for kibana start-up..."
  kubectl wait --for=condition=Ready pods -l=app=kibana -n dapr-monitoring --timeout=600s

  # Load metricbeat via helm chart.
  helm pull elastic/metricbeat --untar --untardir $MONITORING_TMP
  sed -i "s|docker.elastic.co/|$DOCKER_REGISTRY_PROXY$REGISTRY_ELASTIC_DOCKER|g" $MONITORING_TMP/metricbeat/values.yaml
  helm install metricbeat $MONITORING_TMP/metricbeat -n dapr-monitoring --wait

  # Note: filebeat appears to hit a memory limit; disabling for now as it's not really necessary.
  # Load filebeat via helm chart.
  # helm pull elastic/filebeat --untar --untardir $MONITORING_TMP
  # sed -i "s|docker.elastic.co/|$DOCKER_REGISTRY_PROXY$REGISTRY_ELASTIC_DOCKER|g" $MONITORING_TMP/filebeat/values.yaml
  # helm install filebeat $MONITORING_TMP/filebeat -n dapr-monitoring --wait

  source_url=https://docs.dapr.io/docs

  configMap=fluentd-config-map.yaml
  configMapPath=${MONITORING_TMP}/${configMap}
  wget ${source_url}/${configMap} -O ${configMapPath}
  kubectl apply -f ${configMapPath}

  # YAML source: https://docs.dapr.io/docs/fluentd-dapr-with-rbac.yaml
  local fluentdDaemonsetConfig=$MONITORING_TMP/fluentd-dapr-with-rbac.yaml
  export FLUENTD_DAEMONSET_IMAGE=${DOCKER_REGISTRY_PROXY}${REGISTRY_DOCKER_IO}fluent/fluentd-kubernetes-daemonset:v1.9.2-debian-elasticsearch7-1.0
  populateTemplate ../config/fluentd-dapr-with-rbac_template.yaml ${fluentdDaemonsetConfig}
  kubectl apply -f ${fluentdDaemonsetConfig}

  kubectl wait --for=condition=Ready pods -l=k8s-app=fluentd-logging -n kube-system --timeout=600s

  helm repo add --force-update dapr https://dapr.github.io/helm-charts/
  helm repo update

  # Nicely, there's a global variable for the registry setting
  REGISTRY=${DOCKER_REGISTRY_PROXY}${REGISTRY_DOCKER_IO}
  REGISTRY=${REGISTRY:-docker.io/}
  
  syslog "Waiting for dapr-system installation and start-up..."
  helm install dapr dapr/dapr --namespace dapr-system --set global.logAsJson=true --set global.registry="${REGISTRY}daprio" --wait

  nohup kubectl port-forward svc/kibana-kibana 5601 -n dapr-monitoring > ${MONITORING_TMP}/port-forward.log 2>&1 &
}
