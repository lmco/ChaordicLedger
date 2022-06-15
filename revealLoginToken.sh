#/bin/sh

secretName=$(kubectl get secrets -A | grep dashboard-admin-sa-token | awk '{print $2}')
token=$(kubectl describe secret $secretName | grep "token:" | awk '{print $2;}')

echo $token
