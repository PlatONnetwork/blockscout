# BlockScout Docker Integration

# 需要指定CHAIN_TYPE
docker build --build-arg RELEASE_VERSION=6.6.0 --build-arg CHAIN_TYPE=platon_appchain -t blockscout:platon_appchain -f docker/Dockerfile .


For usage instructions and ENV variables, see the [docker integration documentation](https://docs.blockscout.com/for-developers/deployment/docker-compose-deployment).