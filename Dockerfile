FROM ruby:2.5.3
RUN apt-get update -qq && apt-get upgrade -y && apt-get install -y build-essential && apt-get clean
RUN gem install foreman

ENV GOVUK_APP_NAME rummager
ENV REDIS_HOST redis
ENV ELASTICSEARCH_URI http://elasticsearch:9200
ENV PORT 3009
ENV RABBITMQ_HOSTS rabbitmq
ENV RABBITMQ_VHOST /
ENV RABBITMQ_USER guest
ENV RABBITMQ_PASSWORD guest
ENV RACK_ENV development

ENV APP_HOME /app
RUN mkdir $APP_HOME

WORKDIR $APP_HOME
ADD Gemfile* $APP_HOME/
RUN bundle install
ADD . $APP_HOME

CMD foreman run web
