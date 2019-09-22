FROM ruby:2.4.1
RUN apt-get update -qq && apt-get install -y imagemagick ghostscript
# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

WORKDIR /usr/src/reservations

COPY Gemfile Gemfile.lock ./
RUN bundle install --without development test heroku 

# Copy app source code
COPY . .
# Add docker specific 
COPY deployment/docker/config/ config/.

# Add a script to be executed every time the container starts.
COPY deployment/docker/entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]
#EXPOSE 3000
EXPOSE 8080

VOLUME /usr/src/reservations/.env
VOLUME /usr/src/reservations/assets/
VOLUME /usr/src/reservations/attachments/

# Start the main process.
CMD ["bundle", "exec", "puma"]
