require 'spec_helper'
require 'rake'
load "tasks/message_queue.rake"

RSpec.describe Indexer::MessageProcessor, 'RakeTest' do
  context "when indexing published documents to publishing-api" do
    it "use GovukMessageQueueConsumer::Consumer" do
      statsd_client = Statsd.new
      expect(Services).to receive(:statsd_client).and_return(statsd_client)

      indexer = described_class.new
      expect(described_class).to receive(:new).and_return(indexer)

      consumer = instance_double('GovukMessageQueueConsumer::Consumer', 'consumer')
      expect(consumer).to receive(:run).and_return(true)

      expect(GovukMessageQueueConsumer::Consumer).to receive(:new)
        .with(
          queue_name: "rummager_to_be_indexed",
          processor: indexer,
          statsd_client: statsd_client,
        ).and_return(consumer)

      Rake::Task["message_queue:listen_to_publishing_queue"].invoke
    end
  end
end
