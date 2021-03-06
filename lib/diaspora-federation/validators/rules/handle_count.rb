module Validation; module Rule

  # Rule for validating the number of Diaspora* handles in a string.
  # The evaluated string is split at ";" and the result will be counted.
  class HandleCount

    # @param [Hash] params
    # @option params [Fixnum] :maximum maximum allowed handle count
    def initialize(params)
      unless params.include?(:maximum) && params[:maximum].is_a?(Fixnum)
        raise "A number has to be specified for :maximum"
      end

      @params = params
    end

    def error_key
      :handle_count
    end

    def valid_value?(value)
      value.split(';').count <= params[:maximum]
    end

    def params
      @params
    end
  end
end; end
