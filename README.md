# GitHub Agents

## Requirements

### AWS

- [x] EKS v1.25
- [x] Keda v2.10.1

### K3S

- [x] Keda v2.10.1

## Usage

### k8s - EKS

```console
cp -v .env.sample .env
```

```console
bash scripts/set-aws-vars.sh
```

```console
kubectl apply -f prod/000_keda.yaml
```

```console
kubectl apply -f prod/aws
```

### k3s

```console
cp -v .env.sample .env
```

```console
bash scripts/set-k3s-vars.sh
```

```console
kubectl apply -f prod/000_keda.yaml
```

```console
kubectl apply -f prod/k3s
```

## Usage with Docker or Podman

### Org Runner

```console
docker run -d --restart always --name github-runner \
  -e RUNNER_NAME_PREFIX="myrunner" \
  -e ACCESS_TOKEN="footoken" \
  -e RUNNER_WORKDIR="/tmp/github-runner-your-repo" \
  -e RUNNER_GROUP="my-group" \
  -e RUNNER_SCOPE="org" \
  -e DISABLE_AUTO_UPDATE="true" \
  -e ORG_NAME="octokode" \
  -e LABELS="my-label,other-label" \
  -v /tmp/github-runner-your-repo:/tmp/github-runner-your-repo \
  docker.io/<DOCKER-OWNER>/github-runner:debian-12
```

### Per-Repo Runner

```console
docker run -d --restart always --name github-runner \
  -e REPO_URL="https://github.com/myoung34/repo" \
  -e RUNNER_NAME="foo-runner" \
  -e RUNNER_TOKEN="footoken" \
  -e RUNNER_WORKDIR="/tmp/github-runner-your-repo" \
  -e RUNNER_GROUP="my-group" \
  -v /tmp/github-runner-your-repo:/tmp/github-runner-your-repo \
  docker.io/rusian/github-runner:debian-12
```

## Logs

Check if azure-agent working

```console
kubectl -n keda logs pod/keda-operator-<HASH>
```

## Build

### Build Image via docker

Sample:

```console
docker build --no-cache --tag rusian/github-runner:debian-12 -f container/Dockerfile container/
```

### Build Image via podman

Sample:

```console
podman build --net=host --format docker --no-cache --tag rusian/github-runner:debian-12 -f container/Dockerfile container/
```

## KEDA's relationship with HPA

KEDA acts like a "Custom Metrics API" for exposing metrics to the HPA. KEDA
can't do its job without the HPA.

The complexity of developing a metrics server is abstracted away by using KEDA.

Scalers are the glue that provides the metrics from various sources to the HPA.

Here's a list of some of the most widely used scalers:

- [x] Apache Kafka
- [x] AWS CloudWatch
- [x] AWS Kinesis Stream
- [x] AWS SQS Queue
- [x] Azure Blob Storage
- [x] Azure Event Hubs
- [x] Azure Log Analytics
- [x] Azure Monitor
- [x] Azure Service Bus
- [x] Azure Storage Queue
- [x] Github Runner Scaler
- [x] Google Cloud Platform Pub/Sub
- [x] IBM MQ
- [x] InfluxDB
- [x] NATS Streaming
- [x] OpenStack Swift
- [x] PostgreSQL
- [x] Prometheus
- [x] RabbitMQ Queue
- [x] Redis Lists

For a complete list view the [scalers](https://keda.sh/docs/2.8/scalers/) section on the KEDA site.

A common question is when should one use a HPA and when to enlist KEDA.
If the workload is memory or cpu intensive, and has a well defined metric
that can be measured then using a HPA is sufficient.

When dealing with a workload that is event driven or relies upon a
custom metric, then using KEDA should be the first choice.

## Tricks

### Delete github runners orphans (Org Runner)

```console
export GH_TOKEN="<your-token-github>"
gh api \
  -H "Accept: application/vnd.github.v3+json" \
  /orgs/MyBestOrg/actions/runners \
  -q '.runners[] | {id,status,busy} | select((.busy == false) and (.status == "offline")) | {id} | .[]' \
  --paginate | xargs -I {} \
  gh api \
  --method DELETE \
  -H "Accept: application/vnd.github.v3+json" \
  /orgs/MyBestOrg/actions/runners/{}
```

### Delete github runners orphans (Per-Repo Runner)

```
export GH_TOKEN="<your-token-github>"
gh api \
  -H "Accept: application/vnd.github.v3+json" \
  /repos/freeCodeCamp/news/actions/runners \
  -q '.runners[] | {id,status,busy} | select((.busy == false) and (.status == "offline")) | {id} | .[]' \
  --paginate | xargs -I {} \
  gh api \
  --method DELETE \
  -H "Accept: application/vnd.github.v3+json" \
  /repos/freeCodeCamp/news/actions/runners/{}
```

## References

- <https://github.com/actions/runner/blob/main/docs/start/envlinux.md>
- <https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/autoscaling-with-self-hosted-runners>
- <https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/using-self-hosted-runners-in-a-workflow>
- <https://keda.sh/docs/2.10/deploy/>

## License

This work is licensed under the [GNU GPLv3+](LICENSE)
