require "spec_helper"

describe "Ping" do
  before :each do
    credentials = YAML::load(File.open('credentials.yml'))
    @creds = {:username => credentials['username'], 
          :password => credentials['password'],  
          :clientname => credentials['clientname'],
          :use_production_url => credentials['production']}
  end
  
  describe "returns a meaningful" do
    it "error when URL is missing" do
      @creds[:use_production_url] = nil
      @service = AvaTax::TaxService.new(@creds)
      @service.ping[:result_code].should eql "Success"
    end
    it "success when URL is specified" do
      @creds[:use_production_url] = false
      @service = AvaTax::TaxService.new(@creds)
      @service.ping[:result_code].should eql "Success"
    end
    it "error when username is missing" do
      @creds[:username] = nil
      @service = AvaTax::TaxService.new(@creds)
      @service.ping[:result_code].should eql "Error"
    end
    it "error when password is omitted" do
      @creds[:password] = nil
      @service = AvaTax::TaxService.new(@creds)
      @service.ping[:result_code].should eql "Error"
    end
    it "success when clientname is omitted" do
      @creds[:clientname] = nil
      @service = AvaTax::TaxService.new(@creds)
      @service.ping[:result_code].should eql "Success"
    end      
  end
  
  describe "has consistent formatting for" do
    it "internal logic errors" do
      @service = AvaTax::TaxService.new(@creds)
      lambda { @service.ping("param1","param2") }.should raise_exception
    end
    it "server-side errors" do
      @creds[:password] = nil
      @service = AvaTax::TaxService.new(@creds)
      @result = @service.ping
      @result[:result_code].should eql "Error"
      @result[:messages][:message].should be_a Array
      @result[:messages][:message][0].should include(:details => "The user or account could not be authenticated.")
    end
    it "successful results" do
      @service = AvaTax::TaxService.new(@creds)
      @result = @service.ping
      @result[:result_code].should eql "Success" and @result[:version].should_not be_nil
    end
  end  
  describe "requests with" do
    it "missing required parameters fail" do
      true #there are no required parameters for ping
    end
    it "invalid parameters fail" do
      @service = AvaTax::TaxService.new(@creds)
      lambda { @service.ping("param1","param2") }.should raise_exception
    end
    it "missing optional parameters succeed" do
      @service = AvaTax::TaxService.new(@creds)
      @service.ping[:result_code].should eql "Success"
    end
    it "all parameters succeed" do
      @service = AvaTax::TaxService.new(@creds)
      @service.ping("Message")[:result_code].should eql "Success"
    end
  end
  
end