fs = require 'fs'

urlParse = require('url').parse
Stream = require('stream').Stream
pathJoin = require('path').join
Vfs = require('vfs-local')

errors = require '../commons/errors'
multipart = require('../commons/multipart')
encoder = require './encoder'

errorHandler = (req, res, err, code) ->

  res.statusCode = code if code
  switch err.code
    when "EBADREQUEST" then res.statusCode = 400
    when "EACCES" then res.statusCode = 403
    when "ENOENT" then res.statusCode = 404
    when "ENOTREADY" then res.statusCode = 503
    when "EISDIR" then res.statusCode = 503
    else res.statusCode = 500
    
  message = (err.stack or err) + "\n";
  res.setHeader("Content-Type", "text/plain")
  res.setHeader("Content-Length", Buffer.byteLength(message))
  res.end(message)

module.exports.setup = (app) ->
  app.all /^(\/files(\/.*))$/, (req, res) ->
    
    path = unescape(req.params[1])
    base_path = unescape(req.params[0])
    #Instead of using next for errors, we send a custom response here.
    abort = (err, code) ->
      return errorHandler(req, res, err, code)
  
    vfs = Vfs
      root: process.cwd() + "/specs/"
    
    fileGet = (path,req,res) ->

      options = {}
      options.etag = req.headers["if-none-match"] if req.headers.hasOwnProperty("if-none-match")

      if req.headers.range? 
        range = options.range = {}
        p = req.headers.range.indexOf('=')
      
        parts = req.headers.range.substr(p + 1).split('-')
        if parts[0].length 
          range.start = parseInt(parts[0], 10)
        if parts[1].length
          range.end = parseInt(parts[1], 10)
        range.etag = req.headers["if-range"] if req.headers.hasOwnProperty('if-range')
      
      onGet = (err, meta)->
        
        res.setHeader "Date", (new Date()).toUTCString()
        
        return abort(err) if err
        return abort(meta.rangeNotSatisfiable, 416) if meta.rangeNotSatisfiable

        res.setHeader("ETag", meta.etag) if meta.etag?

        res.statusCode = 304 if meta.notModified
        res.statusCode = 206 if meta.partialContent

        if meta.stream? or options.head 
          res.setHeader("Content-Type", meta.mime) if meta.mime?
        
          if meta.size?
            res.setHeader("Content-Length", meta.size) 
            if meta.partialContent?
              res.setHeader("Content-Range", "bytes " + meta.partialContent.start + "-" + meta.partialContent.end + "/" + meta.partialContent.size)
    
          if not options.encoding 
            res.setHeader("Content-Type", "application/json")
      
        if meta.stream?
          meta.stream.on("error", abort)
          
          mount = base_path
          if options.encoding is null
            host_header = if req.socket.encrypted then "https://" else "http://" 
            base = req.restBase or host_header + req.headers.host + pathJoin(mount, path);
            encoder.jsonEncoder(meta.stream, base).pipe(res)
          else
            meta.stream.pipe(res)
          
          req.on "close", ->
            #console.log "here"
            if meta.stream.readable
              if meta.stream.destroy
                meta.stream.destroy()
              meta.stream.readable = false
        else
          res.end()
        
        
      if path[path.length - 1] == "/" 
        options.encoding = null
        vfs.readdir(path, options, onGet)
      else
        vfs.readfile(path, options, onGet)

    filePut = (path,req,res) ->
      if path[path.length - 1] == "/"
        vfs.mkdir path, {}, (err, meta) ->
          return abort(err) if err
          res.end()
      else
        vfs.mkfile path, { stream: req }, (err, meta) ->
          return abort(err) if err
          res.end()
    
    fileDel = (path, req, res) ->
      
        command = null
        if path[path.length - 1] == "/"
          command = vfs.rmdir
        else
          command = vfs.rmfile
          
        command path, {}, (err, meta) ->
          return abort(err) if err
          res.end()
    
    filePost = (path, req, res) ->
    
      if path[path.length - 1] == "/" 
        contentType = req.headers["content-type"]
        if not contentType
          return abort(new Error("Missing Content-Type header"), 400)
          
        if not /multipart/i.test(contentType) 
          return abort(new Error("Content-Type should be multipart"), 400)
          
        match = contentType.match(/boundary=(?:"([^"]+)"|([^;]+))/i)
        if not match 
          return abort(new Error("Missing multipart boundary"), 400) 
          
        boundary = match[1] or match[2]

        parser = multipart(req, boundary)

        parser.on "part", (stream) ->
          contentDisposition = stream.headers["content-disposition"]
          if not contentDisposition
            return parser.error("Missing Content-Disposition header in part")
            
          match = contentDisposition.match(/filename="([^"]*)"/)
          if not match
            return parser.error("Missing filename in Content-Disposition header in part")
            
          filename = match[1]

          vfs.mkfile path + "/" + filename, {stream:stream}, (err, meta) ->
            return abort(err)  if err
              
        parser.on "error", abort
        parser.on "end", ->
          res.end()

      data = ""
      req.on "data", (chunk) ->
        data += chunk
        
      req.on "end", ->
        message = null
        try
          message = JSON.parse(data)
        catch err
          return abort(err)
          
        command = null
        options = {}
        if message.renameFrom
          command = vfs.rename
          options.from = message.renameFrom
        else if message.copyFrom
          command = vfs.copy
          options.from = message.copyFrom
        else if message.linkTo
          command = vfs.symlink
          options.target = message.linkTo
        else
          return abort(new Error("Invalid command in POST " + data))
          
        command path, options, (err, meta) ->
          return abort(err) if err
          res.end()
    
    return fileGet(path,req, res) if req.route.method is 'get'
    return filePost(path,req, res) if req.route.method is 'post'
    return filePut(path,req,res) if req.route.method is 'put'
    return fileDel(path, req,res) if req.route.mathod is 'delete'
    return errors.badMethod(res)
  



