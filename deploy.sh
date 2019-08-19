export HUOG_HOME=/var/jenkins_home/workspace/easyolap.cn

cd $HUOG_HOME
rm -rf www/*
cp -a public/* $HUOG_HOME/www/
