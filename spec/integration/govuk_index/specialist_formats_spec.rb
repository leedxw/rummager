require 'spec_helper'

RSpec.describe 'SpecialistFormatTest' do
  before do
    bunny_mock = BunnyMock.new
    @channel = bunny_mock.start.channel

    consumer = GovukMessageQueueConsumer::Consumer.new(
      queue_name: "bigwig.test",
      processor: GovukIndex::PublishingEventProcessor.new,
      rabbitmq_connection: bunny_mock
    )

    @queue = @channel.queue("bigwig.test")
    consumer.run
  end

  it "specialist publisher finders are correctly indexed" do
    random_example = generate_random_example(
      schema: "finder",
      payload: { publishing_app: "specialist-publisher" },
    )

    allow(GovukIndex::PublishingApps).to receive(:indexable_publishing_apps).and_return("specialist-publisher" => :all)
    @queue.publish(random_example.to_json, content_type: "application/json")

    expect_document_is_in_rummager({ "link" => random_example["base_path"] }, index: "govuk_test", type: 'edition')
  end

  it "specialist publisher documents are correctly indexed" do
    random_example = generate_random_example(
      schema: "specialist_document",
      payload: { document_type: "aaib_report", publishing_app: "specialist-publisher" },
    )
    allow(GovukIndex::PublishingApps).to receive(:indexable_publishing_apps).and_return("specialist-publisher" => :all)

    @queue.publish(random_example.to_json, content_type: "application/json")

    expect_document_is_in_rummager({ "link" => random_example["base_path"] }, index: "govuk_test", type: "aaib_report")
  end

  it "finders email signup are never indexed" do
    random_example = generate_random_example(
      schema: "finder_email_signup",
      payload: { document_type: "finder_email_signup" },
    )

    @queue.publish(random_example.to_json, content_type: "application/json")

    expect {
      fetch_document_from_rummager(id: random_example["base_path"], index: "govuk_test")
    }.to raise_error(Elasticsearch::Transport::Transport::Errors::NotFound)
  end
end
