HUOG_HOME=/data/devops/hugo/easyolap.cn

sudo docker rm easyolap-hugo -f
sudo rm -rf output/*
sudo docker run --env HUGO_BASEURL='https://easyolap.cn/' \
--env HUGO_THEME=AllinOne --name "easyolap-hugo" \
--publish-all \
--volume $(HUOG_HOME)/:/src --volume $(HUOG_HOME)/output:/output jojomi/hugo