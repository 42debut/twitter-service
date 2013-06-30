
fs      = require 'fs'
path    = require 'path'
restify = require 'restify'
url     = require 'url'


config =
    host:           process.env.services__twitter__host            or '127.0.0.1'
    port:           process.env.services__twitter__port            or 6000
    twitterApiUrl:  process.env.services__twitter__api_url         or 'https://api.twitter.com'
    consumerKey:    process.env.services__twitter__consumer_key
    consumerSecret: process.env.services__twitter__consumer_secret

console.log "CONFIGURATION\n"
console.log config
console.log ""

if not config.consumerKey
    throw new Error('Consumer key is required.')

if not config.consumerSecret
    throw new Error('Consumer secret is required.')


twitterRequest = ((twitterApiUrl) ->
    request = (require 'request').defaults strictSSL:true

    (method, endpoint, options, done) ->
        requestUrl = (url.resolve twitterApiUrl, endpoint)
        console.log 'Twitter request:\n' + (JSON.stringify {method, url:requestUrl}, null, 2)

        [options, done] = [{}, options] if arguments.length is 3 and not done
        method = method.toLowerCase()

        request[method] requestUrl, options, (err, response, body) ->
            return done err if err

            console.log "Twitter response (#{response.statusCode})"

            if response.statusCode isnt 200
                return done response

            data = JSON.parse body
            return done data.errors if data.errors

            return done false, data, response
)(config.twitterApiUrl)


# See this for details:
# https://dev.twitter.com/docs/auth/application-only-auth
requestBearerToken = (consumerKey, consumerSecret, done) ->
    twitterRequest 'post', '/oauth2/token',
        auth:
            user: consumerKey
            pass: consumerSecret
            setImmediate: true

        form:
            grant_type: 'client_credentials'

        , (err, data) ->
            return done err if err

            {token_type:tokenType, access_token:accessToken} = data
            return done new Error("Unexpected token type `#{tokenType}`.") if tokenType isnt 'bearer'

            return done false, accessToken



AuthTwitterRequest = (token) ->
    return (method, endpoint, options, done) ->
        [options, done] = [{}, options] if arguments.length is 3 and not done
        options.headers ?= {}
        options.headers['Authorization'] = "Bearer #{token}"
        twitterRequest method, endpoint, options, done



requestBearerToken config.consumerKey, config.consumerSecret, (err, token) ->
    if err
        console.error "Could not get bearer token:"
        return console.error err

    console.log "Request for bearer token was successful."
    runServer (AuthTwitterRequest token), config.host, config.port



runServer = (twitterApi, host, port) ->

    server = restify.createServer()

    server.use restify.acceptParser server.acceptable
    server.use restify.CORS()
    server.use restify.fullResponse()
    server.use restify.bodyParser()
    server.use restify.gzipResponse()
    server.use restify.queryParser()


    server.get '/1.1/application/rate_limit_status.json', (req, res, next) ->

        twitterApi "get", "/1.1/application/rate_limit_status.json", {
                qs:resources:'statuses,search'
            }, (err, data) ->
                return res.send err if err

                appContext = data.rate_limit_context.application

                if appContext isnt config.consumerKey
                    message = "Unexpected application context `#{appContext}`. Doesn't match configured consumer key."
                    console.error message
                    res.send(502, {message})
                    return next()

                res.send resources:
                    statuses: '/statuses/user_timeline': data.resources.statuses['/statuses/user_timeline']
                    search:   '/search/tweets':          null

                return next()


    proxyTwitterGet = (endpoint) ->
        server.get endpoint, (req, res, next) ->
            {search} = url.parse req.url, true
            twitterApi "get", "#{endpoint}#{search}", {}, (err, data) ->
                if err then (res.send err) else res.send data
                return next()


    proxyTwitterGet "/1.1/statuses/user_timeline.json"
    proxyTwitterGet "/1.1/search/tweets.json"


    console.log "Listening on #{host}:#{port}..."
    server.listen port, host
