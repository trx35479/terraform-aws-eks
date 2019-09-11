# Configuring the cluster with NGINX ingress and Letsencrpyt cert-manager

```
$tree
├── cert-manager
   │   ├── 00-crds.yaml
   │   ├── app.yaml
   │   ├── cloud-generic.yaml
   │   ├── go-ingress.yaml
   │   ├── go.yaml
   │   ├── ingress.yaml
   │   ├── mandatory.yaml
   │   ├── prod-issuer.yaml
   │   ├── staging-issuer.yaml
   │   └── web.yaml
   └── nginx-ingress
       ├── apple.yaml
       ├── banana.yaml
       ├── example-ingress.yaml
       ├── mandatory.yaml
       └── nlb-service.yaml
```

- cert-manager folder contains all needed manifest to run nginx-ingress with certificate manager via Let's Encrypt

### To configure the nginx ingress without certificat management, change to nginx-ingres directory and execute all manifest

### To configure certificate manager

1. Configure tillerless helm 
    - Note: Run tiller on a dedicated cli terminal and run helm on other cli terminal

    - On tiller terminal
    ```
    $ rm -rf ~/.helm
    $ kubectl create namespace tiller # create namespace for tiller
    $ export TILLER_NAMESPACE=tiller
    $ tiller -listen=localhost:44134 -storage=secret -logtostderr
    ```

    - On Helm terminal
    ```
    $ export HELM_HOST=:44134
    $ helm init --client-only
    ```
2. Create the CRD's for cert-manager

    `$ kubectl apply -f 00-crds.yaml`

3. Add the cert-manager helm repo

    `$ helm repo add jetstack https://charts.jetstack.io`

4. Install the cert-managet package from helm repo

    `$ helm install --name cert-manager --namespace kube-system jetstack/cert-manager --version v0.8.0`
    
5. Apply the staging and prod certificate issuer manifest

    ```
    $ kubectl apply -f staging-issuer.yaml # staging certificate issuer
    $ kubectl apply -f prod-issuer.yaml # prod certificate issuer
    ```
6. Install nginx-ingress deployments and service. The svc will be the a generic loadbalancer and will listen to port defined in manifest. 
    
    ```
    $ kubectl apply -f mandatory.yaml # install the nginx-ingress deplyoments
    $ kubectl apply -f cloud-generic.yaml # install the load-balancer service
    ```
7. Install the sample app. The nginx-ingress controller has the ability to route traffic to all namespace in the cluster.

    ```
    $ kubectl create ns go-app # create a go-app namespace
    $ kubectl apply -f go.yaml # deployment of go app and corresponding service
    $ kubectl apply -f go-ingress.yaml # the ingress that will route traffic to service and pods
    ```
   ```
   # contents go-app.yaml manifest
   $cat go.yaml 
   apiVersion: v1
   kind: Service
   metadata:
     name: go-app
     namespace: go-app
   spec:
     ports:
     - port: 80
       targetPort: 8080
     selector:
       app: go-app
   ---
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: go-app
     namespace: go-app
   spec:
     selector:
       matchLabels:
         app: go-app
     replicas: 1
     template:
       metadata:
         labels:
           app: go-app
       spec:
         containers:
         - name: go-app
           image: roweluchi/http_go:latest
           ports:
           - containerPort: 8080
   
   # contents of go-ingress.yaml
   $cat go-ingress.yaml 
   apiVersion: extensions/v1beta1
   kind: Ingress
   metadata:
     name: go-ingress
     namespace: go-app
     annotations:  
       kubernetes.io/ingress.class: nginx
       certmanager.k8s.io/cluster-issuer: letsencrypt-prod # the issuer name
   spec:
     tls:
     - hosts:
       - go.thecloudnative.io
       secretName: letsencrypt-prod
     rules:
     - host: go.thecloudnative.io
       http:
         paths:
         - backend:
             serviceName: go-app
             servicePort: 80

    ```
    
- Note: Deploy first the ingress with staging issuer, once activated update the manifest for ingress to prod-issur