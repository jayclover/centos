FROM centos
MAINTAINER jawen
RUN yum install -y openssh-server && yum install -y sudo && yum install -y net-tools && yum install -y vim && yum install -y openssh-clients && yum install -y sshpass
RUN echo "root:root" | chpasswd  
RUN echo "root   ALL=(ALL)       ALL" >> /etc/sudoers  
RUN ssh-keygen -t dsa -f /etc/ssh/ssh_host_dsa_key  
RUN ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key
RUN sed -i 's/UsePAM yes/UsePAM no/g' /etc/ssh/sshd_config

ADD jdk1.8.tar.gz /usr/local/
RUN ln -s /usr/local/jdk1.8/bin/java /usr/bin/java && echo "export PATH=$PATH:/usr/local/jdk1.8/bin" >> /etc/profile && source /etc/profile

ADD cstor.tar.gz /usr/
ADD test2018.6.5.tar.gz /

ENV HADOOP_HOME /usr/cstor/hadoop
ENV PATH $HADOOP_HOME/bin:$PATH

RUN chown -R root:root /usr/cstor/hbase
ENV HBASE_MANAGES_ZK false   

COPY startnginxpod.sh /opt/
COPY stopnginxpod.sh /opt/

RUN mkdir /var/run/sshd  
EXPOSE 22  
CMD ["/usr/sbin/sshd", "-D"]


