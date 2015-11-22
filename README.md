# luvit-request
Another light-weight progressive request library crafted for flexibility, readability, and a low learning curve.

# Install

## Via [lit](https://github.com/luvit/lit/)
```bash
lit install cyrilis/request
```

# Getting start
```lua
local request  = require("./request")
request.post("https://api.abc.com/v1/test")
:set("Content-Type", "application/x-www-form-urlencoded")
:send({ foo = "bar" })
:auth("user", "password")
:done( function(err, res) 
	if err then
		p(err)
	else
		p(res.body)
	end
end)
```

# Usage
### request:new(options)
	init a request instance with `:new` method or `:get`, `:post`, `:put`, ":delete"

```lua
local url = "http://example.com/"
local req = request:new({url = url, method = "GET"})

-- `local req = request:get(url)` 
-- `local req = request:post(url)` 
-- `local req = request:put(url)` 
-- `local req = request:delete(url)`
```

###`req:set(key, value)`
	Set request headers

###`req:type(type)`
	Set request headers for "Content-Type"
	type: ["html", "json", "xml", "urlencoded", "form", "form-data"]

###`req:accept(type)`
	Set request headers for "Accept"

###`req:query(queryTable)`
	Pass query parameter to request, queryTable is a key-value table, `req:query({page = "2"})`

###`req:send(dataTable)`
	pass post data to request, dataTable is a key-value table, `req:send({title = "Hello world!"})`

###`:auth(username, password)`
	Pass `username` and `password` for basic auth.

###`:done(callback)`
	Callback after request is done and got the response content.  two params will pass to callback function: `error` and `res`
	
	`res` is a httpResponse.
	The `res.text` property contains the unparsed response body string. This property is always present for the client API,
	When a parser is defined for the Content-Type, it is parsed, which by default includes "application/json" and "application/x-www-form-urlencoded". The parsed object is then available via `res.body`.

### Error handling
	req:on("error", handler)


# Simple Usage

> Code in file `mailgun.lua`:

```lua
--
-- Created by: Cyril Hou.
-- Created at: 15/6/24 下午6:22
-- Email: houshoushuai@gmail.com
--

local request  = require("./request")

Mail = require("core").Object:extend()

function Mail:initialize(option)
    if not(option) then return false end
    self.api  = option.api
    self.domain = option.domain
    self.defaultFrom = option.from
end

function Mail:send (opt, callback)
    request.post("https://api.mailgun.net/v3/"..self.domain.."/messages")
    :set("Content-Type", "application/x-www-form-urlencoded; charset=UTF-8")
    :send({
        from = opt.from or self.defaultFrom,
        to   = opt.to,
        subject = opt.subject,
        text = opt.text,
        html = opt.html
    })
    :auth("api", self.api)
    :done(callback)
end

module.exports = Mail

```

Then you can send email via:

```lua
local mail = require("./mailgun"):new({
    api = "key-xxxx-xxxxx-xxxxxxxxxxxxx",
    domain = "example.com"
})

mail:send({
    from = "hello@example.com",
    to = "me@cyrilis.com",
    subject = "Hello from Luvit Request",
    html = "<h1>Hello World!</h1>",
    text = "Hello World!"
}, function(err, res)
    p(err, res.body)
end)
```

# Licence
MIT