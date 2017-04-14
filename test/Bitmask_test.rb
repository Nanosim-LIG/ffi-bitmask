[ '../lib', 'lib' ].each { |d| $:.unshift(d) if File::directory?(d) }
require 'minitest/autorun'
require 'ffi/bitmask'

module BitmaskTestModule
  extend FFI::Library
end

class BitmaskTest < Minitest::Test

  def test_bitmask_creation_notype_notag
    bm = BitmaskTestModule.bitmask(:FLAG1, :FLAG2, :FLAG3)
    assert_kind_of(FFI::Bitmask, bm)
    assert_kind_of(FFI::Enum, bm)
    assert_nil(bm.tag)
    assert_equal({:FLAG1 => 1, :FLAG2 => 2, :FLAG3 => 4}, bm.symbol_map)
    assert_equal(FFI::Type::INT, bm.native_type)
  end

  def test_bitmask_creation_notype
    bm = BitmaskTestModule.bitmask(:test_mask, [:FLAG1, :FLAG2, :FLAG3])
    assert_kind_of(FFI::Bitmask, bm)
    assert_kind_of(FFI::Enum, bm)
    assert_equal(:test_mask, bm.tag)
    assert_equal({:FLAG1 => 1, :FLAG2 => 2, :FLAG3 => 4}, bm.symbol_map)
    assert_equal(FFI::Type::INT, bm.native_type)
  end

  def test_bitmask_creation_notag
    bm = BitmaskTestModule.bitmask(FFI::Type::UINT64, [:FLAG1, :FLAG2, :FLAG3])
    assert_kind_of(FFI::Bitmask, bm)
    assert_kind_of(FFI::Enum, bm)
    assert_nil(bm.tag)
    assert_equal({:FLAG1 => 1, :FLAG2 => 2, :FLAG3 => 4}, bm.symbol_map)
    assert_equal(FFI::Type::UINT64, bm.native_type)
  end

  def test_bitmask_creation
    bm = BitmaskTestModule.bitmask(FFI::Type::UINT64, :test_mask, [:FLAG1, :FLAG2, :FLAG3])
    assert_kind_of(FFI::Bitmask, bm)
    assert_kind_of(FFI::Enum, bm)
    assert_equal(:test_mask, bm.tag)
    assert_equal({:FLAG1 => 1, :FLAG2 => 2, :FLAG3 => 4}, bm.symbol_map)
    assert_equal(FFI::Type::UINT64, bm.native_type)
  end

  def test_complex_bitmap_creation
    bm = BitmaskTestModule.bitmask(:FLAG1, :FLAG2, 5, :FLAG3)
    assert_equal({:FLAG1 => 1, :FLAG2 => 1<<5, :FLAG3 => 1<<6}, bm.symbol_map)
  end

  def test_find
    bm = BitmaskTestModule.bitmask(:FLAG1, :FLAG2, 5, :FLAG3)
    assert_equal([:FLAG1], bm[1])
    assert_equal([:FLAG1], bm[3])
    assert_equal([:FLAG1,:FLAG2], bm[1+(1<<5)])
    assert_equal([:FLAG1,:FLAG2], bm[1,(1<<5)])
    assert_equal(1<<5, bm[:FLAG2])
    assert_equal(1+(1<<5), bm[:FLAG2, :FLAG1])
  end

  def test_to_native
    bm = BitmaskTestModule.bitmask(:FLAG1, :FLAG2, 5, :FLAG3)
    assert_equal( 0, bm.to_native(nil, nil))
    assert_equal( 0, bm.to_native([], nil))
    assert_equal( 1, bm.to_native(:FLAG1, nil))
    assert_equal( 1+(1<<6), bm.to_native([:FLAG1,:FLAG3], nil))
    assert_equal( 1+(1<<5)+(1<<6), bm.to_native([:FLAG1,bm[:FLAG2],:FLAG3], nil))
    e = assert_raises( ArgumentError ) {
      bm.to_native([:FLAG1,:FLAG4,:FLAG3], nil)
    }
  end

  def test_from_native
    bm = BitmaskTestModule.bitmask(:FLAG1, :FLAG2, 5, :FLAG3)
    assert_equal([], bm.from_native(0, nil))
    assert_equal([:FLAG1,:FLAG3], bm.from_native(1+(1<<6), nil))
    assert_equal([:FLAG1,:FLAG3], bm.from_native(1+(1<<6)+(1<<7), nil))
  end

end

