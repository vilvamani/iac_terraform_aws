#!/bin/bash

exec &> /var/log/init-aws-kubernetes-master.log

set -o verbose
set -o errexit
set -o pipefail

export KUBEADM_TOKEN=${kubeadm_token}
export DNS_NAME=${dns_name}
export IP_ADDRESS=${ip_address}
export CLUSTER_NAME=${cluster_name}
export ASG_NAME=${asg_name}
export ASG_MIN_NODES="${asg_min_nodes}"
export ASG_MAX_NODES="${asg_max_nodes}"
export AWS_REGION=${aws_region}
export AWS_SUBNETS="${aws_subnets}"
export ADDONS="${addons}"
export KUBERNETES_VERSION="1.19.3"
export EFS_DNS="${efs_dns_name}"
export EFS_ID="${efs_id}"

# Set this only after setting the defaults
set -o nounset

# We needed to match the hostname expected by kubeadm an the hostname used by kubelet
FULL_HOSTNAME="$(curl -s http://169.254.169.254/latest/meta-data/hostname)"

# Make DNS lowercase
DNS_NAME=$(echo "$DNS_NAME" | tr 'A-Z' 'a-z')

# Install AWS CLI client
yum install -y epel-release
yum install -y python3-pip
pip3 install awscli --upgrade

# Install NFS Util & GIT
yum -y install nfs-utils git

mkdir -p ~/efs-mount-point

# Tag subnets
for SUBNET in $AWS_SUBNETS
do
  aws ec2 create-tags --resources $SUBNET --tags Key=kubernetes.io/cluster/$CLUSTER_NAME,Value=shared --region $AWS_REGION
done

# Install docker
yum install -y yum-utils device-mapper-persistent-data lvm2 docker

# Install Kubernetes components
sudo cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
        https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

# setenforce returns non zero if already SE Linux is already disabled
is_enforced=$(getenforce)
if [[ $is_enforced != "Disabled" ]]; then
  setenforce 0
  sed -i 's/SELINUX=enforcing/SELINUX=permissive/g' /etc/selinux/config
  
fi

yum install -y kubelet-$KUBERNETES_VERSION kubeadm-$KUBERNETES_VERSION kubernetes-cni

# Helm3 Installation
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

# Start services
systemctl enable docker
systemctl start docker
systemctl enable kubelet
systemctl start kubelet

# Docker Run permission
sudo chown centos:centos /var/run/docker.sock

# Set settings needed by Docker
sysctl net.bridge.bridge-nf-call-iptables=1
sysctl net.bridge.bridge-nf-call-ip6tables=1

