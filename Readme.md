## 使用daocloud加速

toolbox采用的加速方法
注册登录daocloud，在dashboard里面点击`我的集群->自有集群->添加主机->windows/`

其他方法参考 <https://www.daocloud.io/mirror#accelerator-doc>

## windows-虚拟机-容器-共享文件夹

1、在virtualBox里面设置共享位置和名称，不要自动挂载

2、进入虚拟机中 docker-machine ssh default

3、创建一个文件夹 mkdir /home/share/

4、输入命令，建立主机与虚拟机的共享 sudo mount -t vboxsf share /home/share .这里的share是在虚拟机设置的时候取的名字，一般默认是share。

5、在主机中丢入文件，去虚拟机中及时查看。cd /home/share 然后 ls就能看到共享的文件。

6、虚拟机与容器之间建立文件共享，输入 docker run -d -p 3838:3838 -v /home/share:/root/share quantumobject/docker-shiny .

7、进入容器内的查看共享的文件 docker exec -it <CONTAINER ID> bash. 或者<name> docker exec -it backstabbing_goodall PS：通过docker ps来查看容器的ID和name。

8、验证：cd /srv/share 然后输入 ls，如果出现共享的文件就说明成功了 :)

若是Ubuntu的容器运行： docker run -it -v /home/share:/usr/share ubuntu:14.04 /bin/bash .


## docker 常用命令

###　查看本机的容器
`docker images`

### 启动一个Ubuntu容器，并将Ubuntu的shell作为入口
`docker run -it ubuntu:latest sh -c '/bin/bash'`

- `-i`表示这是一个交互容器，会将当前标准输入重新定向到容器中的标准输入，而不是终止程序
- `-t`指为这个容器分配一个终端

### 查看当前运行容器
`docker ps -a`

- 需要记住的只有两个，一个是容器的ID，一个是NAME

### 退出容器
`Ctrl +　D` ,需要重新启动可以使用
`docker start -i [NAME]`

- 每次执行`docker run`命令都会创建新的容器，建议一次创建后，使用`docker
  start/stop` 来启动和停用容器。

## 数据储存
docker运行期间，对文件系统的修改都是以增量的方式，并不是真正的对只读层数据信息的修改。每一次对运行容器的修改，都可以理解为夹心饼干又添加了一层奶油。当删除docker容器或者重启时，之前的更改都会丢失。

两种解决办法，第一是建立文件夹共享数据，第二种就是使用daocloud提供的volume服务。

### 虚拟机与容器共享文件夹
`docker run -it -v [host_dir]:[contain_dir] ubuntu:latest sh -c '/bin/bash' `

- 如果不添加[contain_dir]虚拟机的目录将会被挂在到 `/var/lib/docker/vfs/dir/...` 下面

- 容器和容器之间是可以共享数据卷的，我们可以单独创建一些容器，存放如数据库持久化存储、配置文件一类的东西，然而这些容器并不需要运行。`docker run --name dbdata ubuntu echo "Data container`."在需要使用这个数据容器的容器创建时 --volumes-from [容器名] 的方式来使用这个数据共享容器。

### 网络共享

`docker run -it -p 22 ubuntu sh -c '/bin/bash/'`

- `-p [主机端口]:[容器端口]`指定暴露容器端口在主机上

容器和容器之间想要网络通讯，可以直接使用 --link 参数将两个容器连接起来。例如 WordPress 容器对 some-mysql 的连接：

`docker run --name some-wordpress --link some-mysql:mysql -p 8080:80 -d wordpress`
### 环境变量

是docker能够使用一些外部参数，例如用来传递MySQL。环境变量通过
`-e`参数来向容器传递：

`docker run --name some-wordpress -e WORDPRESS_DB_HOST=192.168.1.2:3306 \
-e WORDPRESS_DB_USER=... -e WORDKPRESS_DB_PASSWORD=... -d wordpress 

## 创建镜像

Docker可以把自己开发的应用随同各种依赖环境一起打包、分发、运行。要创建一个新的docker镜像，通常基于一个已有的docker镜像来创建。Docker提供两种方式来创建镜像：把容器创建为一个新的镜像、使用Dockerfile创建镜像。


### 将容器创建为镜像

1.选择一个镜像作为基地

`docker run -it ubuntu:latest sh -c '/bin/bash'`

2.对容器进行修改

```shell
sudo apt-get intall r-base
...
# some other opereations
```

3.操作完成后Ctrl+D退出容器

```shell
docker ps -a

