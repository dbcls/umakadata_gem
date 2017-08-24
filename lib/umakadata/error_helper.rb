module Umakadata
  module ErrorHelper

    def set_error(value)
      @error = value
    end

    def get_error
      return nil if @error.nil?

      error = @error.dup
      clear
      return error
    end

    private
      def clear
        @error = nil
      end

  end
end
