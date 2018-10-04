# frozen_string_literal: true

require 'spec_helper'

describe Pruny::Models::Tree::TreeNode do
  # The logic for tree creation is in the Tree module. We're testing
  # that this class correctly handles the args and attr accessors. We
  # could have used dummy doubles for everything, but this also servers
  # as a documentation of what kind of arguments are expected.
  describe 'creation and accessors' do
    let(:node) { Pruny::Models::Tree::TreeNode.new(args) }
    let(:args) { {} }

    specify do
      assert_nil(node.key)
      assert_nil(node.value)
      assert_nil(node.parent)
      assert_empty(node.children)
    end

    describe 'with key' do
      let(:args) { {key: 'niice'} }

      it 'has a key' do
        assert_equal('niice', node.key)
        assert_nil(node.value)
        assert_nil(node.parent)
        assert_empty(node.children)
      end

      it 'can change the key' do
        node.key = 'awesome'
        assert_equal(node.key, 'awesome')
      end
    end

    describe 'with value' do
      let(:args) { {value: {'oh' => 'hay'}} }

      it 'has a value' do
        assert_nil(node.key)
        assert_equal({'oh' => 'hay'}, node.value)
        assert_nil(node.parent)
        assert_empty(node.children)
      end

      it 'can change the value' do
        node.value = {'id' => 1}
        assert_equal({'id' => 1}, node.value)
      end
    end

    describe 'with parent' do
      let(:parent) { Pruny::Models::Tree::TreeNode.new }
      let(:another_parent) { Pruny::Models::Tree::TreeNode.new }
      let(:args) { {parent: parent} }

      it 'has a parent' do
        assert_nil(node.key)
        assert_nil(node.value)
        assert_equal(parent, node.parent)
        assert_empty(node.children)
      end

      it 'can change the parent' do
        node.parent = another_parent
        assert_equal(another_parent, node.parent)
      end
    end

    describe 'with children' do
      let(:args) { {children: children} }
      let(:children) do
        [
          Pruny::Models::Tree::TreeNode.new,
          Pruny::Models::Tree::TreeNode.new
        ]
      end

      it 'has children' do
        assert_nil(node.key)
        assert_nil(node.value)
        assert_nil(node.parent)
        assert_equal(children, node.children)
      end

      it 'can change the children' do
        node.children = []
        assert_empty(node.children)
      end
    end
  end

  describe '#as_json' do
    let(:tree) do
      # It's a bit awkward to create a tree by hand, this could be improved by
      # having the node set the parent for its children. However, since it isn't
      # really required for the user stories at hand, I decided not to invest time
      # into such a API, we're not creating trees manually at the moment, anyway.
      # Refer to the comment in {TreeNode#initialize}.
      root = Pruny::Models::Tree::TreeNode.new
      child = Pruny::Models::Tree::TreeNode.new(parent: root, value: {'some' => 'useful-value'})
      grandchild = Pruny::Models::Tree::TreeNode.new(parent: child, key: 'mygrandchildren')
      great_grandchildren = [
        Pruny::Models::Tree::TreeNode.new(parent: grandchild, value: {'id' => 1}),
        Pruny::Models::Tree::TreeNode.new(parent: grandchild, value: {'id' => 2})
      ]

      root.children = [child]
      child.children = [grandchild]
      grandchild.children = great_grandchildren
      root
    end

    let(:expected_json) do
      [
        {
          'some' => 'useful-value',
          'mygrandchildren' => [
            {'id' => 1},
            {'id' => 2}
          ]
        }
      ]
    end

    it 'converts the tree to a json data structure' do
      assert_equal(expected_json, tree.as_json)
    end
  end

  describe '#filter' do
    let(:tree) do
      Pruny::Models::Tree.from_json(
        [
          {
            'id' => 1,
            'name' => 'Demographics',
            'sub_themes' => [
              {
                'id' => 1,
                'name' => 'Births and Deaths',
                'categories' => [
                  {
                    'id' => 1,
                    'name' => 'Crude death rate',
                    'unit' => '(deathes per 1000 people)',
                    'indicators' => [
                      {'id' => 1, 'name' => 'Total'},
                      {'id' => 2, 'name' => 'Foobar'}
                    ]
                  },
                  {
                    'id': 2,
                    'name': 'Some other category',
                    'unit': '(percent)',
                    'indicators' => [
                      {'id' => 4, 'name' => '0-14 or 65+ years'},
                      {'id' => 5, 'name' => 'Total'},
                      {'id' => 6, 'name' => 'Foobar'}
                    ]
                  }
                ]
              },
              {
                'id' => 2,
                'name' => 'Age and Sex',
                'categories' => [
                  {
                    'id' => 1,
                    'name' => 'Dependency Ratio',
                    'unit' => '(percent)',
                    'indicators' => [
                      {'id' => 7, 'name' => 'Total'},
                      {'id' => 8, 'name' => 'Foobar'}
                    ]
                  }
                ]
              }
            ]
          },
          {
            'id' => 2,
            'name' => 'Urban',
            'sub_themes' => [
              {
                'id' => 1,
                'name' => 'Administrative',
                'categories' => [
                  {
                    'id' => 1,
                    'name' => 'Area',
                    'unit' => '(deathes per 1000 people)',
                    'indicators' => [
                      {'id' => 9, 'name' => 'Total'},
                      {'id' => 10, 'name' => 'Foobar'}
                    ]
                  }
                ]
              }
            ]
          }
        ]
      )
    end

    describe 'single node' do
      let(:expected_output_tree_json) do
        {
          'id' => 1,
          'name' => 'Demographics',
          'sub_themes' => [
            'id' => 1,
            'name' => 'Births and Deaths',
            'categories' => [
              {
                'id' => 1,
                'name' => 'Crude death rate',
                'unit' => '(deathes per 1000 people)',
                'indicators' => [
                  {'id' => 2, 'name' => 'Foobar'}
                ]
              }
            ]
          ]
        }
      end

      it 'finds a single node and returns the filtered subtree' do
        assert_equal(expected_output_tree_json, tree.filter('indicators', 'id', [2]).first.as_json)
      end

      it 'can handle non-existing nodes' do
        assert_equal([], tree.filter('indicators', 'id', [0]))
      end
    end

    describe 'multiple nodes, same ascendants' do
      let(:expected_output_tree_json) do
        [
          {
            'id' => 1,
            'name' => 'Demographics',
            'sub_themes' => [
              {
                'id' => 1,
                'name' => 'Births and Deaths',
                'categories' => [
                  {
                    'id' => 1,
                    'name' => 'Crude death rate',
                    'unit' => '(deathes per 1000 people)',
                    'indicators' => [
                      {'id' => 1, 'name' => 'Total'},
                      {'id' => 2, 'name' => 'Foobar'}
                    ]
                  }
                ]
              },
              {
                'id' => 2,
                'name' => 'Age and Sex',
                'categories' => [
                  {
                    'id' => 1,
                    'name' => 'Dependency Ratio',
                    'unit' => '(percent)',
                    'indicators' => [
                      {'id' => 7, 'name' => 'Total'}
                    ]
                  }
                ]
              }
            ]
          },
          {
            'id' => 2,
            'name' => 'Urban',
            'sub_themes' => [
              {
                'id' => 1,
                'name' => 'Administrative',
                'categories' => [
                  {
                    'id' => 1,
                    'name' => 'Area',
                    'unit' => '(deathes per 1000 people)',
                    'indicators' => [
                      {'id' => 9, 'name' => 'Total'}
                    ]
                  }
                ]
              }
            ]
          }
        ]
      end

      it 'finds the nodes, returns the single common filtered subtree for them' do
        assert_equal(
          expected_output_tree_json,
          tree.filter('indicators', 'id', [1, 2, 7, 9]).map(&:as_json)
        )
      end

      it 'can handle non-existing nodes' do
        assert_equal(
          expected_output_tree_json,
          tree.filter('indicators', 'id', [1, 2, 7, 9, 0]).map(&:as_json)
        )
      end
    end

    describe 'multiple nodes, different ascendants' do
      let(:expected_output_tree_json) do
        [
          {
            'id' => 1,
            'name' => 'Demographics',
            'sub_themes' => [
              {
                'id' => 1,
                'name' => 'Births and Deaths',
                'categories' => [
                  {
                    'id' => 1,
                    'name' => 'Crude death rate',
                    'unit' => '(deathes per 1000 people)',
                    'indicators' => [
                      {'id' => 2, 'name' => 'Foobar'}
                    ]
                  }
                ]
              }
            ]
          },
          {
            'id' => 2,
            'name' => 'Urban',
            'sub_themes' => [
              {
                'id' => 1,
                'name' => 'Administrative',
                'categories' => [
                  {
                    'id' => 1,
                    'name' => 'Area',
                    'unit' => '(deathes per 1000 people)',
                    'indicators' => [
                      {'id' => 9, 'name' => 'Total'}
                    ]
                  }
                ]
              }
            ]
          }
        ]
      end

      it 'finds the nodes, returns the common subtrees per common parents' do
        assert_equal(
          expected_output_tree_json,
          tree.filter('indicators', 'id', [2, 9]).map(&:as_json).flatten
        )
      end
    end
  end
end