# Fix certificates file on CentOS
if cat /etc/*release | grep ^NAME= | grep CentOS ; then
    rm -rf /etc/ssl/certs/ca-certificates.crt/
    cp /etc/ssl/certs/ca-bundle.crt /etc/ssl/certs/ca-certificates.crt
fi

# Initialize the master
cat >/tmp/kubeadm.yaml <<EOF
---
apiVersion: kubeadm.k8s.io/v1beta2
kind: InitConfiguration
bootstrapTokens:
- groups:
  - system:bootstrappers:kubeadm:default-node-token
  token: $KUBEADM_TOKEN
  ttl: 0s
  usages:
  - signing
  - authentication
nodeRegistration:
  criSocket: /var/run/dockershim.sock
  kubeletExtraArgs:
    cloud-provider: aws
    read-only-port: "10255"
  name: $FULL_HOSTNAME
  taints:
  - effect: NoSchedule
    key: node-role.kubernetes.io/master
---
apiVersion: kubeadm.k8s.io/v1beta2
kind: ClusterConfiguration
apiServer:
  certSANs:
  - $DNS_NAME
  - $IP_ADDRESS
  extraArgs:
    authorization-mode: "Node,RBAC"
  timeoutForControlPlane: 5m0s
certificatesDir: /etc/kubernetes/pki
clusterName: $CLUSTER_NAME
controllerManager:
  extraArgs:
    cloud-provider: aws
dns:
  type: CoreDNS
etcd:
  local:
    dataDir: /var/lib/etcd
imageRepository: k8s.gcr.io
kubernetesVersion: v$KUBERNETES_VERSION
networking:
  dnsDomain: cluster.local
  podSubnet: ""
  serviceSubnet: 10.96.0.0/12
scheduler: {}
---
EOF

kubeadm reset --force
kubeadm init --config /tmp/kubeadm.yaml

# Use the local kubectl config for further kubectl operations
export KUBECONFIG=/etc/kubernetes/admin.conf

echo "export KUBECONFIG=/etc/kubernetes/admin.conf" >> /root/.bash_profile

# Install calico
kubectl apply -f /tmp/calico.yaml

# Allow the user to administer the cluster
kubectl create clusterrolebinding admin-cluster-binding --clusterrole=cluster-admin --user=admin

# Prepare the kubectl config file for download to client (IP address)
export KUBECONFIG_OUTPUT=/home/centos/kubeconfig_ip
kubeadm alpha kubeconfig user \
  --client-name admin \
  --apiserver-advertise-address $IP_ADDRESS \
  > $KUBECONFIG_OUTPUT
chown centos:centos $KUBECONFIG_OUTPUT
chmod 0600 $KUBECONFIG_OUTPUT

cp /home/centos/kubeconfig_ip /home/centos/kubeconfig
sed -i "s/server: https:\/\/$IP_ADDRESS:6443/server: https:\/\/$DNS_NAME:6443/g" /home/centos/kubeconfig
chown centos:centos /home/centos/kubeconfig
chmod 0600 /home/centos/kubeconfig

kubectl apply -k "github.com/kubernetes-sigs/aws-efs-csi-driver/deploy/kubernetes/overlays/stable/?ref=release-1.0" --validate=false

# Load addons
for ADDON in $ADDONS
do
  curl $ADDON | envsubst > /tmp/addon.yaml
  kubectl apply -f /tmp/addon.yaml
  rm /tmp/addon.yaml
done

#kubectl create clusterrolebinding jenkins-sa-binding --clusterrole=cluster-admin --user=admin --user=kubelet --group=system:system:serviceaccount:jenkins:default
#kubectl create clusterrolebinding jenkins-sa-admin --clusterrole cluster-admin --serviceaccount=jenkins:default
#kubectl create clusterrolebinding default-sa-binding --clusterrole=cluster-admin --user=admin --user=kubelet --group=system:system:serviceaccount:default:default
#kubectl create clusterrolebinding default-sa-admin --clusterrole cluster-admin --serviceaccount=default:default

# Mount EFS Storage
mount -t nfs -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport $EFS_DNS:/ ~/efs-mount-point

# Mount K8s persistentvolume path
mkdir -p ~/efs-mount-point/jenkins
mkdir -p ~/efs-mount-point/sonarqube-extensions
mkdir -p ~/efs-mount-point/sonarqube-data
mkdir -p ~/efs-mount-point/postgres
mkdir -p ~/efs-mount-point/grafana

chmod -R 777 ~/efs-mount-point/jenkins
chmod -R 777 ~/efs-mount-point/sonarqube-extensions
chmod -R 777 ~/efs-mount-point/sonarqube-data
chmod -R 777 ~/efs-mount-point/postgres
chmod -R 777 ~/efs-mount-point/grafana

# Create DevOps Namespace
kubectl create namespace devops

# Download Jenkins helm repo
helm repo add stable https://charts.helm.sh/stable
helm repo list

cat >/tmp/config.json <<EOF
{
    "auths": {
        "https://index.docker.io/v1/": {
            "auth": "dmlsdmFtYW5pMDA3OlJldmF0aHlAMDA3"
        }
    }
}
EOF

kubectl create configmap docker-config --from-file=/tmp/config.json --namespace devops

cat >/tmp/jenkins_volume.yaml <<EOF
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: jenkins
spec:
  capacity:
    storage: 25Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: efs-sc
  csi:
    driver: efs.csi.aws.com
    volumeHandle: $EFS_ID:/jenkins
EOF

cat >/tmp/sonarqube_volume.yaml <<EOF
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: postgres-pv
spec:
  capacity:
    storage: 5Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  storageClassName: efs-sc
  csi:
    driver: efs.csi.aws.com
    volumeHandle: $EFS_ID:/postgres

---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: sonarqube-extensions-pv
spec:
  capacity:
    storage: 5Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  storageClassName: efs-sc
  csi:
    driver: efs.csi.aws.com
    volumeHandle: $EFS_ID:/sonarqube-extensions

---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: sonarqube-data-pv
spec:
  capacity:
    storage: 5Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  storageClassName: efs-sc
  csi:
    driver: efs.csi.aws.com
    volumeHandle: $EFS_ID:/sonarqube-data
    
EOF

cat >/tmp/grafana_volume.yaml <<EOF
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: grafana-pv
spec:
  capacity:
    storage: 5Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  storageClassName: efs-sc
  csi:
    driver: efs.csi.aws.com
    volumeHandle: $EFS_ID:/grafana
EOF

cat >/tmp/jenkins_role_permission.yaml <<EOF
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: devops-clusterrolebinding
subjects:
- kind: ServiceAccount
  name: default
  namespace: devops
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: ""
EOF

kubectl apply -f /tmp/jenkins_role_permission.yaml --namespace devops

# Create/Deploy Jenkins
kubectl apply -f /tmp/jenkins_volume.yaml --namespace devops
helm upgrade --install jenkins stable/jenkins  --values https://raw.githubusercontent.com/vilvamani/iac_terraform_aws/main/modules/templates/jenkins-values.yml --namespace devops

kubectl get pods --namespace=devops

# Create/Deploy SonarQube
kubectl apply -f /tmp/sonarqube_volume.yaml --namespace devops
kubectl apply -f  https://raw.githubusercontent.com/vilvamani/iac_terraform_aws/main/sonarqube/sonarqube-secrets.yaml --namespace devops
kubectl apply -f  https://raw.githubusercontent.com/vilvamani/iac_terraform_aws/main/sonarqube/postgres-pvc.yaml --namespace devops
kubectl apply -f  https://raw.githubusercontent.com/vilvamani/iac_terraform_aws/main/sonarqube/postgres-deployment.yaml --namespace devops
kubectl apply -f  https://raw.githubusercontent.com/vilvamani/iac_terraform_aws/main/sonarqube/postgres-service.yaml --namespace devops
kubectl apply -f  https://raw.githubusercontent.com/vilvamani/iac_terraform_aws/main/sonarqube/sonarqube-pvc.yaml --namespace devops
kubectl apply -f  https://raw.githubusercontent.com/vilvamani/iac_terraform_aws/main/sonarqube/sonarqube-deployment.yaml --namespace devops
kubectl apply -f  https://raw.githubusercontent.com/vilvamani/iac_terraform_aws/main/sonarqube/sonarqube-service.yaml --namespace devops

kubectl get pods --namespace=devops

# Create/Deploy Grafana
kubectl apply -f /tmp/grafana_volume.yaml --namespace devops
kubectl apply -f https://raw.githubusercontent.com/vilvamani/iac_terraform_aws/main/grafana/grafana-configmap.yaml --namespace devops
kubectl apply -f https://raw.githubusercontent.com/vilvamani/iac_terraform_aws/main/grafana/grafana-secrets.yaml --namespace devops
kubectl apply -f https://raw.githubusercontent.com/vilvamani/iac_terraform_aws/main/grafana/grafana-pvc.yaml --namespace devops
kubectl apply -f https://raw.githubusercontent.com/vilvamani/iac_terraform_aws/main/grafana/grafana-deployment.yaml --namespace devops
kubectl apply -f https://raw.githubusercontent.com/vilvamani/iac_terraform_aws/main/grafana/grafana-service.yaml --namespace devops

kubectl get pods --namespace=devops

# Create/Deploy prometheus
kubectl create namespace monitoring

#kubectl apply -f /tmp/prometheus_config_map.yaml --namespace monitoring
#kubectl apply -f https://raw.githubusercontent.com/vilvamani/iac_terraform_aws/main/prometheus/clusterRole.yaml --namespace monitoring
#kubectl apply -f https://raw.githubusercontent.com/vilvamani/iac_terraform_aws/main/prometheus/prometheus-deployment.yaml --namespace monitoring
#kubectl apply -f https://raw.githubusercontent.com/vilvamani/iac_terraform_aws/main/prometheus/prometheus-service.yaml --namespace monitoring

#kubectl get pods --namespace=monitoring
