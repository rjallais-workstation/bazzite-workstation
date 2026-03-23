#!/usr/bin/env nu
#MISE description="Install: Docker CE from official repository"
def main [] {
    let docker_packages = [
        containerd.io
        docker-buildx-plugin
        docker-ce
        docker-ce-cli
        docker-compose-plugin
        docker-model-plugin
    ]
    ^dnf config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo
    ^sed -i 's/enabled=.*/enabled=0/g' /etc/yum.repos.d/docker-ce.repo
    ^dnf -y install --enablerepo=docker-ce-stable ...$docker_packages
    ^rm -rf /var/lib/dnf
}
