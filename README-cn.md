# lua-resty-yii

	一个基于OpenResty的仿Yii的web框架，通过本框架能够极大降低openresty的开发入门门槛。 [English](README.md)

# 系统要求

	安装OpenResty 1.0以上版本 https://openresty.org/en/download.html

# 快速开始
	
**Linux：修改runtime/start.sh中/usr/local/openresty/bin/openresty路径为您所安装的openresty路径**

	开始，bash中cd到当前目录，执行：runtime/start.sh
	停止，bash中cd到当前目录，执行：runtime/stop.sh

**Windows：修改runtime/start.bat中D:\openresty-1.11.2.2-win32\路径为您所安装的openresty路径**

    开始，双击：runtime/win-start.bat
    停止，双击：runtime/win-stop.bat

# 开发说明
## 应用结构
    目录及文件：
    |____index.lua                      #入口文件
    |____lua-releng                     #检查代码质量／是否使用了全局变量
    |____config                         #配置文件目录
    | |____db.lua                       #数据库配置
    | |____lang.lua                     #语言包配置
    | |____memcache.lua                 #memcache配置
    | |____session.lua                  #session配置
    | |____web.lua                      #网站基本信息配置
    |____controllers                    #controller目录
    | |____site.lua                     #前端页面
    |____models                         #models目录
    | |____LoginForm.lua                #登录逻辑处理类
    | |____Userinfo.lua                 #用户信息管理类
    |____runtime                        #Openresty运行目录
    | |____client_body_temp             #post上传的临时保存目录
    | |____fastcgi_temp                 #fastcig临时目录
    | |____logs                         #站点日志目录
    | | |____access.log                 #请求日志
    | | |____error.log                  #错误日志
    | | |____nginx.pid                  #nginx进程文件
    | |____nginx.conf                   #站点nginx配置文件
    | |____proxy_temp                   #proxy_temp
    | |____scgi_temp                    #scgi_temp 
    | |____start.sh                     #站点启动程序
    | |____stop.sh                      #站点停止程序
    | |____uwsgi_temp                   #uwsgi_temp
    |____vendor                         #框架及第三方类
    | |____ActiveRecord.lua             #数据库处理基类
    | |____Application.lua              #请求处理类
    | |____Controller.lua               #Controller基类
    | |____Files.lua                    #上传文件接收类
    | |____Memcache.lua                 #Memcache操作类
    | |____Model.lua                    #Model基类
    | |____Mysql.lua                    #Mysql操作类
    | |____Pager.lua                    #分页类
    | |____Query.lua                    #查询构建器
    | |____Request.lua                  #请求信息工具类
    | |____resty                        #第三方resty工具
    | | |____http.lua                   #http请求工具
    | | |____template.lua               #lua模版工具类
    | |____Session.lua                  #Session操作类
    | |____User.lua                     #用户信息操作类
    | |____Util.lua                     #基本工具类
    |____views                          #页面模版目录
    | |____layout                       #页面框架目录
    | | |____main.lua.html              #基本站点框架
    | |____site                         #站点页面目录
    | | |____error.lua.html             #错误信息页
    | | |____guide.lua.html             #开发说明页
    | | |____index.lua.html             #首页
    | | |____login.lua.html             #登录页
    |____web                            #静态资源目录
    | |____css                          #样式
    | | |____bootstrap-theme.css        #bootstrap
    | | |____bootstrap-theme.min.css    #bootstrap
    | | |____bootstrap.css              #bootstrap
    | | |____bootstrap.min.css          #bootstrap
    | | |____site.css                   #站点样式
    | |____js                           #javascript 
    | | |____bootstrap.js               #bootstrap
    | | |____bootstrap.min.js           #bootstrap
    | | |____jquery.js                  #jquery
    | | |____jquery.min.js              #jquery
    | | |____jquery.slim.js             #jquery
    | | |____jquery.slim.min.js         #jquery
    | |____favicon.ico                  #图标
    | |____robots.txt                   #robots.txt
## 运行机制概述
每一次应用开始处理 HTTP 请求时，它都会进行一个近似的流程。

