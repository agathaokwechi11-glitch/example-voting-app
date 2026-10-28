# Example Voting App

A simple distributed application running across multiple Docker containers.

## Getting started

Download [Docker Desktop](https://www.docker.com/products/docker-desktop) for Mac or Windows. [Docker Compose](https://docs.docker.com/compose) will be automatically installed. On Linux, make sure you have the latest version of [Compose](https://docs.docker.com/compose/install/).

This solution uses Python, Node.js, .NET, with Redis for messaging and Postgres for storage.

Run in this directory to build and run the app:

```shell
docker compose up
```

The `vote` app will be running at [http://localhost:8080](http://localhost:8080), and the `results` will be at [http://localhost:8081](http://localhost:8081).

Alternately, if you want to run it on a [Docker Swarm](https://docs.docker.com/engine/swarm/), first make sure you have a swarm. If you don't, run:

```shell
docker swarm init
```

Once you have your swarm, in this directory run:

```shell
docker stack deploy --compose-file docker-stack.yml vote
```

## Run the app in Kubernetes

The folder k8s-specifications contains the YAML specifications of the Voting App's services.

Run the following command to create the deployments and services. Note it will create these resources in your current namespace (`default` if you haven't changed it.)

```shell
kubectl create -f k8s-specifications/
```

The `vote` web app is then available on port 31000 on each host of the cluster, the `result` web app is available on port 31001.

To remove them, run:

```shell
kubectl delete -f k8s-specifications/
```

## Deploy to AWS EKS with Helm

The Helm chart in `helm/voting-app` deploys the vote, result, worker, PostgreSQL,
and Redis services. Its configuration is in the chart's single `values.yaml`.
The vote and result services use AWS load balancers by default; the database
and Redis use ephemeral storage, so this sample chart is intended for learning
and demonstration, not production data.

The GitHub Actions workflow automatically runs Terraform before deployment on
each push to `main`. Terraform creates the cluster on the first run, then uses
its saved state to plan and apply any infrastructure changes on later runs.
The workflow also provisions infrastructure before the manual rollback demo.
This project uses `us-east-1` and the cluster name `voting-app-cluster`.
Terraform filters default-VPC subnets to EKS-supported Availability Zones in
this account (`us-east-1a`, `us-east-1b`, `us-east-1c`, `us-east-1d`, and
`us-east-1f`), excluding `us-east-1e`, which EKS rejected for the cluster.

The Terraform S3 backend uses the existing bucket
`voting-app-cluster-bucket` in `us-east-1`. The state key is configured in
`terraform/k8s-cluster/providers.tf` as
`terraform/k8s-cluster/terraform.tfstate`; you do not need to create the key
manually. Enable bucket versioning so prior state versions can be recovered.

Create an AWS IAM role trusted by GitHub Actions OIDC. Its trust policy must
match this repository and the `main` branch. Store its full ARN as the GitHub
Actions secret `AWS_ROLE_ARN`. The role that creates the EKS cluster is
automatically granted cluster-admin access by the cluster's
`bootstrap_cluster_creator_admin_permissions` setting; Terraform must not
create a second access entry for that same role.

**Important:** the role needs permissions for Terraform to manage the EKS
cluster, managed node group, IAM roles and policy attachments, and the cluster
security-group rule. It also needs `iam:PassRole` for
the EKS and EC2 service roles, plus S3 permissions to read/write the state
object and create/remove the `.tflock` lock object in the configured bucket.
`eks:DescribeCluster` alone is not enough for automatic provisioning. Restrict
the role trust to this repository; infrastructure changes can incur AWS costs.

After Terraform completes successfully, configure and verify kubectl:

```shell
aws eks update-kubeconfig --name voting-app-cluster --region us-east-1
kubectl get nodes
```

In the GitHub repository settings, add the `DOCKERHUB_USERNAME`,
`DOCKERHUB_TOKEN`, and `AWS_ROLE_ARN` Actions secrets. Set the `AWS_REGION`
repository variable to `us-east-1` and `EKS_CLUSTER_NAME` to
`voting-app-cluster`. Pushes to `main` run Trivy, build and publish commit-tagged images
to Docker Hub, and deploy that exact image tag with Helm. Pull requests scan
and build without publishing or deploying. Terraform provisions or updates the
EKS cluster in the infrastructure job; the workflow does not delete it.

You can also deploy the chart directly after configuring `kubectl`:

```shell
aws eks update-kubeconfig --name voting-app-cluster --region us-east-1
helm upgrade --install voting-app ./helm/voting-app --namespace voting-app --create-namespace --wait
kubectl get services --namespace voting-app
```

To demonstrate Helm recovery safely, manually run the workflow with
`rollback_demo` enabled. It installs the known-good release in the separate
`voting-rollback-demo` namespace, attempts an image tag that does not exist,
then rolls back to the recorded good revision. It does not alter the regular
`voting-app` release. To inspect or remove the demo later:

```shell
helm history voting-app-rollback-demo --namespace voting-rollback-demo
helm uninstall voting-app-rollback-demo --namespace voting-rollback-demo
kubectl delete namespace voting-rollback-demo
```

## Architecture

![Architecture diagram](architecture.excalidraw.png)

* A front-end web app in [Python](/vote) which lets you vote between two options
* A [Redis](https://hub.docker.com/_/redis/) which collects new votes
* A [.NET](/worker/) worker which consumes votes and stores them in…
* A [Postgres](https://hub.docker.com/_/postgres/) database backed by a Docker volume
* A [Node.js](/result) web app which shows the results of the voting in real time

## Notes

The voting application only accepts one vote per client browser. It does not register additional votes if a vote has already been submitted from a client.

This isn't an example of a properly architected perfectly designed distributed app... it's just a simple
example of the various types of pieces and languages you might see (queues, persistent data, etc), and how to
deal with them in Docker at a basic level.
