mailer = require('nodemailer');
config = require('../app')
marked = require('marked-prettyprint')
util = require('util')

transport = mailer.createTransport('SMTP', config.mail_opts)
SITE_ROOT_URL = 'http://' + config.host

###
 #Send an email
 #@param {Object} data 邮件对象
###
sendMail = (data) ->
  if config.debug
    console.log('******************** 在测试环境下，不会真的发送邮件*******************');
    for k in data 
      console.log('%s: %s', k, data[k])
    return

  #遍历邮件数组，发送每一封邮件，如果有发送失败的，就再压入数组，同时触发mailEvent事件
  transport.sendMail data, (err) ->
    console.log(err) if err

###
 * 发送激活通知邮件
 * @param {String} who 接收人的邮件地址
 * @param {String} token 重置用的token字符串
 * @param {String} name 接收人的用户名
###
    
exports.sendActiveMail = (who, token, name) ->
  from = util.format('%s <%s>', config.name, config.mail_opts.auth.user)
  to = who
  subject = config.name + '社区帐号激活'
  html = """<p>您好：<p/>'
    <p>我们收到您在 #{config.name} 社区的注册信息，请点击下面的链接来激活帐户：</p>
    <a href="#{SITE_ROOT_URL}/active_account?key=#{token}&name=#{name}">激活链接</a>
    <p>若您没有在#{config.name}社区填写过注册信息，说明有人滥用了您的电子邮箱，请删除此邮件，我们对给您造成的打扰感到抱歉。</p>
    <p> #{config.name} 社区 谨上。</p>
    """
  sendMail
    from: from
    to: to
    subject: subject
    html: html
    
###
 发送密码重置通知邮件
 @param {String} who 接收人的邮件地址
 @param {String} token 重置用的token字符串
 @param {String} name 接收人的用户名
###
exports.sendResetPassMail = (who, token, name) ->
  from = util.format('%s <%s>', config.name, config.mail_opts.auth.user)
  to = who
  subject = config.name + '社区密码重置'
  html = """<p>您好：<p/>
    <p>我们收到您在#{config.name}社区重置密码的请求，请在24小时内单击下面的链接来重置密码：</p>
    <a href="#{SITE_ROOT_URL}/reset_pass?key=#{token}&name=#{name}">重置密码链接</a>
    <p>若您没有在#{config.name}社区填写过注册信息，说明有人滥用了您的电子邮箱，请删除此邮件，我们对给您造成的打扰感到抱歉。</p>
    <p>#{config.name}社区 谨上。</p>
    """
  sendMail
    from: from
    to: to
    subject: subject
    html: html

###
 * 发送回复通知邮件
 * @param {String} who 接收人的邮件地址
 * @param {Object} msg 发送的消息对象
###
    
exports.sendReplyMail = (who, msg) ->
  from = util.format('%s <%s>', config.name, config.mail_opts.auth.user)
  to = who
  subject = config.name + ' 新消息';
  url = SITE_ROOT_URL + '/topic/' + msg.topic._id + '#' + msg.reply._id
  msg_content = marked( msg or "")
  
  html = """<p>您好：<p/>
    <p>
      <a href="#{SITE_ROOT_URL}/user/#{msg.author.name}" >#{ msg.author.name } </a> 
      在话题 <a href="#{url}"> #{msg.topic.title}</a> 
      中回复了你: 
    </p> 
    <blockquote> #{msg_content}</blockquote>
    <hr/> 
    <p>若您没有在' + config.name + '社区填写过注册信息，说明有人滥用了您的电子邮箱，请删除此邮件，我们对给您造成的打扰感到抱歉。</p>
    <p> #{config.name}社区 谨上。</p>
    """
  sendMail
    from: from
    to: to
    subject: subject
    html: html

