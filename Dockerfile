FROM centos
MAINTAINER jawen
RUN yum install -y openssh-server sudo net-tools vim openssh-clients sshpass && sed -i 's/UsePAM yes/UsePAM no/g' /etc/ssh/sshd_config && echo "root:root" | chpasswd && echo "root   ALL=(ALL)       ALL" >> /etc/sudoers && ssh-keygen -t dsa -f /etc/ssh/ssh_host_dsa_key  && ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key && mkdir /var/run/sshd && mkdir /usr/cstor
EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
