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
end
