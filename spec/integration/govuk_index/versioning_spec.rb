require 'govuk_schemas'
require 'spec_helper'
require 'govuk_index/publishing_event_processor'

RSpec.describe 'GovukIndex::VersioningTest' do
  before do
    @processor = GovukIndex::PublishingEventProcessor.new
  end

  it "should successfully index increasing version numbers" do
    allow(GovukIndex::PublishingApps).to receive(:indexable?).and_return(true)

    version1 = generate_random_example(
      payload: { payload_version: 123 },
    )

    base_path = version1["base_path"]
    process_message(version1)

    document = fetch_document_from_rummager(id: base_path, index: "govuk_test")
    expect(document["_version"]).to eq(123)

    version2 = version1.merge(title: "new title", payload_version: 124)
    process_message(version2)

    document = fetch_document_from_rummager(id: base_path, index: "govuk_test")
    expect(document["_version"]).to eq(124)
    expect(document["_source"]["title"]).to eq("new title")
  end

  it "should discard message with same version as existing document" do
    allow(GovukIndex::PublishingApps).to receive(:indexable?).and_return(true)
    version1 = generate_random_example(payload: { payload_version: 123 })

    base_path = version1["base_path"]
    process_message(version1)

    document = fetch_document_from_rummager(id: base_path, index: "govuk_test")
    expect(document["_version"]).to eq(123)

    version2 = version1.merge(title: "new title", payload_version: 123)
    process_message(version2)

    document = fetch_document_from_rummager(id: base_path, index: "govuk_test")
    expect(document["_version"]).to eq(123)
    expect(version1["title"]).to eq(document["_source"]["title"])
  end

  it "should discard message with earlier version than existing document" do
    allow(GovukIndex::PublishingApps).to receive(:indexable?).and_return(true)

    version1 = generate_random_example(payload: { payload_version: 123 })

    base_path = version1["base_path"]
    process_message(version1)

    document = fetch_document_from_rummager(id: base_path, index: "govuk_test")
    expect(document["_version"]).to eq(123)

    version2 = version1.merge(title: "new title", payload_version: 122)
    process_message(version2)

    document = fetch_document_from_rummager(id: base_path, index: "govuk_test")
    expect(document["_version"]).to eq(123)
    expect(version1["title"]).to eq(document["_source"]["title"])
  end

  it "should delete and recreate document when unpublished and republished" do
    allow(GovukIndex::PublishingApps).to receive(:indexable?).and_return(true)
    version1 = generate_random_example(
      payload: { payload_version: 1 },
      excluded_fields: ["withdrawn_notice"],
    )

    base_path = version1["base_path"]
    process_message(version1)

    document = fetch_document_from_rummager(id: base_path, index: "govuk_test")
    expect(document["_version"]).to eq(1)

    version2 = generate_random_example(
      schema: 'gone',
      payload: {
        base_path: base_path,
        payload_version: 2
      },
      excluded_fields: ["withdrawn_notice"],
    )
    process_message(version2, unpublishing: true)

    expect {
      fetch_document_from_rummager(id: base_path, index: 'govuk_test')
    }.to raise_error(Elasticsearch::Transport::Transport::Errors::NotFound)

    version3 = version1.merge(payload_version: 3)
    process_message(version3)

    document = fetch_document_from_rummager(id: base_path, index: "govuk_test")
    expect(document["_version"]).to eq(3)
  end

  it "should discard unpublishing message with earlier version" do
    allow(GovukIndex::PublishingApps).to receive(:non_indexable?).and_return(false)
    allow(GovukIndex::PublishingApps).to receive(:indexable?).and_return(true)
    version1 = generate_random_example(payload: { payload_version: 2 })

    base_path = version1["base_path"]
    process_message(version1)

    document = fetch_document_from_rummager(id: base_path, index: "govuk_test")
    expect(document["_version"]).to eq(2)

    version2 = generate_random_example(
      schema: 'gone',
      payload: {
        base_path: base_path,
        payload_version: 1
      },
      excluded_fields: ["withdrawn_notice"],
    )
    process_message(version2, unpublishing: true)

    document = fetch_document_from_rummager(id: base_path, index: "govuk_test")
    expect(document["_version"]).to eq(2)
  end

  it "should ignore event for non indexable formats" do
    allow(GovukIndex::PublishingApps).to receive(:non_indexable?).and_return(false)
    allow(GovukIndex::PublishingApps).to receive(:indexable?).and_return(true)

    version1 = generate_random_example(payload: { payload_version: 123 })

    base_path = version1["base_path"]
    process_message(version1)

    document = fetch_document_from_rummager(id: base_path, index: "govuk_test")

    expect(document["_version"]).to eq(123)

    allow(GovukIndex::PublishingApps).to receive(:indexable?).and_return(false)

    version2 = version1.merge(title: "new title", payload_version: 124)
    process_message(version2)

    document = fetch_document_from_rummager(id: base_path, index: "govuk_test")
    expect(document["_version"]).to eq(123)
    expect(version1["title"]).to eq(document["_source"]["title"])
  end

  def process_message(example_document, unpublishing: false)
    @processor.process(stub_message_payload(example_document, unpublishing: unpublishing))
  end
end
