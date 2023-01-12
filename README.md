[![ci](https://github.com/toelke/docker-rsync/actions/workflows/build-docker.yaml/badge.svg?branch=main)](https://github.com/toelke/docker-rsync/actions/workflows/build-docker.yaml)

Simply a rsync packaged in a distroless image; I use it as sidecar in kubernetes to copy files out of running pods with RWX-mounted volumes.

## Copy data from pod

```shell
rsync -Pavc --blocking-io --rsh ./kubectl-rsh.sh podname:/data /data
```

## Copy data from pod in namespace

```shell
rsync -Pavc --blocking-io --rsh ./kubectl-rsh.sh podname@namespace:/data /data
```

## Copy data from container in  pod in namespace

```shell
rsync -Pavc --blocking-io --rsh ./kubectl-rsh.sh podname.container@namespace:/data /data
```

## In kubernetes CronJob

This is how it can be used to backup a deployment:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: foo
  namespace: default
spec:
  selector:
    matchLabels:
      app: foo
  replicas: 1
  template:
    metadata:
      labels:
        app: foo
    spec:
      containers:
        - name: foo
          image: foo/foo
          volumeMounts:
            - name: data
              mountPath: /data
        - name: rsync
          image: toelke158/docker-rsync
          volumeMounts:
            - name: data
              mountPath: /data
---
apiVersion: batch/v1
kind: CronJob
metadata:
  name: backup-foo
  namespace: default
spec:
  concurrencyPolicy: Forbid
  schedule: "51 3 * * *"
  jobTemplate:
    spec:
      template:
        spec:
          initContainers:
            - name: backup-foo
              image: alpine/k8s:1.21.2
              command:
                - bash
                - -exuc
                - |
                  apk add rsync
                  cat > kubectl-rsh.sh << 'EOF'
                  #!/bin/bash

                  set -exu
                  set -o pipefail

                  namespace=''
                  container=''
                  pod=$1
                  shift

                  # rsync calls us with "-l pod namespace" if we use pod@namespace
                  if [ "X$pod" = "X-l" ]; then
                    pod=$1
                    shift
                    namespace="-n $1"
                    shift
                  fi

                  # pod is "pod.container"
                  if [[ "$pod" == *"."* ]]; then
                    container="-c ${pod#*.}"
                    pod="${pod%.*}"
                  fi

                  # pod is "type#name"
                  if [[ "$pod" == *"#"* ]]; then
                    pod="${pod//#/\/}"
                  fi

                  exec kubectl $namespace exec -i $container $pod -- "$@"
                  EOF
                  chmod +x kubectl-rsh.sh
                  rsync -Pavc --blocking-io --rsh ./kubectl-rsh.sh deploy#foo.rsync:/data /data
              volumeMounts:
                - mountPath: /data
                  name: data
          containers:
            - name: restic
              image: restic/restic
              command: ['/bin/sh']
              args:
                - -c
                - restic --verbose --repo repo --host foo --tag foo backup /data
              volumeMounts:
                - mountPath: /data
                  name: data
          restartPolicy: Never
          volumes:
            - name: data
              emptyDir: {}
```
