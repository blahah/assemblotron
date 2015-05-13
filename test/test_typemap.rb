require 'helper'
require 'trollop'

class TestController < Test::Unit::TestCase

  context 'TypeMap' do

    should 'convert type descriptions to Classes' do
      assert_equal String, Assemblotron::TypeMap.class_from_type('str')
      assert_equal String, Assemblotron::TypeMap.class_from_type('string')
      assert_equal Integer, Assemblotron::TypeMap.class_from_type('int')
      assert_equal Integer, Assemblotron::TypeMap.class_from_type('integer')
      assert_equal Float, Assemblotron::TypeMap.class_from_type('float')
      assert_equal nil, Assemblotron::TypeMap.class_from_type('notarealtype')
    end

  end

end
