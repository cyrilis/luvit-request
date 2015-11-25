--
-- Created by: Cyril.
-- Created at: 15/6/23 下午4:04
-- Email: houshoushuai@gmail.com
--

http = require("http")
https = require("https")
JSON = require("json")
string = require("string")

local qs = require('querystring')

local base64_table = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
local sub  = string.sub
local gsub = string.gsub
local byte = string.byte
local find = string.find
local base64 = function(data)
    return ((gsub(data, '.', function(x)
        local r, b = '', byte(x)
        for i = 8, 1, -1 do
            r = r .. (b % 2 ^ i - b % 2 ^ (i - 1) > 0 and '1' or '0')
        end
        return r
    end) .. '0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if #x < 6 then
            return ''
        end
        local c = 0
        for i = 1, 6 do
            c = c + (sub(x, i, i) == '1' and 2 ^ (6 - i) or 0)
        end
        return sub(base64_table, c + 1, c + 1)
    end) .. ({
        '',
        '==',
        '='
    })[#data % 3 + 1])
end

_G.map = function(t, f)
    local r = { }
    for k, v in pairs(t) do
        table.insert(r, f(k, v, t))
    end
    return r
end

local split = function(str, sep, nmax)
    if sep == nil then
        sep = '%s+'
    end
    local r = { }
    if #str <= 0 then
        return r
    end
    local plain = false
    nmax = nmax or -1
    local nf = 1
    local ns = 1
    local nfr, nl = find(str, sep, ns, plain)
    while nfr and nmax ~= 0 do
        r[nf] = sub(str, ns, nfr - 1)
        nf = nf + 1
        ns = nl + 1
        nmax = nmax - 1
        nfr, nl = find(str, sep, ns, plain)
    end
    r[nf] = sub(str, ns)
    return r
end


BaseTypes = {
    ["html"] = 'text/html',
    ["json"] = 'application/json',
    ["xml"] = 'application/xml',
    ["urlencoded"] = 'application/x-www-form-urlencoded',
    ['form'] = 'application/x-www-form-urlencoded',
    ['form-data'] = 'application/x-www-form-urlencoded'
};

Emitter = require('core').Emitter
Request = Emitter:extend()
function Request:initialize (options, callback)
    self.options = options or {}
    self.callback = callback or function() end
    local URL = require("url").parse(self.options.url)
    local defaultPort = 80
    self._request = http.request
    if URL.protocol == "https" then
        defaultPort = 443
        self._request = https.request
    end
    self.option = {
        protocol = URL.protocol or "http",
        host =  URL.hostname,
        port = URL.port or defaultPort,
        path = URL.path,
        method = self.options.method and self.options.method:upper() or "GET",
        headers = self.options.headers or {}
    }

    table.insert(self.option.headers, {"connection", "keep-alive"})

    if URL.auth then
        local user, pass = URL.auth:match("([^:]+):([^:]+)")
        return self:auth(user, pass)
    end
    return self
end

function Request:set(key, value)
    table.insert(self.option.headers, {key, value})
    return self
end

function Request:type(type)
    self:set("Content-Type", BaseTypes[type] or type)
    return self
end

function Request:accept(type)
    self:set("Accept", BaseTypes[type] or type)
    return self
end

function Request:query(query)
    local queryArray = map(query, function(key, value)
        return key .. "=" .. value
    end)
    local querystring = table.concat(queryArray, "&")
    local url = require("url").parse(self.option.path)
    local oldQuery = url.query
    if not(oldQuery) then
        oldQuery = ""
    else
        oldQuery = oldQuery .. "&"
    end
    self.option.path = url.pathname .. "?" .. oldQuery .. querystring
    return self
end

function Request:send(data)
--    self.option.headers["Content-Type"] = "application/x-www-form-urlencoded"
    if self.option.method == "GET" or self.option.method == "HEAD" then
        return false
    end
    self.data = data
    self.postData = qs.stringify(self.data)

    table.insert(self.option.headers, {"Content-Length", #self.postData})

    --    if ('HEAD' != options.method) req.setHeader('Accept-Encoding', 'gzip, deflate');
    return self
end

function Request:auth(user, pass)
    local str = base64(user .. ":" .. pass)
    table.insert(self.option.headers, {"Authorization", "Basic "..str})
    return self
end

function Request:pipe(fd, callback)
    self.callback = callback or self.callback
    if self._isCalled then return false end
    self.client = self._request(self.option, function(res)
        self._isCalled = true
        res:pipe(fd)
        res:on("end", function()
            self.callback()
        end)
    end)

    self.client:on("error", function(error)
        self.callback(error)
        self._isCalled = true
        self:emit("error", error)
    end)
    if self.option.method ~= "GET" and self.option.method ~= "HEAD" then
        if self.postData then self.client:write(self.postData) end
    end
    self.client:done();
    return self
end

function Request:done(callback)
    self.callback = callback or self.callback
    if self._isCalled then return false end
    self.client = self._request(self.option, function(res)
        local data = ""
        res:on("data", function(chunk)
            data = data .. chunk
        end)
        res:on("end", function(chunk)
            chunk  = chunk or ""
            data = data .. chunk
            local bodyObj
            local contentType = split(res.headers["Content-Type"], ";")[1]
            if contentType == BaseTypes['json'] then
                bodyObj = JSON.parse(data)
            elseif contentType == BaseTypes['form'] then
                bodyObj = qs.parse(data)
            end
            res.body = bodyObj
            res.text = data
            self.callback(err, res)
            self._isCalled = true
        end)
    end)

    self.client:on("error", function(error)
        self.callback(error)
        self._isCalled = true
        self:emit("error", error)
    end)

    if self.option.method ~= "GET" and self.option.method ~= "HEAD" then
        if self.postData then self.client:write(self.postData) end
    end

    self.client:done();
    return self
end

module.exports = {
    name = "cyrilis/request",
    version = "0.0.2",
    new = Request.new,
    get =  function(url)
        return Request:new({url = url, method = "GET"})
    end,
    post = function(url)
        return Request:new({url = url, method = "POST"})
    end,
    put = function(url)
        return Request:new({url = url, method = "PUT"})
    end,
    delete = function(url)
        return Request:new({url = url, method = "DELETE"})
    end
}
