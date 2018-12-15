#!/bin/bash
#
# Copyright (C) 2013-2018 Draios Inc dba Sysdig.
#
# This file is part of sysdig .
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
#set -e

function mount_cgroup_subsys(){
	requested_subsys=$1
	subsys=$(awk -v subsys=$requested_subsys '
$(NF-2) == "cgroup" {
	sub(/(^|,)rw($|,)/, "", $NF)
	if (!printed && $NF ~ "(^|,)" subsys "($|,)") {
		print $NF
		printed=1
	}
}

END {
	if (!printed) {
		print subsys
	}
}' < /proc/self/mountinfo)
	echo "* Mounting $requested_subsys cgroup fs (using subsys $subsys)"
	mkdir -p $SYSDIG_HOST_ROOT/cgroup/$requested_subsys
	mount -t cgroup -o $subsys,ro none $SYSDIG_HOST_ROOT/cgroup/$requested_subsys
}


echo "* Setting up /usr/src links from host"

for i in $(ls $SYSDIG_HOST_ROOT/usr/src)
do
	ln -s $SYSDIG_HOST_ROOT/usr/src/$i /usr/src/$i
done
mount_cgroup_subsys memory
mount_cgroup_subsys cpuacct


/usr/bin/sysdig-probe-loader

exec "$@"
