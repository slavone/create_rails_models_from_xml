require 'minitest/autorun'
require 'active_support/core_ext'
require './xml_parser.rb'

class TestParser < MiniTest::Test

  TEST_XML = <<-end_of_xml
<document>
  <firstEntity>
    <firstParam attr='22323'>I am a the first param of the first entity</firstParam>
    <secondParam>I am the second param of the first entity</secondParam>
    <secondEntity>
      <firstParam>I am a the first param of the second entity</firstParam>
      <secondParam>I am the second param of the second entity</secondParam>
      <thirdEntity>
        <firstParam>I am a the first param of the third entity</firstParam>
        <secondParam>I am the second param of the third entity</secondParam>
      </thirdEntity>
    </secondEntity>
  </firstEntity>
  <firstParam>I am a the first param of the initial document</firstParam>
  <secondParam>I am the second param of the initial document</secondParam>
</document>
end_of_xml

  def setup
    @parser = Parser.new
  end

  def test_find_elements_and_nested
    r = @parser.find_elements_and_nested(Hash.from_xml(TEST_XML)['document'])
    assert_equal ['firstParam', 'secondParam'], r[:elements]
    assert_equal ['firstEntity'], r[:nested]
  end

  def test_everything
    hash = Hash.from_xml(TEST_XML)
    #hash = Hash.from_xml(File.read "brs_resp_2.xml")
    #puts @parser.create_tables hash, 'document'
    #@parser.write_into 'parsed_data', hash
    #@parser.print_unique_entities
    puts @parser.save_data hash, 'document', nil, 'brs'
  end
end
