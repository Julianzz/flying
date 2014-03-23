
isOldBrowser = (req) ->
    # https://github.com/biggora/express-useragent/blob/master/lib/express-useragent.js
    return false unless ua = req.useragent
    return true if ua.isiPad or ua.isiPod or ua.isiPhone or ua.isOpera
    return false unless ua and ua.Browser in ["Chrome", "Safari", "Firefox", "IE"] and ua.Version
    b = ua.Browser
    v = parseInt ua.Version.split('.')[0], 10
    return true if b is 'Chrome' and v < 17
    return true if b is 'Safari' and v < 6
    return true if b is 'Firefox' and v < 21
    return true if b is 'IE' and v < 10
    false
 
setupMiddlewareToSendOldBrowserWarningWhenPlayersViewLevelDirectly = (app) ->
  
  app.use '/play/', (req, res, next) ->
    return next() if req.query['try-old-browser-anyway'] or not isOldBrowser req
    res.sendfile(path.join(__dirname, 'public', 'index_old_browser.html'))
    
exports.isOldBrowser = isOldBrowser
exports.setupMiddlewareToSendOldBrowserWarningWhenPlayersViewLevelDirectly = setupMiddlewareToSendOldBrowserWarningWhenPlayersViewLevelDirectly
