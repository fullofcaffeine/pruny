# frozen_string_literal: true

require 'spec_helper'

describe Pruny::Models::Tree do
  describe '.from_json' do
    let(:tree) { Pruny::Models::Tree.from_json(json) }

    let(:json) do
      [
        {
          'foo' => 'bar',
          'meh' => {'such' => 'value'},
          'bar' => [
            {'tutu' => 'toot'},
            {'lala' => 'lolo'}
          ],
          'derp' => []
        }
      ]
    end

    describe 'root' do
      let(:root) { tree }
      specify do
        # The first node corresponds to the main array. This first element has:
        # - No key (it was an array)
        # - No parent (it's root)
        # - Has one children (the single hash)
        # - Has no value
        #
        # Array and Hashes are created as keyless nodes with its contents added as children. The hierachy
        # of nodes is generated like this to make make it easier to recreate the actual json again later.
        # (see the JsonConvertible module and or test).
        #
        # This behavior changes slightly if the array is value for a hash pair, in this case, the
        # array is created as a node with an actual key see the grandchild below for an example.
        assert_nil(root.key)
        assert_nil(root.parent)
        assert_nil(root.value)
        assert_equal(1, root.children.length)
      end

      describe 'first child' do
        let(:child) { root.children.first }

        specify do
          # Corresponds to the *hash*. The hash itself acts as a parent to any
          # pair that where value is_a?(Array). If the pair's value points to
          # anything that's not an Array, it will simply be part of the node's value.
          #
          # As explained in the example above, a hash is created as a node. It's pairs
          # are then assigned to this node's `value` field *except* if the value for this
          # pair is an array. If that's the case, then it will result in child node with
          # an actual `key` attribute and
          #
          # - This node has no key either
          # - It has a value of {foo: 'bar', meh: {such: 'value'}
          # - It has two children (see assertions below)
          assert_equal(root, child.parent)
          assert_nil(child.key)
          assert_equal({'foo' => 'bar', 'meh' => {'such' => 'value'}}, child.value)
          assert_equal(2, child.children.length)
        end

        describe 'first grandchild' do
          let(:first_grandchild) { child.children.first }

          specify do
            # Corresponds to the first pair that has a value of an array.
            #
            # This node does have a key. The key is :bar, and it also has 2 children,
            # the array, in this case, *is not* crated as a tree node because
            # 'bar' is the actual parent. The array shouldn't act as an additional child
            # node or it would result in a wrong child<>parent relationship.
            #
            # This node has children.
            assert_equal('bar', first_grandchild.key)
            assert_equal(child, first_grandchild.parent)
            assert_nil(first_grandchild.value)
            assert_equal(2, first_grandchild.children.count)
          end

          describe 'great grandchildren (leaves)' do
            let(:great_grandchildren) { first_grandchild.children }

            specify do
              assert_nil(great_grandchildren.first.key)
              assert_nil(great_grandchildren.last.key)

              assert_equal(first_grandchild, great_grandchildren.first.parent)
              assert_equal(first_grandchild, great_grandchildren.last.parent)

              assert_empty(great_grandchildren.first.children)
              assert_empty(great_grandchildren.last.children)

              assert_equal({'tutu' => 'toot'}, great_grandchildren.first.value)
              assert_equal({'lala' => 'lolo'}, great_grandchildren.last.value)
            end
          end
        end

        describe 'last grandchild (leaf)' do
          let(:last_grandchild) { child.children.last }

          specify do
            # This is to exemplify a hash pair that points to an empty array.
            # It's created just like the node for the first_grandchild, but
            # with no children. It's makes it a leaf.
            assert_equal('derp', last_grandchild.key)
            assert_equal(child, last_grandchild.parent)
            assert_nil(last_grandchild.value)
            assert_empty(last_grandchild.children)
          end
        end
      end
    end
  end
end
