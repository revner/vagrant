require "vagrant/config/v2/util"

module Vagrant
  module Config
    module V2
      # This is the root configuration class. An instance of this is what
      # is passed into version 1 Vagrant configuration blocks.
      class Root
        # Initializes a root object that maps the given keys to specific
        # configuration classes.
        #
        # @param [Hash] config_map Map of key to config class.
        def initialize(config_map, keys=nil)
          @keys       = keys || {}
          @config_map = config_map
        end

        # We use method_missing as a way to get the configuration that is
        # used for Vagrant and load the proper configuration classes for
        # each.
        def method_missing(name, *args)
          return @keys[name] if @keys.has_key?(name)

          config_klass = @config_map[name.to_sym]
          if config_klass
            # Instantiate the class and return the instance
            @keys[name] = config_klass.new
            return @keys[name]
          else
            # Super it up to probably raise a NoMethodError
            super
          end
        end

        # Called to finalize this object just prior to it being used by
        # the Vagrant system. The "!" signifies that this is expected to
        # mutate itself.
        def finalize!
          @keys.each do |_key, instance|
            instance.finalize!
          end
        end

        # This validates the configuration and returns a hash of error
        # messages by section. If there are no errors, an empty hash
        # is returned.
        #
        # @param [Environment] env
        # @return [Hash]
        def validate(machine)
          # Go through each of the configuration keys and validate
          errors = {}
          @keys.each do |_key, instance|
            if instance.respond_to?(:validate)
              # Validate this single item, and if we have errors then
              # we merge them into our total errors list.
              result = instance.validate(machine)
              if result && !result.empty?
                errors = Util.merge_errors(errors, result)
              end
            end
          end

          # Go through and delete empty keys
          errors.keys.each do |key|
            errors.delete(key) if errors[key].empty?
          end

          errors
        end

        # Returns the internal state of the root object. This is used
        # by outside classes when merging, and shouldn't be called directly.
        # Note the strange method name is to attempt to avoid any name
        # clashes with potential configuration keys.
        def __internal_state
          {
            "config_map" => @config_map,
            "keys"       => @keys
          }
        end
      end
    end
  end
end
