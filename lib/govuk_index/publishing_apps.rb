module GovukIndex
  module PublishingApps
    extend self

    def non_indexable?(app)
      non_indexable_publishing_apps.include?(app)
    end

    def indexable?(app, format, path)
      return false unless indexable_publishing_apps[app].present? || indexable_routes[app].present?
      indexable_publishing_apps[app] == :all || indexable_publishing_apps[app]&.include?(format) ||
        indexable_routes[app]&.include?(path)
    end

    def indexable_publishing_apps
      @indexable_publishing_apps ||= convert_to_allowed_hash(data_file['indexable_publishing_apps'])
    end

    def indexable_routes
      @indexable_routes ||= data_file['indexable_special_cases']
    end

    def non_indexable_publishing_apps
      @blacklist_publishing_apps ||= data_file['non_indexable_publishing_apps']
    end

  private

    def data_file
      @data_file ||= YAML.load_file(File.join(__dir__, '../../config/govuk_index/publishing_apps.yaml'))
    end

    def convert_to_allowed_hash(apps)
      apps.inject({}) do |hash, app|
        if app.is_a?(Hash)
          hash.merge(app)
        else
          hash[app] = :all
          hash
        end
      end
    end
  end
end
