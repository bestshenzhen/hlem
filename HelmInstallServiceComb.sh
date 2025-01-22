#!/bin/bash

curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

echo "Verifying Helm installation..."
helm version

# 安装helm-s3插件
helm plugin install https://github.com/hypnoglow/helm-s3.git

# OBS相关的设置环境变量
export AWS_ACCESS_KEY_ID=EJQBXE6QFCRVF7S9TPWO
export AWS_SECRET_ACCESS_KEY=mH7q0IrMwOWfBwbM19Gevh4lH86RHVvq8Rg5yZZ9
export AWS_DEFAULT_REGION=ap-southeast-3
export AWS_ENDPOINT="obs.ap-southeast-3.myhuaweicloud.com"
export AWS_DISABLE_SSL=true

# 创建helm配置目录
mkdir -p /root/.config/helm/

#初始化Helm仓库文件
helm repo init

#创建新的存储库
helm s3 init s3://servicecomb-czq/charts

# 使用 Helm S3 插件添加仓库
helm repo add mynewrepo s3://servicecomb-czq/charts

# 编写zookeeper、edge-service、admin-service、admin-website、authentication-server、resource-server的chart yaml
#Chart地址：https://gitcode.com/moseszane168/open-source-for-huawei-demo-chart/overview
git clone https://gitcode.com/moseszane168/open-source-for-huawei-demo-chart.git

# 创建模板文件目录
mkdir -p /usr/local/templates

# 拷贝（递归拷贝）./open-source-for-huawei-demo-chart目录下所有文件到/usr/local/templates/
cp -r ./open-source-for-huawei-demo-chart/*  /usr/local/templates/

# 切换执行地址
cd /usr/local/templates/

# 存在重名的zookeeper服务，替换自定义的服务名
mv ./zookeeper ./zookeeper-test

# 处理配置文件
sed -i 's/ip:port/49.0.202.155:8000/g' ./authentication-server/values.yaml
sed -i 's/123456/Czq12qw!/g' ./authentication-server/values.yaml
sed -i 's/name: zookeeper/name: zookeeper-test/g' ./zookeeper-test/Chart.yaml

# 打包和发布
# ./admin-service：指向当前目录下的admin-service文件夹，它包含Helm chart结构，通常包括Chart.yaml文件、values.yaml文件以及一个或多个Kubernetes清单文件
helm package ./admin-service
helm package ./admin-website
helm package ./authentication-server
helm package ./edge-service
helm package ./resource-server
helm package ./zookeeper-test

# 推送chart到OBS
helm s3 push ./admin-service-0.1.0.tgz mynewrepo
helm s3 push ./admin-website-0.1.0.tgz mynewrepo
helm s3 push ./authentication-server-0.1.0.tgz mynewrepo
helm s3 push ./edge-service-0.1.0.tgz mynewrepo
helm s3 push ./resource-server-0.1.0.tgz mynewrepo
helm s3 push ./zookeeper-test-0.1.0.tgz mynewrepo

# 创建应用目录
mkdir -p /usr/local/apps

# 切换执行地址
cd /usr/local/apps/

# 从OBS拉取chart
helm pull s3://servicecomb-czq/charts/zookeeper-test-0.1.0.tgz
helm pull s3://servicecomb-czq/charts/admin-service-0.1.0.tgz
helm pull s3://servicecomb-czq/charts/admin-website-0.1.0.tgz
helm pull s3://servicecomb-czq/charts/authentication-server-0.1.0.tgz
helm pull s3://servicecomb-czq/charts/edge-service-0.1.0.tgz
helm pull s3://servicecomb-czq/charts/resource-server-0.1.0.tgz

# 加载Chart包到Helm
helm install zookeeper-test  ./zookeeper-test-0.1.0.tgz
helm install admin-service  ./admin-service-0.1.0.tgz
helm install dmin-website  ./admin-website-0.1.0.tgz
helm install authentication-server  ./authentication-server-0.1.0.tgz
helm install edge-service  ./edge-service-0.1.0.tgz
helm install resource-server  ./resource-server-0.1.0.tgz

# 部署Chart包
helm install zookeeper-test  ./zookeeper-test-0.1.0.tgz --namespace=servicecomb
helm install admin-service  ./admin-service-0.1.0.tgz --namespace=servicecomb
helm install dmin-website  ./admin-website-0.1.0.tgz --namespace=servicecomb
helm install authentication-server  ./authentication-server-0.1.0.tgz --namespace=servicecomb
helm install edge-service  ./edge-service-0.1.0.tgz --namespace=servicecomb
helm install resource-server  ./resource-server-0.1.0.tgz --namespace=servicecomb

# 验证部署
helm list
kubectl get pods --namespace=servicecomb
