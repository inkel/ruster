require_relative "./helper"

Protest.describe "Node" do
  test "is cluster enabled" do
    with_nodes(n: 1) do |ports|
      node = Ruster::Node.new("127.0.0.1:#{ports.first}")

      assert node.enabled?
    end
  end

  test "is not cluster enabled" do
    with_nodes(n: 1, enabled: "no") do |ports|
      node = Ruster::Node.new("127.0.0.1:#{ports.first}")

      assert !node.enabled?
    end
  end

  context "info" do
    test "#read_info_line!" do
      info_line = "9aee954a0b7d6b49d7e68c18d08873c56aaead6b :0 myself,master - 0 1 2 connected"

      node = Ruster::Node.new("127.0.0.1:12701")

      node.read_info_line!(info_line)

      assert_equal "9aee954a0b7d6b49d7e68c18d08873c56aaead6b", node.id
      assert_equal "127.0.0.1:12701", node.addr
      assert_equal ["myself", "master"], node.flags
      assert_equal "-", node.master_id
      assert_equal 0, node.ping_epoch
      assert_equal 1, node.pong_epoch
      assert_equal 2, node.config_epoch
      assert_equal "connected", node.state
      assert_equal [], node.slots
    end
  end
end
