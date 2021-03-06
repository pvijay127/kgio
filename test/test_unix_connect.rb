require 'test/unit'
require 'io/nonblock'
$-w = true
require 'kgio'
require 'tempfile'

class SubSocket < Kgio::Socket
  attr_accessor :foo
  def wait_writable
    @foo = "waited"
  end
end

class TestKgioUnixConnect < Test::Unit::TestCase

  def setup
    tmp = Tempfile.new('kgio_unix')
    @path = tmp.path
    File.unlink(@path)
    tmp.close rescue nil
    @srv = Kgio::UNIXServer.new(@path)
    @addr = Socket.pack_sockaddr_un(@path)
  end

  def teardown
    @srv.close unless @srv.closed?
    File.unlink(@path)
    Kgio.accept_cloexec = true
  end

  def test_unix_socket_new_invalid
    assert_raises(ArgumentError) { Kgio::UNIXSocket.new('*' * 1024 * 1024) }
  end

  def test_unix_socket_new
    sock = Kgio::UNIXSocket.new(@path)
    assert_instance_of Kgio::UNIXSocket, sock
    ready = IO.select(nil, [ sock ])
    assert_equal sock, ready[1][0]
    assert_equal nil, sock.kgio_write("HELLO")
  end

  def test_new
    sock = Kgio::Socket.new(@addr)
    assert_instance_of Kgio::Socket, sock
    ready = IO.select(nil, [ sock ])
    assert_equal sock, ready[1][0]
    assert_equal nil, sock.kgio_write("HELLO")
  end

  def test_start
    sock = Kgio::Socket.start(@addr)
    assert_instance_of Kgio::Socket, sock
    ready = IO.select(nil, [ sock ])
    assert_equal sock, ready[1][0]
    assert_equal nil, sock.kgio_write("HELLO")
  end

  def test_socket_start
    Kgio::wait_writable = :wait_writable
    sock = SubSocket.start(@addr)
    assert_nil sock.foo
    ready = IO.select(nil, [ sock ])
    assert_equal sock, ready[1][0]
    assert_equal nil, sock.kgio_write("HELLO")
  end

  def test_wait_writable_set
    Kgio::wait_writable = :wait_writable
    sock = SubSocket.new(@addr)
    assert_kind_of Kgio::Socket, sock
    assert_instance_of SubSocket, sock
    assert_equal nil, sock.kgio_write("HELLO")
  end
end
