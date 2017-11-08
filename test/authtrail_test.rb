require_relative "test_helper"

class AuthTrailTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::AuthTrail::VERSION
  end
end
