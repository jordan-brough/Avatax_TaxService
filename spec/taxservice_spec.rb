require "spec_helper"

describe "TaxService" do
  before :each do
    credentials = YAML::load(File.open('credentials.yml'))
    @creds = {:username => credentials['username'], 
          :password => credentials['password'],  
          :clientname => credentials['clientname'],
          :use_production_url => credentials['production']}
  end

  describe "does not allow instantiation with" do
    it "no values" do
      lambda { AvaTax::TaxService.new }.should raise_exception
    end
    it "optional values only" do
      lambda { AvaTax::TaxService.new(
      :clientname => @creds[:clientname],
      :adapter => "AvaTaxCalcRuby",
      :machine => "MyComputer",
      :use_production_account => @creds[:use_production_url] ) }.should raise_exception
    end
  end
  describe "allows instantiation with" do
    it "required values only" do
      lambda { AvaTax::TaxService.new(
      :username => @creds[:username], 
      :password => @creds[:password],  
      :clientname => @creds[:clientname]) }.should_not raise_exception
    end
    it "required and optional values" do
      lambda { AvaTax::TaxService.new(
      :username => @creds[:username], 
      :password => @creds[:password],  
      :clientname => @creds[:clientname],
      :adapter => "AvaTaxCalcRuby",
      :machine => "MyComputer",
      :use_production_account => false ) }.should_not raise_exception
    end
  end

end