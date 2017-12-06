# Lua-resty-yii

A network framework based on OpenResty Imitation Yii, through this framework can greatly reduce the entry threshold of openresty development. [中文](README-cn.md)

#System Requirements

Install OpenResty 1.0+ https://openresty.org/en/download.html

# Quick start

**Linux OS: Modify the /usr/local/openresty/bin/openresty path in your runtime/start.sh to your openresty path**

At the beginning, bash CD to the current directory, execute: runtime/start.sh
Stop, celebrate the CD to the current directory, execute: runtime/stop.sh

**Windows: Modify runtime/start.bat in d:\openresty-1.11.2.2--Win32\ path for your installed openresty path**

    Start, double-click: runtime/win-start.bat
    Stop, double-click: runtime/win-stop.bat

# Development instructions

## application structure

    Directory and documents:
    | ____ index.lua # entry file
    | ____ lua-releng # Check code quality / whether global variables are used
    | ____ config # configuration file directory
    | | ____ db.lua # database configuration
    | | ____ lang.lua # language pack configuration
    | | ____ memcache.lua # memcache configuration
    | | ____ session.lua #session configuration
    | ____ web.lua # Website basic information configuration
    | ____ Controller #controller directory
    | | ____ site.lua # front page
    | ____ Model #models directory
    | | ____ LoginForm.lua # Login logical processing class
    | ____ Userinfo.lua # User Information Management Class
    | ____ runtime # Openresty run directory
    | | ____ client_body_temp #post Upload temporary save directory
    | ____ fastcgi_temp #fastcig temporary directory
    | ____ Logs # The site log directory
    | | | ____ access.log # Request Log
    | | | ____ error.log # error log
    | | | ____ nginx.pid #nginx Process File
    | | ____ nginx.conf # Site nginx configuration file
    | | ____ proxy_temp #proxy_temp
    | | ____ scgi_temp #scgi_temp
    | ____ start.sh # Site Launcher
    | | ____ stop.sh # Stop the program
    | | ____ uwsgi_temp #uwsgi_temp
    | ____ vendor # framework and third-party classes
    | ____ ActiveRecord.lua # database processing base class
    | ____ Application.lua # Request processing class
    | | ____ Controller.lua #Controller base class
    | ____ Files.lua # Upload file receiving class
    | | ____ Memcache.lua #Memcache operation class
    | ____ Model.lua #Model base class
    | | ____ Mysql.lua #Mysql operation class
    | ____ Pager.lua # Paging classes
    | | ____ Query.lua # Query builder
    | ____ Request.lua # request information tool class
    | ____ resty # third-party resty tools
    | | | ____ http.lua #http Request Tool
    | | | ____ template.lua #lua Template Tools
    | | ____ Session.lua #Session action class
    | | ____ User.lua # user information action class
    | ____ Util.lua # Basic Tools
    | ____ views # page template directory
    | ____ layout # page frame directory
    | | | ____ main.lua.html # basic site framework
    | ____ site # site page directory
    | | | ____ error.lua.html # error message page
    | | | ____ guide.lua.html # Development Notes page
    | | | ____ index.lua.html # Home
    | | | ____ login.lua.html # Login page
    | ____ web # Static Resource Directory
    | | ____ css # style
    | | | ____ bootstrap-theme.css #bootstrap
    | | | ____ bootstrap-theme.min.css #bootstrap
    | | | ____ bootstrap.css #bootstrap
    | | | ____ bootstrap.min.css #bootstrap
    | | | ____ site.css # site style
    | | ____ js # javascript
    | | | ____ bootstrap.js #bootstrap
    | | | ____ bootstrap.min.js #bootstrap
    | | | ____ jquery.js #jquery
    | | | ____ jquery.min.js #jquery
    | | | ____ jquery.slim.js #jquery
    | | | ____ jquery.slim.min.js #jquery
    | | ____ favicon.ico # icon
    | | ____ robots.txt # robots.txt

## Overview of the operating mechanism

