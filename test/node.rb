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

  context "information" do
    test "read and parses info line" do
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

      assert_equal "127.0.0.1:12701 [9aee954a0b7d6b49d7e68c18d08873c56aaead6b]", node.to_s
    end

    context "allocated slots" do
      test "contiguous block" do
        info_line = "9aee954a0b7d6b49d7e68c18d08873c56aaead6b :0 myself,master - 0 1 2 connected 0-16383"

        node = Ruster::Node.new("127.0.0.1:12701")

        node.read_info_line!(info_line)

        assert_equal [(0..16383)], node.slots
        assert       node.migrating.empty?
        assert       node.importing.empty?
      end

      test "single" do
        info_line = "9aee954a0b7d6b49d7e68c18d08873c56aaead6b :0 myself,master - 0 1 2 connected 4096"

        node = Ruster::Node.new("127.0.0.1:12701")

        node.read_info_line!(info_line)

        assert_equal [(4096..4096)], node.slots
        assert       node.migrating.empty?
        assert       node.importing.empty?
      end

      test "migrating" do
        info_line = "9aee954a0b7d6b49d7e68c18d08873c56aaead6b :0 myself,master - 0 1 2 connected [16383->-6daeaa65c37880d81c86e7d94b6d7b0a459eea9]"

        node = Ruster::Node.new("127.0.0.1:12701")

        node.read_info_line!(info_line)

        assert_equal [], node.slots
        assert_equal 1, node.migrating.size
        assert_equal "6daeaa65c37880d81c86e7d94b6d7b0a459eea9", node.migrating[16383]
        assert       node.importing.empty?
      end

      test "importing" do
        info_line = "9aee954a0b7d6b49d7e68c18d08873c56aaead6b :0 myself,master - 0 1 2 connected [16383-<-6daeaa65c37880d81c86e7d94b6d7b0a459eea9]"

        node = Ruster::Node.new("127.0.0.1:12701")

        node.read_info_line!(info_line)

        assert_equal [], node.slots
        assert_equal 1, node.importing.size
        assert_equal "6daeaa65c37880d81c86e7d94b6d7b0a459eea9", node.importing[16383]
        assert       node.migrating.empty?
      end

      test "combined" do
        info_line = "9aee954a0b7d6b49d7e68c18d08873c56aaead6b :0 myself,master - 0 1 2 connected 0-1024 2048 [3072->-6daeaa65c37880d81c86e7d94b6d7b0a459eea9] 4096 [6144-<-6daeaa65c37880d81c86e7d94b6d7b0a459eea9] 8192-16383"

        node = Ruster::Node.new("127.0.0.1:12701")

        node.read_info_line!(info_line)

        assert_equal [(0..1024), (2048..2048), (4096..4096), (8192..16383)], node.slots

        assert_equal 1, node.migrating.size
        assert_equal "6daeaa65c37880d81c86e7d94b6d7b0a459eea9", node.migrating[3072]

        assert_equal 1, node.importing.size
        assert_equal "6daeaa65c37880d81c86e7d94b6d7b0a459eea9", node.importing[6144]
      end

      test "all allocated slots as an array" do
        info_line = "9aee954a0b7d6b49d7e68c18d08873c56aaead6b :0 myself,master - 0 1 2 connected 0-3 5 10-13 16383"

        node = Ruster::Node.new("127.0.0.1:12701")

        node.read_info_line!(info_line)

        assert_equal [0, 1, 2, 3, 5, 10, 11, 12, 13, 16383], node.all_slots
      end
    end

    test "create from info line" do
      info_line = "9aee954a0b7d6b49d7e68c18d08873c56aaead6b 127.0.0.1:12701 master - 0 1 2 connected"

      node = Ruster::Node.from_info_line(info_line)

      assert_equal "9aee954a0b7d6b49d7e68c18d08873c56aaead6b", node.id
      assert_equal "127.0.0.1:12701", node.addr
      assert_equal ["master"], node.flags
      assert_equal "-", node.master_id
      assert_equal 0, node.ping_epoch
      assert_equal 1, node.pong_epoch
      assert_equal 2, node.config_epoch
      assert_equal "connected", node.state
      assert_equal [], node.slots

      assert_equal "127.0.0.1:12701 [9aee954a0b7d6b49d7e68c18d08873c56aaead6b]", node.to_s
    end
  end
end
