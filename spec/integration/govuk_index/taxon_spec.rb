require 'spec_helper'

RSpec.describe "taxon publishing" do
  before do
    bunny_mock = BunnyMock.new
    @channel = bunny_mock.start.channel

    consumer = GovukMessageQueueConsumer::Consumer.new(
      queue_name: "taxon.test",
      processor: GovukIndex::PublishingEventProcessor.new,
      rabbitmq_connection: bunny_mock,
    )

    @queue = @channel.queue("taxon.test")
    consumer.run
  end

  it "indexes a whitelisted taxon page" do
    random_example = generate_random_example(
      schema: "taxon",
      payload: {
        publishing_app: "content-tagger",
        base_path: "/world/afghanistan",
      }
    )

    allow(GovukIndex::PublishingApps).to receive(:indexable_routes).and_return("content-tagger" => ["/world/afghanistan"])
    @queue.publish(random_example.to_json, content_type: "application/json")

    expected_document = { "link" => random_example["base_path"] }
    expect_document_is_in_rummager(expected_document, index: "govuk_test", type: "edition")
  end

  it "removes a whitelisted taxon page" do
    allow(GovukIndex::PublishingApps).to receive(:indexable_routes).and_return("content-tagger" => ["/world/afghanistan"])
    content_id = "b7e993e1-9afa-4235-99a4-479caa240267"
    document = { "link" => "/world/afghanistan", "content_id" => content_id }

    commit_document('govuk_test', document, id: content_id, type: 'taxon')
    expect_document_is_in_rummager(document, id: content_id, index: "govuk_test", type: "taxon")

    payload = { "document_type" => "gone", "payload_version" => 15, "content_id" => content_id }
    @queue.publish(payload.to_json, content_type: "application/json")

    expect_document_missing_in_rummager(id: content_id, index: "govuk_test")
  end
end
