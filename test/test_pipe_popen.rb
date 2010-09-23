require 'test/unit'
require 'io/nonblock'
$-w = true
require 'kgio'

class TestPipePopen < Test::Unit::TestCase
  def test_popen
    io = Kgio::Pipe.popen("sleep 1 && echo HI")
    assert_equal Kgio::WaitReadable, io.kgio_read(2)
    sleep 1.5
    assert_equal "HI\n", io.kgio_read(3)
    assert_raises(EOFError) { io.kgio_read 5 }
  end
end