require 'spec_helper'

RSpec.describe GovukIndex::DetailsPresenter do
  subject(:presented_details) { described_class.new(details: details, format: format) }

  context 'when presenting details for a document' do
    context "when the format is 'license'" do
      let(:format) { 'licence' }
      let(:details) {
        {
          "continuation_link" => "http://www.on-and-on.com",
          "external_related_links" => [],
          "licence_identifier" => "1234-5-6",
          "licence_short_description" => "short description",
          "licence_overview" => [
            { "content_type" => "text/govspeak", "content" => "**overview**" },
            { "content_type" => "text/html", "content" => "<strong>overview</strong>" }
          ],
          "will_continue_on" => "on and on",
        }
      }

      it "extracts licence specific fields" do
        expect(presented_details.licence_identifier).to eq(details["licence_identifier"])
        expect(presented_details.licence_short_description).to eq(details["licence_short_description"])
      end
    end

    context "without an image in the document" do
      let(:format) { 'answer' }

      let(:details) {
        {
          "body" => "<p>Gallwch ddefnyddio’r gwasanaethau canlynol gan Gyllid a Thollau Ei Mawrhydi </p>\n\n",
          "external_related_links" => []
        }
      }

      it "has no image" do
        expect(presented_details.image_url).to be nil
      end
    end

    context "with an image in the document" do
      let(:format) { 'news_article' }

      let(:details) {
        {
          "image" => {
            "alt_text" => "Christmas",
            "url" => "https://assets.publishing.service.gov.uk/christmas.jpg"
          },
          "body" => "<div class=\"govspeak\"><p>We wish you a merry Christmas.</p></div>",
        }
      }

      it "has an image" do
        expect(presented_details.image_url).to eq("https://assets.publishing.service.gov.uk/christmas.jpg")
      end
    end

    context "when the format is 'hmrc_manual'" do
      let(:format) { "hmrc_manual" }

      context "without change notes" do
        let(:details) { {} }

        it "has no latest change note" do
          expect(presented_details.latest_change_note).to be_nil
        end
      end

      context "with empty change notes" do
        let(:details) {
          { "change_notes" => [] }
        }

        it "has no latest change note" do
          expect(presented_details.latest_change_note).to be_nil
        end
      end

      context "with multiple change notes" do
        let(:details) {
          {
            "change_notes" => [
              {
                "change_note" => "Change 1",
                "title" => "Manual section A",
                "published_at" => "2017-02-05T09:30:00+00:00"
              },
              {
                "change_note" => "Change 3",
                "title" => "Manual section B",
                "published_at" => "2017-07-24T08:00:00+00:00"
              },
              {
                "change_note" => "Change 2",
                "title" => "Manual section C",
                "published_at" => "2017-05-31T14:45:00+00:00"
              }
            ]
          }
        }

        it "combines the title and description from the most recent change note" do
          expect(presented_details.latest_change_note).to eq("Change 3 in Manual section B")
        end
      end
    end
  end
end
