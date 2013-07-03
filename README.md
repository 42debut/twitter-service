# Twitter Service

A web service that proxies calls to a read-only subset of the twitter API.
The proxy injects app-only authentication details.

Make sure you carefully evaluate and understand the security of this
service before using it. It is not meant to be exposed directly to the
internets.


## APIs Wrapped

#### `/1.1/application/rate_limit_status.json`
> https://dev.twitter.com/docs/api/1.1/get/application/rate_limit_status

> Returns the twitter app's rate limit status, but it only returns the
> resources that are wrapped by this service. <br>
> It also excludes the consumer key, because our clients don't really need it.


#### `/1.1/statuses/user_timeline.json`
> https://dev.twitter.com/docs/api/1.1/get/statuses/user_timeline


#### `/1.1/search/tweets.json`
> https://dev.twitter.com/docs/api/1.1/get/search/tweets


## Configuration

This service is configured via the following environment variables:

| Variable                              | Notes
| ------------------------------------- | ---------------------------------------------------
| `services__twitter__host`             | **optional**, defaults to `127.0.0.1`
| `services__twitter__port`             | **optional**, defaults to `6000`
| `services__twitter__api_url`          | **optional**, defaults to `https://api.twitter.com`
| `services__twitter__consumer_key`     | **required**
| `services__twitter__consumer_secret`  | **required**


## Setup

1. Get your keys by creating an application at
   https://dev.twitter.com/apps


## Installation

1. Install CoffeeScript: `npm install -g coffee-script`
2. Install the dependencies: `npm install -d`


## Running

1. Simply run `coffee twitter-service.coffee`.
