FROM ruby:2.1.6

# throw errors if Gemfile has been modified since Gemfile.lock
#RUN bundle config --global frozen 1
RUN apt-get install -y build-essential nodejs npm && \
    npm install -g yarn

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

EXPOSE 3000

#CMD ["bundle", "exec", "rake", "server"]
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-p", "3000"]