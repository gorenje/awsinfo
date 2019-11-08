# Aws Info

Simple web interface on top of [aws cli tool](https://aws.amazon.com/cli/).

## Installation

Fairly typical sinatra/ruby project:

    gem install bundler
    bundle
    PORT=5000 foreman start

After that, it's turtles all the way down.

    open -a Firefox http://localhost:5000

After that, everything should work fine.

## Deployment

None. This is intended to be only run locally.

## Assumptions / Prerequisites

You are using a Mac since this uses ```osascript``` to start terminal
windows.

Also you'll need to install the [aws cli](https://aws.amazon.com/cli/) and
with it, the [aws-mfa](https://pypi.org/project/aws-mfa/).

At  time of writing this was something like:

    pip install awscli
    pip install aws-mfa

## Support

At the moment the two use cases this fulfills are

1. getting the IP of a server within a ECS cluster
2. manipulating SSM parameters - viewing, adding, updating, deleting
