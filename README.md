#Short Description


This small project aims assisting those who seek a better understanding and commonly have issues running "daemonized" images on any kind of orchestrators.

1 - Create a "daemonized" docker image using runit  
2 - Create a small nginx image (10.4 MB in size compared to 108 MB original nginx image from dockerhub)  
3 - Provide a hands on example of a Dockerfile that you could use in production

###Targeted audience:

This article aims engineers that already have a minimum knowledge in docker. It doesn't require any orchestrator's (k8 or ecs) knowledge. However it should be used as source for future articles. Minimum Linux understanding.

###The Dockerfile:

```
    FROM alpine

    RUN apk --update add \\  
        runit \\  
        bash \\  
        openssh-server \\  
        nginx \\  
    && rm -rf /var/cache/apk/*

    ENV NOTVISIBLE "in users profile"  
  
    RUN ssh-keygen -t rsa -b 4096 -C "Mykey" -P "" -f "/etc/ssh/ssh_host_rsa_key" -q  
    RUN mkdir /run/nginx  /usr/lib/nginx/html  
    RUN echo 'root:password' | chpasswd  
    RUN sed -i s/'#PermitRootLogin prohibit-password'/'PermitRootLogin yes'/g /etc/ssh/sshd_config  
 
    COPY conf/service /etc/service
    COPY conf/nginx/index.html /usr/lib/nginx/html/index.html
    COPY conf/nginx/default.conf /etc/nginx/conf.d/default.conf

    EXPOSE 22
    EXPOSE 80

    ENTRYPOINT ["/sbin/runsvdir", "-P", "/etc/service"]
```

###How It works:

This image makes use of the alpine linux original image from dockerhu and makes use of the apk package manager.

More information on the alpine project

In the configuration above we install the following packages:

runit => smarden.org/runit

* I like to use runit since it's small, free,. Feel free

bash => https://www.gnu.org/software/bash/

openssh-server => https://www.openssh.com

nginx => https://nginx.org/en/

* Much used as webserver and/or proxy server.


In order to be able to use this image, build the image:

```
[ec2-user@ip-172-31-23-71 ~]$ cd Build/
[ec2-user@ip-172-31-23-71 Build]$ ls -l
total 16
-rw-r--r-- 1 ec2-user ec2-user  683 Oct 18 18:45 Dockerfile
drwxr-xr-x 5 ec2-user ec2-user 4096 Oct 18 18:27 conf
```
These files are organized like the following:

```
[ec2-user@ip-172-31-23-71 Build]$ tree
.
|-- conf
|   |-- nginx
|   |   |-- default.conf
|   |   `-- index.html
|   |-- script
|   |   `-- script.sh
|   `-- service
|       |-- nginx
|       |   `-- run
|       `-- ssh
|           `-- run
|-- Dockerfile
```

To build the image, you need to issue the "docker build" command followed by a -t parameter, an image-name and the location. After issuing the command you should se docker creating several intermediate containers (in this example 13 due to multiple commands executed in the Dockerfile) and performing configurations. If the image creation is successful you should see a message like "Successfully built <container-id>". First, let's clone the project:
```
git clone https://github.com/fernandino143/sample-dockerfile.git
cd sample-dockerfile
```
And build
```
[ec2-user@ip-172-31-23-71 Build]$ docker build -t article . 
Sending build context to Docker daemon 13.31 kB
Step 1/13 : FROM alpine
 ---> 76da55c8019d
...
...
...
Step 13/13 : ENTRYPOINT /sbin/runsvdir -P /etc/service
 ---> Using cache
 ---> b5aa2c1fff3d
Successfully built b5aa2c1fff3d
```
Now, if you run the docker images command you should be able to see the b5aa2c1fff3d image.

```
[ec2-user@ip-172-31-23-71 Build]$ docker images
REPOSITORY                TAG                 IMAGE ID            CREATED             SIZE
article                   latest              b5aa2c1fff3d        30 minutes ago      10.4 MB
...
nginx                     latest              1e5ab59102ce        8 days ago          108 MB
```

Now, let's run the image detached exporting port 22 and 80 to our host:
```
[ec2-user@ip-172-31-23-71 Build]$ docker run -d -p :22 -p :80 article
e79b188315579426cb33a1422668563626bc7f731c1bc6041f573a5087d96612
```
Run the docker ps command to see the container running the ports that were dinamically associated with the mapped ports
```
user@ip-172-31-23-71 Build]$ docker ps
CONTAINER ID        IMAGE                            COMMAND                  CREATED              STATUS              PORTS                                          NAMES
e79b18831557        article                          "/sbin/runsvdir -P..."   About a minute ago   Up About a minute   0.0.0.0:37074->22/tcp, 0.0.0.0:37073->80/tcp   hungry_mayer
```
###Let's test it:
```
[ec2-user@ip-172-31-23-71 Build]$ docker port e79b18831557
22/tcp -> 0.0.0.0:37074
80/tcp -> 0.0.0.0:37073
[ec2-user@ip-172-31-23-71 Build]$ curl localhost:37073
Hello
[ec2-user@ip-172-31-23-71 Build]$ ssh root@localhost -p 37074 -o StrictHostKeyChecking=no
Warning: Permanently added '[localhost]:37074' (RSA) to the list of known hosts.
root@localhost's password: 
Welcome to Alpine!
The Alpine Wiki contains a large amount of how-to guides and general
information about administrating Alpine systems.
See <http://wiki.alpinelinux.org>.
You can setup the system with the command: setup-alpine

You may change this message by editing /etc/motd.

e79b18831557:~# 
```

As you can see the Hello message was returned by nginx from the index.html file provided inside the conf directory.

####Please check the conf directory for configuration files and pop me an email fssilv@ incase you need assistance.

Hope this helps.