Every time an application starts to process an HTTP request, it performs an approximate process.

--**User submits request for entry script index.lua**
--**The entry script creates an Application instance to handle the request and loads the configuration**
--**The application parses the requested route through the request application component.**
--**Application to create a Controller instance to handle the request.**
--**Execute the before() method in the controller for request filtering.**
--**Continue with action if before() returns true, otherwise terminate.**
--**Action will load a data model, usually loaded from the database.**
--**The action renders a View and provides it with the required data model.**
--**Rendered results are returned to the response (response) application component.**
--**The response component sends the result back to the user's browser.**

## Debug mode:

--**Access / lua / index will use lua_code_cache off mode to access the site**
--**Visit / lua / {filepath} Can debug the corresponding lua script**

## Application

Each time an HTTP request is received, the entry script index.lua creates an instance of the application for processing the request
After the application instance is created, the global variable ngx.ctx is overwritten (for each request corresponding to the life cycle of the global variable)

```lua
ngx.ctx = require ("vendor.Application"): new()
```

When the application is created, it will load the basic configuration and basic tools of the website as attributes, such as:

--**ngx.ctx.web is equivalent to require ("config.web"), --Site Configuration Information Table**
--**ngx.ctx.lang is equivalent to require ("config.lang"), --language package configuration information**
--**ngx.ctx.session is equivalent to require ("config.session"), --site session class**
--**ngx.ctx.user is equivalent to require ("vendor.User"), --Site User Tools**
--**ngx.ctx.request is equivalent to require ("vendor.Request"), --Site Request Processing**

When executing a new() application, a controller instance is inherited from the application,
So ngx.ctx is an application that is also a controller instance and is also available in the controller
self.web, self.lang, self.session.self.user.self.request Direct reference to the above configuration and tools

** Note: When using, minimize the use of the global variable ngx.ctx, but should pass the value of the function pass, get faster speed **

## Controller (Controller):

``` lua
local _M = require("vendor.Controller"):new{_VERSION='0.01'}    --Generate a new Controller instance

function _M:indexAction()   --The action method name must be name + Action
    if not self.user.isLogin then return self:loginAction() end     --use the user information to determine whether the user login

    local Product = require('models.Product')               --Uses the Product Datasheet operation class
    local query = Product.find().where{'in','product_id',self.user.resource} --The fin() method generates a new querier

    local page = Pager{                 
        pageSize = 8,                   
        totalCount = query.count(),     
    }

    local list = query.orderBy('create_time desc').page(page).all()
    
    return self:render('index',{
        page = page,
        list = list,
    })
end

retrun _M
```

** If saved as controller / filename.lua then access? ACT = filename.index, it will perform the above corresponding indexAction() method **

## model (model):
The model is part of the MVC pattern and represents the business data, rules, and logic objects.
The model class can be defined by inheriting "vendor.Model" or its subclasses. The base class "vendor.Model" supports many useful features such as:

```lua
local _M = require ("vendor.Model"): new {_version = '0.0.1'} --Generate a new instance of Model

Local Userinfo = require ('models.Userinfo') --Use other models in the Model

Function _M.rules() --Method rules Add data validation rules
Return {
{{'Username', 'password', 'sacode'}, 'trim'}, --Filter input automatically through trim
{'Username', 'required', message = 'Please fill in the login account'}, --Required by the required rules set
--{'username', 'email'}, --if required username must be set for email time
{'Password', 'required', message = 'Please fill in the login password'},
--Use custom methods to verify the parameters
{'Password', 'checkPass'} --Validate using the custom checkPass method
}
End

Function _M: checkPass (key)
If self: hasErrors() then return to the end

Local user = Userinfo.getUserByName (self.username)
If not user then
From: addError ('username', 'account does not exist')
Elseif user.password ~ ​​= self.password Then
From: addError ('password', 'wrong password')
Other
Self.userinfo = user
End
End

Function _M: login (user)
If not self: validate() then returns false
The company is located in:
Return user.login (self.userinfo, rememberMe and 3600 * 24 * 30 or 0)
End

return _M
```

