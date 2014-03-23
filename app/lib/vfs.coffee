
Request = require "./request"

methodsMap = 
  "listdir": "getJSON"
  "write": "put"
  "mkdir": "put"
  "create": "put"
  "special": "post"
  "remove": "delete"
  "read": "get"

module.exports.execute = ( method, args, options ) ->
	
	#args = if args and not method == "write" then JSON.stringify(args) else args 
	args  = args 
	return Q.reject(new Error("VFS requests need url option"))  if not options.url
	return Q.reject(new Error("invalid Vfs Request " + method)) if not methodsMap[method]
	
	requestFunc = Request[ methodsMap[ method ]]

	return requestFunc( options.url, args, options )
