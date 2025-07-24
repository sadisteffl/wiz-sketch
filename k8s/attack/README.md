`gcc -fPIC -shared -o poc.so poc.c
`


Intall the gpu operator: 
helm repo add nvidia https://nvidia.github.io/gpu-operator
helm repo update

helm install gpu-operator nvidia/gpu-operator \
  --namespace gpu-operator \
  --create-namespace \
  --set "toolkit.env[0].name=NVIDIA_CONTAINER_TOOLKIT_OPT_IN_FEATURES" \
  --set "toolkit.env[0].value=enable-cuda-compat" \
  --set "toolkit.version=1.17.7-ubuntu20.04" \
  --version=25.3.1


instance_types = ["g4dn.medium"]
