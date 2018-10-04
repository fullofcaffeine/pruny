# frozen_string_literal: true

module Pruny
  module Models
    module Tree
      class TreeNode
        include Concerns::Filterable
        include Concerns::JsonConvertible

        attr_accessor :id, :key, :value, :parent, :children

        # Creates a new TreeNode.
        #
        # Note: Currently adding children to a node will not automatically set their parent! So
        # be aware if you're creating a new tree manually or create it from a json using
        # {Tree#from_json} which correctly sets parents for children (This might be an
        # idea of improvement for the future: to move this responsibility over here).
        #
        # @param key [String] A key that will serve as the name for the node.
        # @param value [Hash] A hash that holds the values for the node.
        # @param parent [TreeNode, nil] The parent for the node. Node is root if nil.
        # @param children [Array<TreeNode>, []] The children for the node. Leaf if empty.
        #
        # @return A node (that might represent a tree) [TreeNode]
        def initialize(id: nil, key: nil, value: nil, parent: nil, children: nil)
          @id = id || SecureRandom.uuid
          @key = key
          @value = value
          @parent = parent
          @children = children || []
        end
      end
    end
  end
end
