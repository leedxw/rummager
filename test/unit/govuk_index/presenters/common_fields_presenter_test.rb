require 'test_helper'

class GovukIndex::ElasticsearchPresenterTest < Minitest::Test
  def setup
    super

    @popularity_lookup = stub(:popularity_lookup)
    Indexer::PopularityLookup.stubs(:new).returns(@popularity_lookup)
    @popularity_lookup.stubs(:lookup_popularities).returns({})

    @directly_mapped_fields = %w(
      content_id
      description
      email_document_supertype
      government_document_supertype
      navigation_document_supertype
      publishing_app
      rendering_app
      title
      user_journey_document_supertype
    )
  end

  def test_directly_mapped_fields
    payload = generate_random_example(
      payload: { expanded_links: {} },
      excluded_fields: ["withdrawn_notice"]
    )

    presented_fields = common_fields_presenter(payload).present

    @directly_mapped_fields.each do |field|
      assert_equal presented_fields[field.to_sym], payload[field]
    end
  end

  def test_non_directly_mapped_fields
    defined_fields = {
      base_path: "/some/path",
      details: { body: "We love cheese" },
      expanded_links: {},
    }

    payload = generate_random_example(
      payload: defined_fields,
      excluded_fields: ["withdrawn_notice"]
    )

    presented_fields = common_fields_presenter(payload).present

    assert_equal presented_fields[:format], payload["document_type"]
    assert_equal presented_fields[:indexable_content], "\nWe love cheese\n"
    assert_equal presented_fields[:is_withdrawn], false
    assert_equal presented_fields[:link], payload["base_path"]
  end

  def test_withdrawn_when_withdrawn_notice_present
    payload = {
      "base_path" => "/some/path",
      "withdrawn_notice" => {
        "explanation" => "<div class=\"govspeak\"><p>test 2</p>\n</div>",
        "withdrawn_at" => "2017-08-03T14:02:18Z"
      }
    }

    presented_fields = common_fields_presenter(payload).present

    assert_equal presented_fields[:is_withdrawn], true
  end

  def test_popularity_when_value_is_returned_from_lookup
    payload = { "base_path" => "/some/path" }

    popularity = 0.0125356

    Indexer::PopularityLookup.expects(:new).with('govuk_index', SearchConfig.instance).returns(@popularity_lookup)
    @popularity_lookup.expects(:lookup_popularities).with([payload['base_path']]).returns(payload["base_path"] => popularity)

    presented_fields = common_fields_presenter(payload).present

    assert_equal popularity, presented_fields[:popularity]
  end

  def test_no_popularity_when_no_value_is_returned_from_lookup
    payload = { "base_path" => "/some/path" }

    Indexer::PopularityLookup.expects(:new).with('govuk_index', SearchConfig.instance).returns(@popularity_lookup)
    @popularity_lookup.expects(:lookup_popularities).with([payload['base_path']]).returns({})

    presented_fields = common_fields_presenter(payload).present

    assert_equal nil, presented_fields['popularity']
  end

  def common_fields_presenter(payload)
    GovukIndex::CommonFieldsPresenter.new(
      payload,
      GovukIndex::IndexableContentSanitiser.new
    )
  end
end
