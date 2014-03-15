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

  context "in cluster" do
    test "only node" do
      with_nodes(n: 1) do |ports|
        node = Ruster::Node.new("127.0.0.1:#{ports.first}")

        node.load!

        assert       node.id
        assert_equal [], node.friends
      end
    end

    test "meet and forget node" do
      with_nodes(n: 2) do |ports|
        port_a, port_b = ports.to_a

        # This is the story of two nodes
        node_a = Ruster::Node.new("127.0.0.1:#{port_a}")
        node_b = Ruster::Node.new("127.0.0.1:#{port_b}")

        # One day they met for the first time and fell for each other
        node_a.meet("127.0.0.1", port_b)

        # Give the nodes some time to get to know each other
        sleep 0.5

        node_a.load!
        node_b.load!

        assert_equal 1, node_a.friends.size
        assert_equal 1, node_b.friends.size

        assert_equal node_b.id, node_a.friends.first.id
        assert_equal node_a.id, node_b.friends.first.id

        # But one tragic afternoon, node_b took a terrible decision
        node_b.forget(node_a)

        # Give the nodes some time to process their breakup
        sleep 0.5

        node_a.load!
        node_b.load!

        # node_a still remembers node_b...
        assert_equal 1, node_a.friends.size

        # ...but node_b has already moved on
        assert_equal 0, node_b.friends.size

        # node_a now decides to use the machine from Eternal sunshine of the spotless mind...
        node_a.forget(node_b)

        # ...and after a while, this story ends
        sleep 0.5

        node_a.load!

        assert_equal 0, node_a.friends.size
      end
    end

    test "replicate/slaves" do
      with_nodes(n: 2) do |ports|
        port_a, port_b = ports.to_a

        leo    = Ruster::Node.new("127.0.0.1:#{port_a}")
        django = Ruster::Node.new("127.0.0.1:#{port_b}")

        leo.meet("127.0.0.1", port_b)

        # Give the nodes some time to get to know each other
        sleep 0.5

        leo.load!

        django.replicate(leo)

        # Wait for configuration to update
        sleep 0.5

        assert_equal 1, leo.slaves.size

        django.load!

        assert_equal django.id, leo.slaves.first.id
      end
    end

    test "allocate, deallocate and flush slots" do
      with_nodes(n: 1) do |ports|
        node = Ruster::Node.new("127.0.0.1:#{ports.first}")

        # Single slot
        node.add_slots(1024)

        # Multiple slots
        node.add_slots(2048, 4096)

        node.load!

        assert_equal [1024..1024, 2048..2048, 4096..4096], node.slots

        node.del_slots(1024)

        node.load!

        assert_equal [2048..2048, 4096..4096], node.slots

        node.flush_slots!

        node.load!

        assert_equal [], node.slots
      end
    end
  end
end
