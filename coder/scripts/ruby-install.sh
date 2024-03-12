#!/bin/bash

rbenv install --skip-existing $RUBY_VERSION \
    && rbenv global $RUBY_VERSION \
    && rbenv rehash \
    && gem install bundler colorls /coder/pulsar.gem --conservative
