#/bin/sh

# Note: This may or may not reveal the token; it depends on the kubectl version you're using.
#       Repeating the create token command from initialization will regenerate the token
#       and print the token to the terminal.

secretName=$(kubectl get secrets -A | grep dashboard-admin-sa-token | awk '{print $2}')
token=$(kubectl describe secret $secretName | grep "token:" | awk '{print $2;}')

echo $token
