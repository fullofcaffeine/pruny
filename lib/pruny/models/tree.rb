# frozen_string_literal: true

module Pruny
  module Models
    module Tree
      # Builds a new tree from based off a data structure that's
      # consisted of Array and Hashes.
      #
      # An Array is converted to a tree node with its elements as
      # the children.
      #
      # @param v [Array, Hash] the json (represented as array of hashes or hash) to convert to a Tree.
      # @param k [String] the key that will describe the node for `v`.
      # @param parent [TreeNode] the parent for the new node being created.
      # @return the tree [TreeNode]
      def self.from_json(v, k = nil, parent = nil)
        if v.is_a?(Array)
          TreeNode.new(key: k, parent: parent).tap do |node|
            node.children = v.map { |o| from_json(o, k, node) }.flatten
          end
        elsif v.is_a?(Hash)
          TreeNode.new(value: {}, parent: parent, children: []).tap do |node|
            v.each_pair do |key, val|
              if val.is_a?(Array)
                node.children << from_json(val, key, node)
              else
                node.value = node.value.merge(key => val)
              end
            end
          end
        end
      end
    end
  end
end
