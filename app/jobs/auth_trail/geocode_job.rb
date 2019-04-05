module AuthTrail
  class GeocodeJob < Rails::VERSION::MAJOR >= 5 ? ApplicationJob : ActiveJob::Base
    def perform(login_activity)
      result =
        begin
          Geocoder.search(login_activity.ip).first
        rescue => e
          Rails.logger.info "Geocode failed: #{e.message}"
          nil
        end

      if result
        with_coordinates = model_supports_coordinates?(login_activity)
        attributes = attributes_for_result(result, with_coordinates)
        login_activity.update!(attributes)
      end
    end

    private

      def attributes_for_result(result, with_coordinates)
        attributes = {
          city: result.try(:city).presence,
          region: result.try(:state).presence,
          country: result.try(:country).presence
        }
        if with_coordinates
          attributes[:latitude] = result.try(:latitude).presence
          attributes[:longitude] = result.try(:longitude).presence
        end
        attributes
      end

      def model_supports_coordinates?(login_activity)
        column_names = login_activity.class.column_names
        column_names.include?('latitude') && column_names.include?('longitude')
      end

  end
end
