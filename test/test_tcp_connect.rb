require 'test/unit'
require 'io/nonblock'
$-w = true
require 'kgio'

class SubSocket < Kgio::Socket
  attr_accessor :foo
  def wait_writable
    @foo = "waited"
  end
end

class TestKgioTcpConnect < Test::Unit::TestCase

  def setup
    @host = ENV["TEST_HOST"] || '127.0.0.1'
    @srv = Kgio::TCPServer.new(@host, 0)
    @port = @srv.addr[1]
    @addr = Socket.pack_sockaddr_in(@port, @host)
  end

  def teardown
    @srv.close unless @srv.closed?
    Kgio.accept_cloexec = true
    Kgio.accept_nonblock = false
    Kgio.wait_readable = Kgio.wait_writable = nil
  end

  def test_new
    sock = Kgio::Socket.new(@addr)
    assert_kind_of Kgio::Socket, sock
    ready = IO.select(nil, [ sock ])
    assert_equal sock, ready[1][0]
    assert_equal nil, sock.kgio_write("HELLO")
  end

  def test_tcp_socket_new_invalid
    assert_raises(ArgumentError) { Kgio::TCPSocket.new('example.com', 80) }
    assert_raises(ArgumentError) { Kgio::TCPSocket.new('999.999.999.999', 80) }
  end

  def test_tcp_socket_new
    sock = Kgio::TCPSocket.new(@host, @port)
    assert_instance_of Kgio::TCPSocket, sock
    ready = IO.select(nil, [ sock ])
    assert_equal sock, ready[1][0]
    assert_equal nil, sock.kgio_write("HELLO")
  end

  def test_wait_writable_set
    Kgio::wait_writable = :wait_writable
    sock = SubSocket.new(@addr)
    assert_equal "waited", sock.foo
    assert_equal nil, sock.kgio_write("HELLO")
  end
end