Use in controller Model:

```lua
 --Because the model contains data, be sure to call the new method to generate a new instance, to avoid data caching problems
local model = require ('models.LoginForm'): new()

 --Load data automatically through model load() method
If model: load (self.request.post()) and model: login (self.user) then
Back to myself: goHome()
End
```

## view (view):
The view is based on the [LUA-resty template (https://github.com/bungle/lua-resty-template)

The following tags must be used in the view:
 --**{{expression}}, output the expression, and html formatted**
 --**{* expression *}, the result of the expression expression is output as it is**
 --**{% lua code%}, execute Lua code**
 --**{# comments #} All content between {# and #} is considered commented (ie not output or executed)**

Unlike the normal usage of the LUA-resty template, all view files are saved as LUA files in the sub-directory with the filename * .lua.html
Rendering methods in your controller When you try to render, you get the content of the view as you need it

views / layout directory storage frame view, rendering view default views / layout / main.lua.html,
Controller can be set by the layout of the property to use a different frame view, such as:
lua
Local_M = require ("vendor.Controller"): new {layout = 'manage'}
```
Under the views of the other sub-directories for different functional modules corresponding to the content view, all page headers, page footers, menus and other content should be implemented in the frame view
Other views are deprecated in the content view as {(templates)}, which can cause errors such as missing files due to different default renderings

When the controller renders the view, it passes all application and controller data to the view so that it can be used directly in the view
Such as: {{lang.siteName}} output the name of the site configured in the language pack

In the view, you can set a contextual property to pass values ​​between the content view and the frame view, such as setting:
{% Context.title = 'Development Description'%}
You can display the {{title}} output in the frame view

## request processing
### Get request parameters
lua
Local request = require ("vendor.Request")
--In the controller method can be obtained directly through self.request call

local get = request.get()
--equivalent to php: $get = $_GET;

Local id = request.get ('id');
--equivalent to php: $id = isset ($_ GET ['id'])? $_GET ['id']: null;

Local id = request.get ('id', 1)
--equivalent to php: $id = isset ($_ GET ['id'])? $_GET ['id']: 1;

Local post = request.post()
--equivalent to php: $post = $_POST;

Local name = request.post ('name')
--equivalent to php: $name = isset ($_ POST ['name'])? $_POST ['name']: null;

Local name = request.post ('name', '')
--equivalent to php: $name = isset ($_ POST ['name'])? $_POST ['name']: '';

Local cookie = request.cookie()
--equivalent to php: $cookie = $_COOKIE;

Local sso = request.cookie ('sso')
--equivalent to php: $sso = isset ($_ COOKIE ['sso'])? $_COOKIE ['sso']: null;

Local sso = request.cookie ('sso', '')
--equivalent to php: $sso = isset ($_ COOKIE ['sso'])? $_COOKIE ['sso']: '';

 --Determine whether there is an upload file
ngx.say (request.isPostFile())
 --Note different places with PHP, if there is an upload file, the normal parameters can not be obtained through the request.post() method
 --Recommended to upload files, common parameters passed by GET

 --Receive uploaded files
Local file = required ('vendor.Files')
Local savename = path .. filename

Local ok, err = file.receive ('upfile', savename) --receive upload file named upfile
If not
Return {retcode = 1, retmsg = 'Receive file failed, please try again:' .. err}
End
```
### Set cookie:
```lua
Local util = needs "vendor.Util"
util.set_cookie ('ABC', '123')
util.set_cookie ('HD', '456', 3600)
util.set_cookie (Name, Value, Expired, Path, Domain, Security, Http Only)
```

### Session operation:
```lua
ocal session = require "vendor.Session"
--In the Controller method can be called directly through self.session
--session.start() --Enable session, will set a _sessionid cookie, this operation can be omitted
--session.exptime = 1800 --The default session time is 30 minutes
--session.cache = ngx_shared ['session_cache'] --By default, ngx's cache corresponds to the lua_shared_dict configuration in runtime / nginx.conf
--session.cache = require ("vendor.Memcache"): new {host = "127.0.0.1", port = "11211"} --Open this configuration with memcached cache

local sessions = session.get()
--equivalent to php: $ sessions = $ _SESSION;

local abc = session.get ('abc')
--equivalent to: local abc = session.abc
--equivalent to: local abc = session ['abc']
--equivalent to php: $ abc = isset ($ _ SESSION ['abc'])? $ _SESSION ['abc']: null;

local abc = session.get ('abc', '')
--equivalent to php: $ abc = isset ($ _ SESSION ['abc'])? $ _SESSION ['abc']: '';

--set the session value
session.set ('abc', 'abc-value')
--equivalent to: session.abc = 'abc-value'
--equivalent to: session ['abc'] = 'abc-value'
```

## database operation (Working with Databases:

### Database Access (DAO)
```lua
local db = require ('vendor.Mysql'): new {
    host = "127.0.0.1",
    port = 3306,
    database = "mytest",
    user = "root",
    password = "",
    charset = "utf8", --It is recommended to configure Mysql default connection character set utf8, you can get rid of this configuration item, this configuration will add a 'SET NAMES utf8' operation
}

--Or get it directly from the configuration file:
local db = require ('config.db')

--Execute sql:
local rows = db: query ('select * from mytable')
ngx.say (#rows)
```
### Using Query Builder (Query Builder)
vendor.Query encapsulates vendor.Mysql and provides a quick way to build a secure query, for example:
```lua
local db = require ('config.db')
local query = require ('vendor.Query')()
local rows = query.use (db) .from ('products'). where ({product_id = 123}). all()
--equivalent to executing local rows = db: query ("select * from products where product_id = '123'")
ngx.say (query.get ('sql')) --can get to construct the sql statement

--query.use() Used to specify the linked database
query.use (require ('config.db'))

--query.select() is used to specify the field to query, do not specify the default is select *
query.select ({'id', 'email'})
--Equivalent to:
query.select ('id, email')

--query.from() is used to specify the table to be queried SELECT * FROM `user`
query.from ('user')
```
query.where() is used to define the WHERE clause in the SQL statement. You can use the following three formats to define the WHERE condition: **

--** string format **, for example: 'status = 1', this method does not automatically add quotes or escapes.

--** hash format **, for example: {status = 1, type = 2} This method will correctly quote the field name and escape the range of values

--** operator format **, for example: {'in', {'2012', '2011'}}
    The operator format allows you to specify any conditional statement of the class style, as follows:
    {Operator, operand1, operand2, ...}
    Each of these operands can be a string format, a hash format, or a nested operator format, and the operator can be one of the following:

    Operator | usage
    --------| --------------------------------------------
    ** and ** | Operands are concatenated with the AND keyword. For example, {'and', 'id = 1', 'id = 2'} will generate id = 1 AND id = 2. If the operand is an array, it is also converted to a string as described above. For example, {'and', 'type = 1', {'or', 'id = 1', 'id = 2'}} will generate type = 1 AND (id = 1 OR id = 2). This method does not automatically add quotes or escapes.
    ** or ** | Similar to the and operator.
    ** between ** | The first operand is the name of the field, and the second and third represent the range of values ​​for this field. For example, {'between', 'id', 1, 10} will generate id BETWEEN 1 AND 10.
    ** not between ** | usage is similar to between
    ** in ** | The first operand should be the field name, and the second operator is both an array. For example, {'in', 'id', {1, 2, 3}} will generate `id` IN ('1', '2', '3'). This method will correctly quote the field name and escape the value range
    ** not in ** | Usage is similar to in operator.

The query.orderBy() method is used to specify the ORDER BY clause in the SQL statement. **
For example, to achieve ... ORDER BY create_time desc can:
```lua
query.orderBy ('create_time desc')
--equivalent to: query.orderBy {create_time = desc}
```

The query.groupBy() method is used to specify the GROUP BY fragment in the SQL statement. **
For example, to achieve ... GROUP BY `id`,` status` could:
```lua
query.groupBy {'id', 'status'}
```

The query.limit() and query.offset() are used to specify the LIMIT and OFFSET clauses in SQL statements. **
For example, to achieve ... LIMIT 10 OFFSET 20 Equivalent to mysql limit 20,10 Can:
```lua
query.limit (10) .offset (20)
```
If you specify an invalid limit or offset (for example, a negative number), it will be ignored.


** query.page() can set LIMIT and OFFSET for paging query by passing "vendor.Pager" object: **
```lua
local page = require ("vendor.Pager") {
    pageSize = 8,
    totalCount = 10,
}
query.page (page) --Equivalent to: query.limit (page.limit) .offset (page.offset)
```
#### Query method
vendor.Query provides a complete set of methods for different query purposes.
query.all(): will return an array of rows.
query.one(): returns the first row of the result set.
query.count(): returns the result of a COUNT query.

E.g:
```lua
local db = require ('config.db')
local query = require ('vendor.Query') {}. use (db) .from ('products'). where {product_id = 123}
local rows = query.all()
local row = query.one()
local count = query.count()
```

Other methods:
query.insert(): Insert data.
query.update(): update the data.
query.delete(): delete data.
query.save(): The new data call is equivalent to query.insert() and the query result set call is equivalent to query.update().

E.g:
```lua
local db = require ('config.db')
local data = {product_id = 123, product_name = 'name123'}
local query = require ('vendor.Query') (data) .use (db) .from ('products')

--insert:
local row = query.insert()
--To get the self-growth id of newly inserted data, use:
local id = row.get ('insert_id') --equivalent to query.get ('insert_id')

--Updated:
row.product_name = 'name456'
row.update() --or query.update (row)

--delete:
row.delete() --or query.update (row)
```

### Active Record
vendor.ActiveRecord further encapsulates the query generator vendor.Query
At the same time, vendor.ActiveRecord inherits from vendor.Model and can use the load(), rules(), hasErrors(), validate() methods of the model object

Example of use
```lua
local Product = require ('vendor.ActiveRecord') {
    --db = require ('config.db'), --optional attribute, specify the database connection to use, default 'config.db'
    tableName = function() --The tableName method must be implemented to return the name of the data table to manipulate
        return 'products'
    end
}

--insert data:
local product = Product.new {
    product_id = 123,
    product_name = 'name123',
} --The returned object supports using the vendor.Query method
product.save() --equivalent to product.insert()

--Quickly find a line
local row = Product.findOne {product_id = 123} --The returned object supports using the vendor.Query method

--Quickly find multiple lines
local rows = Product.findAll {user = 'creater'} --The returned object supports using the vendor.Query method

--Complex queries
local query = Product.find(). where {user = 'creater'} --The returned object supports using the vendor.Query method
local page = Pager {
    pageSize = 8,
    totalCount = query.count(),
}
local list = query.orderBy ('create_time desc'). page (page) .all()

--You can also do the following
query.insert() --insert data.
query.update() --Update the data.
query.delete() --delete the data.
```
It is recommended that each data table be created in the models directory as an operation class that inherits from 'vendor.ActiveRecord'

### Database security issues
Use vendor.ActiveRecord or vendor.Query to automatically generate query statements
Sql statement in the construction process, if the parameters passed is a form, the constructor will be escaped operation to prevent sql injection

But if the string is passed, it will not escape operation, it is recommended to minimize the use of, and to ensure that sql security
Query.get ('sql') can be obtained by the implementation of the sql statement

If you want to escape, you can use the util.mescape() method
```lua
local util = require ("vendor.Util")
value = util.mescape (value)
```

lua-resty-yii is available under the MIT license. See the [LICENSE file][1]
for more information.

[1]: ./LICENSE.txt