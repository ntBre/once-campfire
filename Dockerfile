# syntax = docker/dockerfile:1

# Make sure it matches the Ruby version in .ruby-version and Gemfile
ARG RUBY_VERSION=3.4.10
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

# Rails app lives here
WORKDIR /rails

# Install base packages
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libsqlite3-0 libvips libjemalloc2 ffmpeg redis && \
    ln -s /usr/lib/$(uname -m)-linux-gnu/libjemalloc.so.2 /usr/local/lib/libjemalloc.so && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archive

# Set production environment
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development" \
    LD_PRELOAD="/usr/local/lib/libjemalloc.so"


# Shared build stage with the packages needed to compile gems
FROM base AS build-base

RUN apt-get update -qq && \
    apt-get install -y build-essential git pkg-config libyaml-dev libssl-dev && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives


# Throw-away production build stage to reduce size of final image
FROM build-base AS build

# Install application gems
COPY Gemfile Gemfile.lock vendor ./

RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

# Copy application code
COPY . .

# Precompiling assets for production without requiring secret RAILS_MASTER_KEY
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile


# Development image with all gem groups and build tools available
FROM build-base AS development

ENV RAILS_ENV="development" \
    BUNDLE_DEPLOYMENT="false" \
    BUNDLE_WITHOUT=""

COPY Gemfile Gemfile.lock vendor ./
RUN bundle install

COPY . .

# Match the usual host user ID so bind-mounted files remain editable
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    mkdir -p /rails/storage && \
    chown -R rails:rails /rails
USER 1000:1000

EXPOSE 80
CMD ["bin/boot"]


# Final stage for app image
FROM base

# Image metadata
ARG OCI_DESCRIPTION
LABEL org.opencontainers.image.description="${OCI_DESCRIPTION}"
ARG OCI_SOURCE
LABEL org.opencontainers.image.source="${OCI_SOURCE}"
LABEL org.opencontainers.image.licenses="MIT"

# Run and own only the runtime files as a non-root user for security
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash
USER 1000:1000

# Configure environment defaults
ENV HTTP_IDLE_TIMEOUT=60
ENV HTTP_READ_TIMEOUT=300
ENV HTTP_WRITE_TIMEOUT=300

# Copy built artifacts: gems, application
COPY --from=build --chown=rails:rails /usr/local/bundle /usr/local/bundle
COPY --from=build --chown=rails:rails /rails /rails

# Install ONCE backup/restore hooks
COPY --chmod=755 hooks /hooks

# Set version and revision
ARG APP_VERSION
ENV APP_VERSION=$APP_VERSION
ARG GIT_REVISION
ENV GIT_REVISION=$GIT_REVISION

# Expose ports for HTTP and HTTPS
EXPOSE 80 443

# Start the server by default, this can be overwritten at runtime
CMD ["bin/boot"]