docker commit [ID] ubuntu:myubuntu

#镜像导出
docker save -o myubuntu.tar.gz ubuntu:myubuntu

#分发与迁移
docker import myubuntu.tar.gz
```

### Dockerfile创建镜像 Docker HUb

Dockerfile 是一个纯文本文件，它记载了从一个镜像创建另一个新镜像的步骤。撰写好 Dockerfile 文件之后，我们就可以轻而易举的使用 `docker build` 命令来创建镜像了。

<table><tbody><tr><th>命令</th>
<th>参数</th>
<th>说明</th>
</tr><tr><td>#</td>
<td>-</td>
<td>注释说明</td>
</tr><tr><td>FROM</td>
<td>&lt;image&gt;[:&lt;tag&gt;]</td>
<td>从一个已有镜像创建，例如ubuntu:latest</td>
</tr><tr><td>MAINTAINER</td>
<td>Author &lt;some-one@example.com&gt;</td>
<td>镜像作者名字，如Max Liu &lt;some-one@example.com&gt;</td>
</tr><tr><td>RUN</td>
<td>&lt;cmd&gt;或者['cmd1', 'cmd2'…]</td>
<td>在镜像创建用的临时容器里执行单行命令</td>
</tr><tr><td>ADD</td>
<td>&lt;src&gt; &lt;dest&gt;</td>
<td>将本地的&lt;src&gt;添加到镜像容器中的&lt;dest&gt;位置</td>
</tr><tr><td>VOLUME</td>
<td>&lt;path&gt;或者['/var', 'home']</td>
<td>将指定的路径挂载为数据卷</td>
</tr><tr><td>EXPOSE</td>
<td>&lt;port&gt; [&lt;port&gt;...]</td>
<td>将指定的端口暴露给主机</td>
</tr><tr><td>ENV</td>
<td>&lt;key&gt; &lt;value&gt; 或者 &lt;key&gt; = &lt;value&gt;</td>
<td>指定环境变量值</td>
</tr><tr><td>CMD</td>
<td>["executable","param1","param2"]</td>
<td>容器启动时默认执行的命令。注意一个Dockerfile中只有最后一个CMD生效。</td>
</tr><tr><td>ENTRYPOINT</td>
<td>["executable", "param1", "param2"]</td>
<td>容器的进入点</td>
</tr></tbody></table>

例子：

```shell
# This is a comment
FROM ubuntu:14.04
MAINTAINER Kate Smith <ksmith@example.com>
RUN apt-get update && apt-get install -y ruby ruby-dev
RUN gem install sinatra
```

这里其他命令都比较好理解，唯独 CMD 和 ENTRYPOINT 我需要特殊说明一下。CMD 命令可用指定 Docker 容器启动时默认的命令，例如我们上面例子提到的 docker run -it ubuntu:latest sh -c '/bin/bash'。其中 sh -c '/bin/bash' 就是通过手工指定传入的 CMD。如果我们不加这个参数，那么容器将会默认使用 CMD 指定的命令启动。ENTRYPOINT 是什么呢？从字面看是进入点。没错，它就是进入点。ENTRYPOINT 用来指定特定的可执行文件、Shell 脚本，并把启动参数或 CMD 指定的默认值，当作附加参数传递给 ENTRYPOINT。

```shell
ENTRYPOINT ['/usr/bin/mysql']
CMD ['-h 192.168.100.128', '-p']
```
假设这个镜像内已经准备好了 mysql-client，那么通过这个镜像，不加任何额外参数启动容器，将会给我们一个 mysql 的控制台，默认连接到192.168.100.128 这个主机。然而我们也可以通过指定参数，来连接别的主机。但是不管无论如何，我们都无法启动一个除了 mysql 客户端以外的程序。因为这个容器的 ENTRYPOINT 就限定了我们只能在 mysql 这个客户端内做事情。这下是不是明白了~

在准备好 Dockerfile 之后，我们就可以创建镜像了：

`docker build -t starlight36/simpleoa`


