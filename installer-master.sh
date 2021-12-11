# Aggiornamento dei pacchetti

until [[ -f /var/lib/cloud/instance/boot-finished ]]; do
  sleep 1
done

sudo apt-get -y update
sudo apt-get -y dist-upgrade

sudo apt-get -y install python3
sudo apt-get -y install python3-pip
sudo pip3 install numpy
sudo pip3 install pyspark==3.0.3
sudo pip3 install nltk

sudo apt-get -y install python-is-python3
sudo pip3 install sparknlp
python3 -m nltk.downloader popular

sudo apt-get -y install openjdk-8-jdk
sudo wget -q https://archive.apache.org/dist/hadoop/common/hadoop-2.7.7/hadoop-2.7.7.tar.gz > /dev/null
sudo tar zxvf hadoop-2.7.7.tar.gz
sudo mv ./hadoop-2.7.7 /home/ubuntu/hadoop

echo '
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export PATH=$PATH:$JAVA_HOME/bin
export HADOOP_HOME=/home/ubuntu/hadoop
export PATH=$PATH:/home/ubuntu/hadoop/bin
export HADOOP_CONF_DIR=/home/ubuntu/hadoop/etc/hadoop' | sudo tee --append /home/ubuntu/.profile

source /home/ubuntu/.profile

echo '
Host namenode
HostName namenode
User ubuntu
IdentityFile /home/ubuntu/.ssh/amzkey.pem
Host datanode1
HostName datanode1
User ubuntu
IdentityFile /home/ubuntu/.ssh/amzkey.pem
Host datanode2
HostName datanode2
User ubuntu
IdentityFile /home/ubuntu/.ssh/amzkey.pem
Host datanode3
HostName datanode3
User ubuntu
IdentityFile /home/ubuntu/.ssh/amzkey.pem
Host datanode4
HostName datanode4
User ubuntu
IdentityFile /home/ubuntu/.ssh/amzkey.pem' | sudo tee --append /home/ubuntu/.ssh/config

echo '
172.31.16.240 namenode
172.31.16.241 datanode1
172.31.16.242 datanode2
172.31.16.243 datanode3
172.31.16.244 datanode4' | sudo tee --append /etc/hosts

ssh-keygen -f /home/ubuntu/.ssh/id_rsa -t rsa -P '' <<< y

cat /home/ubuntu/.ssh/id_rsa.pub >> /home/ubuntu/.ssh/authorized_keys
ssh -o StrictHostChecking=no datanode1 'cat >> /home/ubuntu/.ssh/authorized_keys'</home/ubuntu/.ssh/id_rsa.pub
ssh -o StrictHostChecking=no datanode2 'cat >> /home/ubuntu/.ssh/authorized_keys'</home/ubuntu/.ssh/id_rsa.pub
ssh -o StrictHostChecking=no datanode3 'cat >> /home/ubuntu/.ssh/authorized_keys'</home/ubuntu/.ssh/id_rsa.pub
ssh -o StrictHostChecking=no datanode4 'cat >> /home/ubuntu/.ssh/authorized_keys'</home/ubuntu/.ssh/id_rsa.pub

sudo sed -i -e 's/export\ JAVA_HOME=\${JAVA_HOME}/export\ JAVA_HOME=\/usr\/lib\/jvm\/java-8-openjdk-amd64/g' /home/ubuntu/hadoop/etc/hadoop/hadoop-env.sh

# Modifica del file core-site.xml
echo '<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<!--
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License. See accompanying LICENSE file.
-->
<!-- Put site-specific property overrides in this file. -->
<configuration>
  <property>
    <name>fs.defaultFS</name>
    <value>hdfs://namenode:9000</value>
  </property>
</configuration>' | sudo tee /home/ubuntu/hadoop/etc/hadoop/core-site.xml

# Modifica del file yarn-site.xml
echo '<?xml version="1.0"?>
<!--
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License. See accompanying LICENSE file.
-->
<!-- Put site-specific property overrides in this file. -->
<configuration>
  <property>
    <name>yarn.nodemanager.aux-services</name>
    <value>mapreduce_shuffle</value>
  </property>
  <property>
    <name>yarn.nodemanager.aux-services.mapreduce.shuffle.class</name>
    <value>org.apache.hadoop.mapred.ShuffleHandler</value>
  </property>
  <property>
    <name>yarn.resourcemanager.hostname</name>
    <value>namenode</value>
  </property>
</configuration>' | sudo tee /home/ubuntu/hadoop/etc/hadoop/yarn-site.xml

sudo cp ${HADOOP_CONF_DIR}/mapred-site.xml.template ${HADOOP_CONF_DIR}/mapred-site.xml

echo '<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<!--
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License. See accompanying LICENSE file.
-->
<!-- Put site-specific property overrides in this file. -->
<configuration>
  <property>
    <name>mapreduce.jobtracker.address</name>
    <value>namenode:54311</value>
  </property>
  <property>
    <name>mapreduce.framework.name</name>
    <value>yarn</value>
  </property>
</configuration>' | sudo tee /home/ubuntu/hadoop/etc/hadoop/mapred-site.xml


# Modifica del file hdfs-site.xml
echo '<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<!--
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License. See accompanying LICENSE file.
-->
<!-- Put site-specific property overrides in this file. -->
<configuration>
  <property>
    <name>dfs.replication</name>
    <value>5</value>
  </property>
  <property>
    <name>dfs.namenode.name.dir</name>
    <value>file:///home/ubuntu/hadoop/data/hdfs/namenode</value>
  </property>
  <property>
    <name>dfs.datanode.data.dir</name>
    <value>file:///home/ubuntu/hadoop/data/hdfs/datanode</value>
  </property>
</configuration>' | sudo tee /home/ubuntu/hadoop/etc/hadoop/hdfs-site.xml

sudo mkdir -p ${HADOOP_HOME}/data/hdfs/namenode
sudo mkdir -p ${HADOOP_HOME}/data/hdfs/datanode

echo '
namenode' | sudo tee --append ${HADOOP_CONF_DIR}/masters

echo '
datanode1
datanode2
datanode3
datanode4
' | sudo tee ${HADOOP_CONF_DIR}/slaves

sudo chown -R ubuntu ${HADOOP_HOME}

sudo wget -q https://downloads.apache.org/spark/spark-3.0.3/spark-3.0.3-bin-hadoop2.7.tgz
sudo tar xvzf spark-3.0.3-bin-hadoop2.7.tgz
sudo mv ./spark-3.0.3-bin-hadoop2.7 /home/ubuntu/spark
sudo cp /home/ubuntu/spark/conf/spark-env.sh.template /home/ubuntu/spark/conf/spark-env.sh

# Configurazione di Spark
echo '
export SPARK_MASTER_HOST=namenode
export HADOOP_CONF_DIR=/home/ubuntu/hadoop/conf' | sudo tee --append /home/ubuntu/spark/conf/spark-env.sh > /dev/null





