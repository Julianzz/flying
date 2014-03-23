
module.exports.parse = (url) ->
  m = String(url).replace(/^\s+|\s+$/g, '').match(/^([^:\/?#]+:)?(\/\/(?:[^:@]*(?::[^:@]*)?@)?(([^:\/?#]*)(?::(\d*))?))?([^?#]*)(\?[^#]*)?(#[\s\S]*)?/)
  
  return if m 
      href     : m[0] or ''
      protocol : m[1] or ''
      authority: m[2] or ''
      host     : m[3] or ''
      hostname : m[4] or ''
      port     : m[5] or ''
      pathname : m[6] or ''
      search   : m[7] or ''
      hash     : m[8] or ''
    else 
      null
    