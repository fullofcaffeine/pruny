# frozen_string_literal: true

module Pruny
  module Models
    module Tree
      module Concerns
        module Filterable
          # Search for one or more tree nodes using a BFS algorithm, then
          # reverses the tree while keeping only the direct ascendants, effectivelly
          # filtering it.
          #
          # To create the search scope, we use three pieces of data:
          #
          # @param parent_node_key [String] The parent key for the node(s) we're looking for
          # @param key [String] The actual key for the value of the tree node we're looking for
          # @param values [Array<String>] The value we're looking
          # @return Array<TreeNode> the root for the filtered tree for each node found. If the nodes have a common
          # parent, they will be aggregated together.
          def filter(parent_node_key, key, values)
            nodes = search(parent_node_key, key, values)

            while nodes
              parents = nodes.group_by(&:parent).keys.group_by(&:id)

              # rubocop:disable Layout/BlockAlignment
              filtered = nodes.group_by { |n| n.parent.id }
                              .reduce([]) do |memo, (parent, children)|
                                 p = parents[parent].first.copy_subtree_filtered
                                 p.leaf.children = children.map { |node| node }
                                 memo << p.leaf
                              end
              break if filtered.map(&:parent).none?
              nodes = filtered
            end
            nodes
          end
          # rubocop:enable Layout/BlockAlignment

          private

          def search(parent_node_key, key, values)
            queue = [self]
            closed_set = Set.new
            found = []

            until queue.empty?
              node = queue.shift

              if node.parent                        &&
                 node.parent.key == parent_node_key &&
                 node.value                         &&
                 values.include?(node.value[key])
                found << node
                return found if found.length == values.length
              end

              node.children.each do |child|
                next if closed_set.include?(child)

                queue << child unless queue.include?(child)

                closed_set.add(child)
              end
            end

            found
          end

          protected

          def shallow_copy
            TreeNode.new(id: id, key: key, value: value)
          end

          def copy_subtree_filtered
            sequence = [shallow_copy]
            node = parent

            while node
              sequence.push(node.shallow_copy)
              node = node.parent
            end

            sequence.each_with_index.map do |n, i|
              child = i.zero? ? nil : sequence[i - 1]
              parent = sequence[i + 1]

              n.parent = parent
              n.children = child ? [child] : []
              n
            end
            # Simpler and more performant solution to get the root and leaf here, but might add
            # those as methods in TreeNode in the future.
            OpenStruct.new(root: sequence.last, leaf: sequence.first)
          end
        end
      end
    end
  end
end
