require 'spec_helper'

RSpec.describe Indexer::MetadataTagger do
  let(:facet_config_file) { File.expand_path("fixtures/facet_config.yml", __dir__) }
  # rubocop:disable RSpec/VerifiedDoubles, RSpec/AnyInstance, RSpec/MessageSpies
  it "amends documents" do
    fixture_file = File.expand_path("fixtures/metadata.csv", __dir__)
    base_path = '/a_base_path'
    test_index_name = 'test-index'

    mock_index = double("index")

    expect_any_instance_of(LegacyClient::IndexForSearch).to receive(:get_document_by_link)
      .and_return('real_index_name' => test_index_name)

    metadata = {
      "sector_business_area" => %w(aerospace agriculture),
      "business_activity" => %w(yes),
      "appear_in_find_eu_exit_guidance_business_finder" => "yes"
    }

    expect(mock_index).to receive(:amend).with(base_path, metadata)
    expect_any_instance_of(SearchIndices::SearchServer).to receive(:index)
      .with(test_index_name)
      .and_return(mock_index)

    described_class.initialise(fixture_file, facet_config_file)
    described_class.amend_all_metadata
  end

  context "when removing metadata" do
    def nil_metadata_hash
      {
        "business_activity" => nil,
        "employ_eu_citizens" => nil,
        "eu_uk_government_funding" => nil,
        "regulations_and_standards" => nil,
        "personal_data" => nil,
        "intellectual_property" => nil,
        "public_sector_procurement" => nil,
        "sector_business_area" => nil,
        "appear_in_find_eu_exit_guidance_business_finder" => nil
      }
    end

    it "nils out all metadatad for a base path" do
      fixture_file = File.expand_path("fixtures/metadata.csv", __dir__)
      base_path = "/a_base_path"
      test_index = "test_index"

      mock_index = double("index")

      expect_any_instance_of(LegacyClient::IndexForSearch).to receive(:get_document_by_link)
        .and_return("real_index_name" => test_index)

      expect(mock_index).to receive(:amend).with(base_path, nil_metadata_hash)
      expect_any_instance_of(SearchIndices::SearchServer).to receive(:index)
        .with(test_index)
        .and_return(mock_index)

      described_class.initialise(fixture_file, facet_config_file)
      described_class.remove_all_metadata_for_base_paths(base_path)
    end

    it "clears all eu exit guidance metadat" do
      fixture_file = File.expand_path("fixtures/metadata.csv", __dir__)

      allow(described_class)
        .to receive(:find_all_eu_exit_guidance)
        .and_return(
          {
            results:
              [
                { "link" => "a_base_path", item: "one" },
                { "link" => "another_base_path", item: "two" }
              ]
          }
      )

      expect(described_class)
        .to receive(:remove_all_metadata_for_base_paths)
        .with(%w(a_base_path another_base_path))

      described_class.initialise(fixture_file, facet_config_file)
      described_class.destroy_all_eu_exit_guidance!
    end
  end
  # rubocop:enable RSpec/VerifiedDoubles, RSpec/AnyInstance, RSpec/MessageSpies
end
