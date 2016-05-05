require File.expand_path '../../test_helper', __dir__

# Test class for Create Subnet Request
class TestCreateSubnet < Minitest::Test
  def setup
    @service = Fog::Network::AzureRM.new(credentials)
    client = @service.instance_variable_get(:@network_client)
    @subnets = client.subnets
    @promise = Concurrent::Promise.execute do
    end
  end

  def test_create_subnet_success
    response = ApiStub::Requests::Network::Subnet.create_subnet_response
    @promise.stub :value!, response do
      @subnets.stub :create_or_update, @promise do
        assert_equal @service.create_subnet('fog-test-rg', 'fog-test-virtual-network', 'fog-test-subnet', '10.1.0.0/24'), response
      end
    end
  end

  def test_create_subnet_argument_error_failure
    response = ApiStub::Requests::Network::Subnet.create_subnet_response
    @promise.stub :value!, response do
      @subnets.stub :create_or_update, @promise do
        assert_raises ArgumentError do
          @service.create_subnet('fog-test-rg', 'fog-test-virtual-network', 'fog-test-subnet')
        end
      end
    end
  end

  def test_create_subnet_exception_failure
    response = -> { fail MsRestAzure::AzureOperationError.new(nil, nil, 'error' => { 'message' => 'mocked exception' }) }
    @promise.stub :value!, response do
      @subnets.stub :create_or_update, @promise do
        assert_raises RuntimeError do
          @service.create_subnet('fog-test-rg', 'fog-test-virtual-network', 'fog-test-subnet', '10.1.0.0/24')
        end
      end
    end
  end
end