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

Provision the EKS cluster from `terraform/k8s-cluster` using AWS credentials
with permission to create the listed EKS and IAM resources:

```shell
cd terraform/k8s-cluster
terraform init
terraform apply
```

For CI deployments, create an AWS IAM role trusted by GitHub Actions OIDC and
grant it `eks:DescribeCluster`. Add its ARN as the Terraform variable
`github_actions_role_arn` when applying, so EKS grants that role cluster
administrator access:

```shell
terraform apply -var="github_actions_role_arn=arn:aws:iam::<account-id>:role/<github-actions-role>"
```

In the GitHub repository settings, add the `DOCKERHUB_USERNAME`,
`DOCKERHUB_TOKEN`, and `AWS_ROLE_ARN` Actions secrets and set the
`AWS_REGION` and `EKS_CLUSTER_NAME` Actions variables to match Terraform.
Restrict the IAM role's OIDC trust policy to this repository's `main` branch.
Pushes to `main` run Trivy, build and publish commit-tagged images to Docker
Hub, and deploy that exact image tag with Helm. Pull requests scan and build
without publishing or deploying.

You can also deploy the chart directly after configuring `kubectl`:

```shell
aws eks update-kubeconfig --name voting-app-cluster --region eu-west-1
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
