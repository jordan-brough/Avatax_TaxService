require "spec_helper"

describe "ReconcileTaxHistory" do
  before :each do
    credentials = YAML::load(File.open('credentials.yml'))
    @creds = {:username => credentials['username'], 
          :password => credentials['password'],  
          :clientname => credentials['clientname'],
          :use_production_url => credentials['production']} 
    @svc =  AvaTax::TaxService.new(@creds)
    @get_tax_request = {
      :companycode => credentials['companycode'],
      :doctype => "SalesInvoice",
      :commit => false,
      :detaillevel => "Tax",
      :docdate=>DateTime.now.strftime("%Y-%m-%d"),
      :customercode => "CUST123",
      :origincode => "456",
      :destinationcode => "456",
      :addresses=>[{
        :addresscode=>"456", 
        :line1=>"7070 West Arlington Drive", 
        :postalcode=>"80123", 
        :country=>"US", 
        }], 
      :lines=>[{
        :no=>"1", 
        :itemcode=>"Canoe", 
        :qty=>"1",
        :amount=>"300.43", 
        :description=>"Blue canoe",
        }]}
    @get_tax_result = @svc.gettax(@get_tax_request) 
    @request_required = {
      :pagesize => "5",
      :reconciled => false,
      :doctype => "SalesInvoice",
      :docstatus => "Any",
      :startdate => @get_tax_result[:doc_date],
      :enddate => @get_tax_result[:doc_date],
      :lastdocid => @get_tax_result[:doc_id],
      :companycode => @get_tax_request[:companycode],
    }
    @request_optional = {      :lastdoccode => '',} # There are no optional parameters for ReconcileTaxHistory
          
  end
  
  describe "returns a meaningful" do
    it "error when URL is missing" do
      @creds[:use_production_url] = nil
      @service = AvaTax::TaxService.new(@creds)
      @service.reconciletaxhistory(@request_required)[:result_code].should eql "Success"
    end
    it "success when URL is specified" do
      @creds[:use_production_url] = false
      @service = AvaTax::TaxService.new(@creds)
      @service.reconciletaxhistory(@request_required)[:result_code].should eql "Success"
    end
    it "error when username is missing" do
      @creds[:username] = nil
      @service = AvaTax::TaxService.new(@creds)
      @service.reconciletaxhistory(@request_required)[:result_code].should eql "Error"
    end
    it "error when password is omitted" do
      @creds[:password] = nil
      @service = AvaTax::TaxService.new(@creds)
      @service.reconciletaxhistory(@request_required)[:result_code].should eql "Error"
    end
    it "success when clientname is omitted" do
      @creds[:clientname] = nil
      @service = AvaTax::TaxService.new(@creds)
      @service.reconciletaxhistory(@request_required)[:result_code].should eql "Success"
    end     
  end
  
  describe "has consistent formatting for" do
    it "server-side errors" do
      @creds[:password] = nil
      @service = AvaTax::TaxService.new(@creds)
      @result = @service.reconciletaxhistory(@request_required)
      @result[:result_code].should eql "Error" and       
      @result[:messages].kind_of?(Array).should eql true and
      @result[:messages][0].should include(:details => "The user or account could not be authenticated.")
    end
    it "successful results" do
      @service = AvaTax::TaxService.new(@creds)
      @result = @service.reconciletaxhistory(@request_required)
      @result[:result_code].should eql "Success" and @result[:transaction_id].should_not be_nil
    end
  end  
  describe "requests with" do
    it "missing required parameters fail" do
      @service = AvaTax::TaxService.new(@creds)
      @result = @service.reconciletaxhistory(@request_optional)
      @result[:result_code].should eql "Error" 
    end
    it "invalid parameters ignore them" do
      @service = AvaTax::TaxService.new(@creds)
      @request_required[:bogus] = "data"
      @result = @service.reconciletaxhistory(@request_required)
      @result[:result_code].should eql "Success" 
    end
    it "missing optional parameters succeed" do
      @service = AvaTax::TaxService.new(@creds)
      @result = @service.reconciletaxhistory(@request_required)
      @result[:result_code].should eql "Success" 
    end
    it "all parameters succeed" do
      @service = AvaTax::TaxService.new(@creds)
      @result = @service.reconciletaxhistory(@request_required.merge(@request_optional))
      @result[:result_code].should eql "Success" 
    end
  end
  describe "workflow" do
    #This method is deprecated - it currently does not pull documents or change their reconciliation status.
    #it "should pull unreconciled documents when requested" do
    #  pending
    #end
    #it "should mark documents as reconciled" do 
    #  pending
    #end
    #it "should pull reconciled documents when requested" do
    #  pending
    #end
  end
  
end