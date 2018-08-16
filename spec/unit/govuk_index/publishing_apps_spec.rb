require "rspec"

RSpec.describe GovukIndex::PublishingApps do
  describe "#non_indexable?" do
    it "returns true if a publishing app's content has been blacklisted as non-indexable" do
      expect(described_class.non_indexable?("calculators")).to be true
    end

    it "returns false if a publishing app's content has not been blacklisted as non-indexable" do
      expect(described_class.non_indexable?("another-app")).to be false
    end
  end

  describe "indexable?" do
    it "returns true if a publishing app's content has been whitelisted as indexable for all its formats" do
      expect(described_class.indexable?("publisher", "a-format", "/a-path")).to be true
    end

    it "returns false if a publishing app's content has not been whitelisted as indexable" do
      expect(described_class.indexable?("an-app", "a-format", "/a-path")).to be_falsey
    end

    it "returns true if a publishing app's content has been whitelisted as indexable for specific formats" do
      expect(described_class.indexable?("whitehall", "finder", "/a-path")).to be true
    end

    it "returns false if a publishing app's format has not been whitelisted as indexable" do
      expect(described_class.indexable?("whitehall", "corporate_report", "/a-path")).to be_falsey
    end

    it "returns true if a route is has been whitelisted as indexable" do
      expect(described_class.indexable?("frontend", "a-format", "/help")).to be true
    end

    it "returns false if a route has not been whitelisted as indexable" do
      expect(described_class.indexable?("an-app", "a-format", "/a-route")).to be false
    end
  end
end
