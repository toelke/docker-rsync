[![ci](https://github.com/toelke/docker-rsync/actions/workflows/build-docker.yaml/badge.svg?branch=main)](https://github.com/toelke/docker-rsync/actions/workflows/build-docker.yaml)

Simply a rsync packaged in a distroless image; I use it as sidecar in kubernetes to copy files out of running pods with RWX-mounted volumes:

```shell
cat > ./rsync-helper.sh << EOF
pod=$1;shift;kubectl exec -i $pod -- "$@"
EOF

rsync -av thePodName:/foo/bar /dest
```
