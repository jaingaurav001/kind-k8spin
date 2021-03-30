#!/usr/bin/make

SHELL ?= /bin/bash

#include .env
include .env
export $(shell sed 's/=.*//' .env)

.PHONY: up
up: create-cluster

.PHONY: install-docker
install-docker:
	sudo apt-get update
	sudo apt-get install apt-transport-https ca-certificates curl gnupg-agent software-properties-common
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
	sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu `lsb_release -cs` stable"
	sudo apt-get update
	sudo apt-get install docker-ce docker-ce-cli containerd.io
	sudo usermod -aG docker `id -un`

	@tput setaf 3; echo -e "\nLogout and login to reload group rights!\n"; tput sgr0

.PHONY: install-kubectl
install-kubectl:
	# Download and install kubectl
	curl -Lo /tmp/kind https://storage.googleapis.com/kubernetes-release/release/${KUBERNETES_VERSION}/bin/linux/amd64/kubectl
	chmod +x /tmp/kubectl
	sudo mv /tmp/kubectl /usr/local/bin

	# Install kubectl completion
	mkdir -p ~/.kube
	echo >>~/.bashrc
	echo 'source <(kubectl completion bash)' >>~/.bashrc

	@tput setaf 3; echo -e "\nStart a new shell to load kubectl completion!\n"; tput sgr0

.PHONY: install-krew
install-krew:
	# Download and install krew
	curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/krew.tar.gz" && tar zxvf krew.tar.gz && ./krew-linux_amd64 install krew

	# Add the ${HOME}/.krew/bin directory to your PATH environment variable
	echo 'export PATH=$$HOME/.krew/bin:$$PATH' >>~/.bashrc
	echo 'export PATH=$$HOME/.krew/bin:$$PATH' >>~/.zshrc

	@tput setaf 3; echo -e "\nStart a new shell to have krew in PATH!\n"; tput sgr0

.PHONY: install-krew-plugin
install-krew-plugin:
	# Download and install krew plugin
	kubectl krew index add k8spin https://github.com/k8spin/k8spin-operator.git
	kubectl krew search k8spin
	kubectl krew install k8spin/k8spin

.PHONY: install-kind
install-kind:
	# Download and install kind
	curl -Lo /tmp/kind https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-amd64
	chmod +x /tmp/kind
	sudo mv /tmp/kind /usr/local/bin

	# Install kind completion
	echo >>~/.bashrc
	echo 'source <(kind completion bash)' >>~/.bashrc

	@tput setaf 3; echo -e "\nStart a new shell to load kind completion!\n"; tput sgr0

.PHONY: install-helm
install-helm:
	# Download and install helm
	curl -sfL https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
	helm repo add stable https://charts.helm.sh/stable
	helm repo update

.PHONY: create-cluster
create-cluster:
	@tput setaf 6; echo -e "\nmake $@\n"; tput sgr0
	./scripts/kind-with-registry.sh

	# Calico
	curl https://docs.projectcalico.org/manifests/calico.yaml | kubectl apply -f -

	# CoreDNS
	kubectl scale deployment --replicas 1 coredns --namespace kube-system

	kubectl cluster-info --context kind-${KIND_CLUSTER_NAME}
	kubectl wait --for=condition=Available --timeout=${KIND_WAIT} -A deployment --all \
			|| echo 'TIMEOUT' >&2
	kubectl wait --for=condition=Ready --timeout=${KIND_WAIT} -A pod --all \
			|| echo 'TIMEOUT' >&2

.PHONY: install
install: install-cert-manager install-k8spin

.PHONY: uninstall
uninstall: uninstall-k8spin uninstall-cert-manager

.PHONY: install-cert-manager
install-cert-manager:
	helm repo add jetstack https://charts.jetstack.io
	helm repo update
	kubectl create namespace cert-manager
	helm install --version v1.2.0 cert-manager jetstack/cert-manager --namespace cert-manager --set installCRDs=true
	kubectl rollout status deployment cert-manager-webhook -n cert-manager -w

.PHONY: uninstall-cert-manager
uninstall-cert-manager:
	helm uninstall cert-manager -n cert-manager
	kubectl delete namespace cert-manager
	helm repo remove jetstack

.PHONY: install-k8spin
install-k8spin:
	helm chart pull ghcr.io/k8spin/k8spin-operator-chart:v1.0.6
	helm chart export ghcr.io/k8spin/k8spin-operator-chart:v1.0.6
	helm install k8spin-operator ./k8spin-operator
	kubectl wait --for=condition=Available deployment --timeout=2m --all

.PHONY: uninstall-k8spin
uninstall-k8spin:
	helm uninstall k8spin-operator

.PHONY: delete-cluster
delete-cluster:
	@tput setaf 6; echo -e "\nmake $@\n"; tput sgr0
	if [ $$(kind get clusters | grep ${KIND_CLUSTER_NAME}) ]; then ./scripts/teardown-kind-with-registry.sh; fi

.PHONY: down
down: delete-cluster
