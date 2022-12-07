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
  
  # TODO: Use helm values override in command instead of overwriting the file's contents.

  # Download helm chart, replace image prefix with proxy variables, install.
  # This allows the use of proxies without affecting the image name and tag.
  # helm pull elastic/elasticsearch --untar --untardir $MONITORING_TMP
  # sed -i "s|docker.elastic.co/|$DOCKER_REGISTRY_PROXY$REGISTRY_ELASTIC_DOCKER|g" $MONITORING_TMP/elasticsearch/values.yaml
  # helm install elasticsearch $MONITORING_TMP/elasticsearch -n dapr-monitoring --set replicas=1
  
  #syslog "elasticsearch DISABLED!"
  helm install elasticsearch elastic/elasticsearch --version 7.17.3 -n dapr-monitoring --set replicas=1
  
  #syslog "Waiting for elasticsearch start-up..."
  # One replica, so only wait for index 0
  kubectl wait --namespace=dapr-monitoring --for=condition=ready pod --timeout=3600s -l statefulset.kubernetes.io/pod-name=elasticsearch-master-0

  #helm pull elastic/kibana --untar --untardir $MONITORING_TMP
  # Received "expected HTTP 206 from byte range request" when pulling from corporate proxy registry; pulling direct from elastic.
  #sed -i "s|docker.elastic.co/|$DOCKER_REGISTRY_PROXY$REGISTRY_ELASTIC_DOCKER|g" $MONITORING_TMP/kibana/values.yaml
  #helm install kibana $MONITORING_TMP/kibana -n dapr-monitoring
  #helm install kibana elastic/kibana -n dapr-monitoring

  # FIX: Kibana refuses to start... need to investigate this manually.
  helm install kibana elastic/kibana --version 7.17.3 -n dapr-monitoring

  #syslog "kibana DISABLED!"
  #syslog "Waiting for kibana start-up..."
  kubectl wait --for=condition=Ready pods -l=app=kibana -n dapr-monitoring --timeout=3600s

  # Load metricbeat via helm chart.
  #syslog "metricbeat DISABLED!"
  syslog "Waiting for metricbeat start-up..."
  #helm pull elastic/metricbeat --untar --untardir $MONITORING_TMP
  #sed -i "s|docker.elastic.co/|$DOCKER_REGISTRY_PROXY$REGISTRY_ELASTIC_DOCKER|g" $MONITORING_TMP/metricbeat/values.yaml
  #helm install metricbeat $MONITORING_TMP/metricbeat --version 7.17.3 -n dapr-monitoring --wait
  helm install metricbeat elastic/metricbeat --version 7.17.3 -n dapr-monitoring --wait

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
