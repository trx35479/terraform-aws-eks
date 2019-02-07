# Deploying AWS EKS

- Configure aws access key using aws-sdk 

- Depoy the Terraform module and wait until the deployment has been completed, code will generate a certificate and place it .kube/config for the user to be able access the kuberntes cluster. Try the below command if the workstatiob can authenticate to eks cluster
  - kubectl get all

- After the terraform has finish the deployment, execute below to finish the deployment.
  
  - kubectl apply -f config_map_aws_auth.yaml