- **用户提交指向 入口脚本 index.lua 的请求**
- **入口脚本会创建一个 应用(Application) 实例用于处理该请求，并加载配置。**
- **应用会通过 request（请求） 应用组件解析被请求的路由。**
- **应用创建一个 controller（控制器） 实例具体处理请求。**
- **执行controller中的before()方法进行请求过滤。**
- **如果执行before()返回true，则继续执行 action（动作），否则终止。**
- **动作会加载一个数据模型，一般是从数据库中加载。**
- **动作会渲染一个 View（视图），并为其提供所需的数据模型。**
- **渲染得到的结果会返回给 response（响应） 应用组件。**
- **响应组件会把渲染结果发回给用户的浏览器。**

## 调试模式：
- **访问 /lua/index 会使用lua_code_cache off的模式访问站点**
- **访问 /lua/{filepath} 可调试对应的lua脚本**

## 应用(Application)
每接收到一个 HTTP 请求，入口脚本 index.lua 会创建一个 应用(Application) 实例用于处理该请求
Application实例创建后，会保存覆盖全局变量ngx.ctx（此全局变量生命周期对应每个请求）
``` lua
ngx.ctx = require("vendor.Application"):new()
```
Application在创建时，会加载网站的基本配置及基本工具作为属性，如：
- **ngx.ctx.web 相当于 require("config.web"),          --站点配置信息表**
- **ngx.ctx.lang 相当于 require("config.lang"),        --语言包配置信息**
- **ngx.ctx.session 相当于 require("config.session"),  --站点Session类**
- **ngx.ctx.user 相当于 require("vendor.User"),        --站点用户工具类**
- **ngx.ctx.request 相当于 require("vendor.Request"),  --站点请求处理类**

在执行Application的new()时，会创建一个继承于Application的Controller实例，
因此ngx.ctx即是一个Application也是一个Controller实例，并且controller中也可以通过
self.web,self.lang,self.session.self.user.self.request直接引用以上配置及工具

**注意：在使用时，尽量少使用全局变量ngx.ctx，而应该通过函数传值的方式进行传递，能获得更快的运行速度**

## 控制器（Controllers）:
``` lua
local _M = require("vendor.Controller"):new{_VERSION='0.01'}    --生成Controller新实例

function _M:indexAction()   --动作方法名必须以name+Action组成
    if not self.user.isLogin then return self:loginAction() end     --使用用户信息类判断用户是否登录

    local Product = require('models.Product')               --使用Product数据表操作类
    local query = Product.find().where{'in','product_id',self.user.resource} --fin()方法生成新的查询器

    local page = Pager{                 --使用分页类
        pageSize = 8,                   --设置每页显示最多8条信息
        totalCount = query.count(),     --使用查询器查询符合条件的数据总条数
    }

    local list = query.orderBy('create_time desc').page(page).all() --使用查询器查询分页数据集
    
    return self:render('index',{
        page = page,
        list = list,
    })
end

retrun _M
```
**如果保存为controllers/filename.lua，则访问?act=filename.index时，会执行上面对应的indexAction()方法**

##模型（Models）:
模型是 MVC 模式中的一部分， 是代表业务数据、规则和逻辑的对象。
可通过继承 "vendor.Model" 或它的子类定义模型类， 基类"vendor.Model"支持许多实用的特性，如：
``` lua
local _M = require("vendor.Model"):new{_version='0.0.1'}    --生成Model新实例

local Userinfo = require('models.Userinfo')     --在Model里使用其他model

function _M.rules()     --方法rules添加数据校验规则
    return {
        {{'username','password','sacode'}, 'trim'}, --通过trim自动过滤输入
        {'username', 'required',message='请填写登录账号'}, --通过required规则设置必须填写
        --{'username', 'email'},            --如果需要用户名必须为email时设置
        {'password', 'required',message='请填写登录密码'},
        --使用自定义方法校验参数
        {'password','checkPass'}        --使用自定义checkPass方法进行校验
    }
end

function _M:checkPass(key)
    if self:hasErrors() then return end

    local user = Userinfo.getUserByName(self.username)
    if not user then 
        self:addError('username','账号不存在')
    elseif user.password ~= self.password then
        self:addError('password','密码错误')
    else
        self.userinfo = user
    end
end

function _M:login(user)
    if not self:validate() then return false end
    
    return user.login(self.userinfo, rememberMe and 3600*24*30 or 0)
end

return _M
```

