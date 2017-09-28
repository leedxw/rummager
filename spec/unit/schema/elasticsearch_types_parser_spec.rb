require 'spec_helper'

RSpec.describe ElasticsearchTypesParser do
  def expect_raises_message(message)
    expect { yield }.to raise_error(message)
  end

  def schema_dir
    File.expand_path('../../../config/schema', File.dirname(__FILE__))
  end

  def cma_case_expanded_search_result_fields
    [
      {
        "label" => "Open",
        "value" => "open",
      },
      {
        "label" => "Closed",
        "value" => "closed",
      },
    ]
  end

  context "after loading standard types" do
    before do
      field_definitions = FieldDefinitionParser.new(schema_dir).parse
      @types = described_class.new(schema_dir, field_definitions).parse
      @identifier_es_config = { "type" => "string", "index" => "not_analyzed", "include_in_all" => false }
    end

    it "recognise the `manual_section` type" do
      expect("manual_section").to eq(@types["manual_section"].name)
    end

    it "know that the `manual_section` type has a `manual` field" do
      manual_field = @types["manual_section"].fields["manual"]
      expect(manual_field).not_to be_nil
      expect("manual").to eq(manual_field.name)
    end

    it "know that the `manual_section` type inherits the `link` field from the base type" do
      link_field = @types["manual_section"].fields["link"]
      expect(link_field).not_to be_nil
      expect("link").to eq(link_field.name)
      expect(false).to eq(link_field.type.multivalued)
      expect("identifier").to eq(link_field.type.name)
    end

    it "produce appropriate elasticsearch configuration for the `manual_section` type" do
      es_config = @types["manual_section"].es_config
      expect(
        hash_including({
          "manual" => @identifier_es_config,
          "link" => @identifier_es_config,
        })
      ).to eq(es_config)
    end

    it "not specify expanded_search_result_fields for the `organisations` field" do
      expect(@types["manual_section"].fields["organisations"].expanded_search_result_fields).to be_nil
    end

    it "include expanded_search_result_fields in the cma_case `case_state` field" do
      expect(
        cma_case_expanded_search_result_fields
      ).to eq(
        @types["cma_case"].fields["case_state"].expanded_search_result_fields
      )
    end

    it "expanded_search_result_fields on a field should also be available from the document type" do
      expect(
        @types["cma_case"].fields["case_state"].expanded_search_result_fields
      ).to eq(
        @types["cma_case"].expanded_search_result_fields["case_state"]
      )
    end
  end

  context "when configuration is invalid" do
    before do
      @definitions = FieldDefinitionParser.new(schema_dir).parse
      @parser = ElasticsearchTypeParser.new("/config/path/doc_type.json", nil, @definitions)
    end

    it "fail if document type doesn't specify `fields`" do
      allow_any_instance_of(ElasticsearchTypeParser).to receive(:load_json).and_return({})
      expect_raises_message(%{Missing "fields", in document type definition in "/config/path/doc_type.json"}) { @parser.parse }
    end

    it "fail if document type specifies unknown entries in `fields`" do
      allow_any_instance_of(ElasticsearchTypeParser).to receive(:load_json).and_return({
        "fields" => ["unknown_field"],
      })
      expect_raises_message(%{Undefined field \"unknown_field\", in document type definition in "/config/path/doc_type.json"}) { @parser.parse }
    end

    it "fail if document type has an unknown property" do
      allow_any_instance_of(ElasticsearchTypeParser).to receive(:load_json).and_return({
        "fields" => [],
        "unknown" => [],
      })
      expect_raises_message(%{Unknown keys (unknown), in document type definition in "/config/path/doc_type.json"}) { @parser.parse }
    end

    it "fail if `expanded_search_result_fields` are specified in base type" do
      allow_any_instance_of(ElasticsearchTypeParser).to receive(:load_json).and_return({
        "fields" => ["case_state"],
        "expanded_search_result_fields" => {
          "case_state" => cma_case_expanded_search_result_fields,
        },
      })
      base_type = @parser.parse

      subtype_parser = ElasticsearchTypeParser.new("/config/path/subtype.json", base_type, @definitions)
      allow_any_instance_of(ElasticsearchTypeParser).to receive(:load_json).and_return({ "fields" => [] })

      expect_raises_message(%{Specifying `expanded_search_result_fields` in base document type is not supported, in document type definition in "/config/path/subtype.json"}) { subtype_parser.parse }
    end

    it "fail if expanded_search_result_fields are set for fields which aren't known" do
      allow_any_instance_of(ElasticsearchTypeParser).to receive(:load_json).and_return({
        "fields" => ["case_state"],
        "expanded_search_result_fields" => {
          "unknown_field" => cma_case_expanded_search_result_fields,
        },
      })

      expect_raises_message(%{Field "unknown_field" set in "expanded_search_result_fields", but not in "fields", in document type definition in "/config/path/doc_type.json"}) { @parser.parse }
    end
  end
end
