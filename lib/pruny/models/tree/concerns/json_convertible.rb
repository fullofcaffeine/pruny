# frozen_string_literal: true

module Pruny
  module Models
    module Tree
      module Concerns
        module JsonConvertible
          # Creates a structure ready for the #to_json method.
          # @return [Array<Hash>, Hash] A hash based representation of the JSON.
          def as_json
            if children.any?
              key = children.first.key
              children_as_json = children.flat_map(&:as_json)

              if key
                h = {}
                h = h.merge(value) if value
                h = h.merge(key => children_as_json)
                h
              else
                children_as_json
              end
            else
              value
            end
          end
        end
      end
    end
  end
end