在Controller里使用Model：
``` lua
--因为Model包含有数据，一定要调用new方法生成新实例，避免出现数据缓存问题
local model = require('models.LoginForm'):new() 

--通过model的load()方法，可自动装载数据
if model:load(self.request.post()) and model:login(self.user) then
    return self:goHome()
end
```

## 视图（Views）:
视图基于[lua-resty-template](https://github.com/bungle/lua-resty-template)实现

在视图中必须使用以下标签：
- **{{expression}}, 输出expression表达式，并用经过html格式化**
- **{*expression*}, 原样输出expression表达式的结果**
- **{% lua code %}, 执行Lua代码**
- **{# comments #}, 所有{＃和＃}之间的内容都被认为是注释掉的（即不输出或执行）**

与lua-resty-template的普通用法不同，所有视图文件，以lua文件的形式保存在views子目录下，文件名为*.lua.html
controller中的render方法渲染试图时，会以require的形式去获取视图内容

views/layout 目录存放框架视图，渲染视图时默认使用views/layout/main.lua.html，
controller中可通过layout属性设置使用不同的框架视图，如：
``` lua
local _M = require("vendor.Controller"):new{layout = 'manage'}
```
views下的其他子目录分别为不同功能模块对应的内容视图，所有页头，页尾，菜单等内容应在框架视图中实现
内容视图中不推荐使用{(template)}的形式来包含其他视图，因与默认渲染方式不同，会导致找不到文件等错误

controller在渲染视图时，会将所有application及controller的数据传递给视图，因此在视图中可以直接使用这些数据
如：{{lang.siteName}}可输出语言包中配置的网站名称

视图中可以通过设置context属性的方式用于内容视图跟框架视图之间传值，如设置：
{% context.title = '开发说明' %}
则可以在框架视图中{{title}}输出显示

## 请求处理
### 获取请求参数
``` lua
local request = require("vendor.Request")
--在Controller方法里可以直接通过self.request调用

local get = request.get()
--等价于php: $get = $_GET;

local id = request.get('id');   
--等价于php: $id = isset($_GET['id']) ? $_GET['id'] : null;

local id = request.get('id', 1)   
--等价于php: $id = isset($_GET['id']) ? $_GET['id'] : 1;

local post = request.post()
--等价于php: $post = $_POST;

local name = request.post('name')   
--等价于php: $name = isset($_POST['name']) ? $_POST['name'] : null;

local name = request.post('name', '')   
--等价于php: $name = isset($_POST['name']) ? $_POST['name'] : '';

local cookie = request.cookie()
--等价于php: $cookie = $_COOKIE;

local sso = request.cookie('sso')   
--等价于php: $sso = isset($_COOKIE['sso']) ? $_COOKIE['sso'] : null;

local sso = request.cookie('sso', '')   
--等价于php: $sso = isset($_COOKIE['sso']) ? $_COOKIE['sso'] : '';

--判断是否有上传文件
ngx.say(request.isPostFile())
--注意跟php不同的地方，如果有上传文件时，普通参数是无法通过request.post()方法获取到的
--建议上传文件时，普通参数通过GET传递

--接收上传文件
local file = require('vendor.Files')
local savename = path..filename

local ok,err = file.receive('upfile',savename)  --接收name为upfile的上传文件
if not ok  then  
    return {retcode=1,retmsg='接收文件失败，请重试:'..err}  
end
```
### 设置cookie：
``` lua
local util = require "vendor.Util"
util.set_cookie('abc','123')
util.set_cookie('def','456',3600)
util.set_cookie(name,value,expire,path,domain,secure,httponly)
```
### Session操作：
``` lua
ocal session = require "vendor.Session"
--在Controller方法里可以直接通过self.session调用
--session.start()   --启用session，会去设置一个_sessionid的cookie，此操作可以省略
--session.exptime = 1800 --修改session失效时间时，默认30分钟
--session.cache = ngx_shared['session_cache'] --默认使用ngx的缓存，对应runtime/nginx.conf里的lua_shared_dict配置项
--session.cache = require("vendor.Memcache"):new{host="127.0.0.1",port="11211"} --使用memcached缓存打开此配置

local sessions = session.get()
--等价于php: $sessions = $_SESSION;

local abc = session.get('abc')   
--等价于:local abc = session.abc 
--等价于:local abc = session['abc']
--等价于php: $abc = isset($_SESSION['abc']) ? $_SESSION['abc'] : null;

local abc = session.get('abc', '')   
--等价于php: $abc = isset($_SESSION['abc']) ? $_SESSION['abc'] : '';

--设置session值
session.set('abc','abc-value')
--等价于:session.abc = 'abc-value'
--等价于:session['abc'] = 'abc-value'
```

## 数据库操作（Working with Databases:

### 数据库访问 (DAO)
```lua
local db = require('vendor.Mysql'):new{
    host = "127.0.0.1",
    port = 3306,
    database = "mytest",
    user = "root",
    password = "",
    charset = "utf8", --建议配置Mysql的默认连接字符集为utf8，可去掉此配置项，此项配置会增加一次'SET NAMES utf8'的操作
}

--或者直接通过配置文件获得：
local db = require('config.db')

--执行sql：
local rows = db:query('select * from mytable')
ngx.say(#rows)
```
### 使用查询生成器 (Query Builder)
vendor.Query 封装了 vendor.Mysql，并提供快捷构建 安全 查询语句的方法，例如：
```lua
local db = require('config.db')
local query = require('vendor.Query')()
local rows = query.use(db).from('products').where({product_id=123}).all()
--相当于执行local rows = db:query("select * from products where product_id='123'")
ngx.say(query.get('sql')) --能获取到构造出的sql语句

--query.use()用于指定链接的数据库
query.use(require('config.db'))

--query.select()用于指定要查询的字段，不指定默认为select *
query.select({'id', 'email'})
--等同于：
query.select('id, email')

--query.from()用于指定要查询的表格 SELECT * FROM `user`
query.from('user')
```
**query.where()用于定义 SQL 语句当中的 WHERE 子句。 你可以使用如下三种格式来定义 WHERE 条件：**

- **字符串格式**，例如：'status=1' , 这个方法不会自动加引号或者转义。

- **哈希格式**，例如： {status=1,type=2}  ，这个方法将正确地为字段名加引号以及为取值范围转义

- **操作符格式**，例如：{'in', {'2012','2011'}}
    操作符格式允许你指定类程序风格的任意条件语句，如下所示：
    {操作符, 操作数1, 操作数2, ...}
    其中每个操作数可以是字符串格式、哈希格式或者嵌套的操作符格式， 而操作符可以是如下列表中的一个：

    操作符      | 用法
    ---------- | --------------------------------------------------------------
    **and** | 操作数会被 AND 关键字串联起来。例如，{'and', 'id=1', 'id=2'} 将会生成 id=1 AND id=2。如果操作数是一个数组，它也会按上述规则转换成字符串。例如，{'and', 'type=1', {'or', 'id=1', 'id=2'}} 将会生成 type=1 AND (id=1 OR id=2)。 这个方法不会自动加引号或者转义。
    **or** | 用法和 and 操作符类似。
    **between** | 第一个操作数为字段名称，第二个和第三个操作数代表的是这个字段 的取值范围。例如，{'between', 'id', 1, 10} 将会生成 id BETWEEN 1 AND 10。
    **not between** | 用法跟between类似
    **in** | 第一个操作数应为字段名称，第二个操作符既是一个数组。 例如， {'in', 'id', {1, 2, 3}} 将生成 `id` IN ('1', '2', '3') 。该方法将正确地为字段名加引号以及为取值范围转义
    **not in** | 用法和 in 操作符类似。

**query.orderBy() 方法是用来指定 SQL 语句当中的 ORDER BY 子句的。**
例如，要实现 ... ORDER BY create_time desc 可以：
``` lua
query.orderBy('create_time desc')
--等价于：query.orderBy{create_time=desc}
```

**query.groupBy() 方法是用来指定 SQL 语句当中的 GROUP BY 片断的。**
例如，要实现 ... GROUP BY `id`, `status`  可以：
``` lua
query.groupBy{'id', 'status'}
```

**query.limit() 和 query.offset() 是用来指定 SQL 语句当中 的 LIMIT 和 OFFSET 子句的。**
例如，要实现 ... LIMIT 10 OFFSET 20   等价于mysql的limit 20,10  可以：
``` lua
query.limit(10).offset(20)
```
如果你指定了一个无效的 limit 或者 offset（例如，一个负数），那么它将会被忽略掉。


**query.page() 能通过传递"vendor.Pager"对象，设置 LIMIT 和 OFFSET 达到分页查询的目的：**
``` lua
local page = require("vendor.Pager"){
    pageSize = 8,
    totalCount = 10,
}
query.page(page) --等价于：query.limit(page.limit).offset(page.offset)
```
####查询方法
vendor.Query 提供了一整套的用于不同查询目的的方法。
* query.all(): 将返回一个由行组成的数组。
* query.one(): 返回结果集的第一行。
* query.count(): 返回 COUNT 查询的结果。

例如：
``` lua
local db = require('config.db')
local query = require('vendor.Query'){}.use(db).from('products').where{product_id=123}
local rows = query.all()
local row = query.one()
local count = query.count()
```

其他方法：
* query.insert(): 插入数据。
* query.update(): 更新数据。
* query.delete(): 删除数据。
* query.save(): 新数据调用等价于query.insert()，查询结果集调用等价于query.update()。

例如：
``` lua
local db = require('config.db')
local data = {product_id=123,product_name='name123'}
local query = require('vendor.Query')(data).use(db).from('products')

--插入：
local row = query.insert()
--要获取新插入的数据的自增长id，请使用：
local id = row.get('insert_id') --等价于query.get('insert_id')

--更新：
row.product_name = 'name456'
row.update()    --或者query.update(row)

--删除：
row.delete()    --或者query.update(row)
```

###使用活动记录 (Active Record)
vendor.ActiveRecord 进一步封装了查询生成器vendor.Query
同时vendor.ActiveRecord继承于vendor.Model，能够使用模型对象的load(),rules(),hasErrors(),validate()等方法

使用示例：
``` lua
local Product = require('vendor.ActiveRecord'){
    --db = require('config.db'),    --可选属性，指定使用的数据库连接，未设置时默认使用'config.db'
    tableName = function()          --必须实现tableName方法，返回要操作的数据表名称
        return 'products'
    end
}

--插入数据：
local product = Product.new{
    product_id   = 123,
    product_name = 'name123',
}   --返回的对象支持使用vendor.Query方法
product.save()  --等价于product.insert()

--快速查找一行
local row = Product.findOne{product_id = 123}   --返回的对象支持使用vendor.Query方法

--快速查找多行
local rows = Product.findAll{user='creater'}    --返回的对象支持使用vendor.Query方法

--复杂查询
local query = Product.find().where{user='creater'}  --返回的对象支持使用vendor.Query方法
local page = Pager{
    pageSize = 8,
    totalCount = query.count(),
}
local list = query.orderBy('create_time desc').page(page).all()

--同样可以执行以下操作
query.insert()  --插入数据。
query.update()  --更新数据。
query.delete()  --删除数据。
```
建议每个数据表格在models目录下建立一个继承于'vendor.ActiveRecord'的操作类

###数据库安全问题
使用vendor.ActiveRecord 或 vendor.Query 自动生成查询语句
在构造sql语句的过程中，如果传递的参数是表格，构造器会进行转义操作，防止sql注入

但如果传递的是字符串，则不会进行转义操作，建议尽量少用，并能确保sql安全
可以通过 query.get('sql') 获取执行的sql语句

如果要进行转义，可使用util.mescape()方法
```lua
local util = require("vendor.Util")
value = util.mescape(value)
```

lua-resty-yii is available under the MIT license. See the [LICENSE file][1]
for more information.

[1]: ./LICENSE.txt



