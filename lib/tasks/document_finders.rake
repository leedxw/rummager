require "publishing_api_finder_publisher"
require "publishing_api_topic_finder_publisher"

namespace :publishing_api do
  desc "Publish document finder."
  task :publish_document_finder do
    document_finder_config = ENV["DOCUMENT_FINDER_CONFIG"]

    unless document_finder_config
      raise "Please supply a valid finder config file name"
    end

    finder = YAML.load_file("config/#{document_finder_config}")
    timestamp = Time.now.iso8601

    PublishingApiFinderPublisher.new(finder, timestamp).call
  end

  desc "Publish citizen topic finders"
  task :publish_citizen_finders do
    taxon_info = [
      {
        title: "Entering and staying in the UK",
        description: "",
        slug: "entering-staying-uk",
        content_id: "ba3a9702-da22-487f-86c1-8334a730e559",
        finder_content_id: "b38fdac0-ab4f-438f-b212-06283e545d83",
      },
      {
        title: "Going and being abroad",
        description: "Includes passports, pet travel and mobile roaming fees",
        slug: "going-and-being-abroad",
        content_id: "9597c30a-605a-4e36-8bc1-47e5cdae41b3",
        finder_content_id: "d37a4cad-42ee-4a82-bb91-7de603848c72",
      },
      {
        title: "Education, training and skills",
        description: "Includes studying abroad and Erasmus+",
        slug: "education",
        content_id: "c58fdadd-7743-46d6-9629-90bb3ccc4ef0",
        finder_content_id: "7a807eae-8414-493e-80c5-1c9191a88b65",
      },
      {
        title: "Parenting, childcare and children's services",
        description: "",
        slug: "childcare-parenting",
        content_id: "206b7f3a-49b5-476f-af0f-fd27e2a68473",
        finder_content_id: "e2b459d3-dbbf-41a9-9f5d-6ca764f1b7d8",
      },
      {
        title: "Corporate information",
        description: "",
        slug: "corporate-information",
        content_id: "a544d48b-1e9e-47fb-b427-7a987c658c14",
        finder_content_id: "add749d5-a5b8-4749-a95b-14a9074bbd6e",
      },
      {
        title: "Transport",
        description: "Includes driving licenses, vehicle insurance and flying to the EU",
        slug: "transport",
        content_id: "a4038b29-b332-4f13-98b1-1c9709e216bc",
        finder_content_id: "2d4ac9b6-d783-47d6-a3ce-4c51b0e697f9",
      },
      {
        title: "Environment",
        description: "Includes environmental standards and food labels",
        slug: "environment",
        content_id: "3cf97f69-84de-41ae-bc7b-7e2cc238fa58",
        finder_content_id: "3d38d82e-5638-468d-a6ea-fef4ccbc8b18",
      },
      {
        title: "Welfare",
        description: "",
        slug: "welfare",
        content_id: "dded88e2-f92e-424f-b73e-6ad24a839c51",
        finder_content_id: "02b15cba-81ed-4db7-9304-cf5f9ef8c478",
      },
      {
        title: "Housing, local and community",
        description: "",
        slug: "housing-local-and-community",
        content_id: "4794066e-e3cc-425e-8cc4-e7ff3edb4c39",
        finder_content_id: "6d81eeba-cb5a-467d-a10f-b190088d2371",
      },
      {
        title: "Life circumstances",
        description: "",
        slug: "life-circumstances",
        content_id: "20086ead-41fc-49cf-8a62-d4e1126f41fc",
        finder_content_id: "82e22d92-d2e0-446f-aabe-9d09add11a2b",
      },
      {
        title: "International",
        description: "",
        slug: "international",
        content_id: "37d0fa26-abed-4c74-8835-b3b51ae1c8b2",
        finder_content_id: "ab33e79b-1fbb-4849-9d10-71d0bca102f3",
      },
      {
        title: "Health and social care",
        description: "Includes healthcare in the EU, medicine and health insurance",
        slug: "health-and-social-care",
        content_id: "8124ead8-8ebc-4faf-88ad-dd5cbcc92ba8",
        finder_content_id: "4c121266-f706-4097-b1ab-7140b338efa8",
      },
      {
        title: "Defence and armed forces",
        description: "",
        slug: "defence-and-armed-forces",
        content_id: "e491505c-77ae-45b2-84be-8c94b94f6a2b",
        finder_content_id: "5762997b-e488-4347-aeea-a3314cbe7f8f",
      },
      {
        title: "Crime, justice and law",
        description: "Includes data protection and legal services",
        slug: "crime-justice-and-law",
        content_id: "ba951b09-5146-43be-87af-44075eac3ae9",
        finder_content_id: "e0944dbe-19d3-4794-9f30-d308b7b23b11",
      },
      {
        title: "Regional and local government",
        description: "",
        slug: "regional-and-local-government",
        content_id: "503c5bc7-809a-47b9-83e2-bd0c212dbabb",
        finder_content_id: "caa34d93-6917-45e1-853f-027f5e2b272e",
      },
      {
        title: "Society and culture",
        description: "",
        slug: "society-and-culture",
        content_id: "e2ca2f1a-0ff3-43ce-b813-16645ff27904",
        finder_content_id: "ef618811-2ee0-4b38-92ab-ec8e235408b6",
      },
      {
        title: "Work",
        description: "",
        slug: "work",
        content_id: "d0f1e5a3-c8f4-4780-8678-994f19104b21",
        finder_content_id: "6c7c64df-4410-460d-8eaa-0f4c3b02a403",
      },
      {
        title: "Money",
        description: "",
        slug: "money",
        content_id: "6acc9db4-780e-4a46-92b4-1812e3c2c48a",
        finder_content_id: "30a2cd6a-cd2f-4161-9589-2a774b5cce3f",
      },
      {
        title: "Business and industry",
        description: "Includes consumer rights, banking and selling online",
        slug: "business-and-industry",
        content_id: "495afdb6-47be-4df1-8b38-91c8adb1eefc",
        finder_content_id: "9b97707e-abf5-400b-962e-2282248fdf02",
      }
    ]

    PublishingApiTopicFinderPublisher.new(taxon_info, Time.now.iso8601).call
  end
end
