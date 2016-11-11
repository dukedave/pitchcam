FROM ruby:2.3.1

RUN apt-get update && apt-get install -y libopencv-dev

RUN bundle config --global frozen 1

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

COPY Gemfile /usr/src/app/
COPY Gemfile.lock /usr/src/app/
RUN bundle install

COPY . /usr/src/app

CMD ["./main.rb"]