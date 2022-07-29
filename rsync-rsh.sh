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
