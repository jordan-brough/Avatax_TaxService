require 'savon'
require 'erb'
require 'benchmark'

module AvaTax
  #Avalara tax class
  class TaxService
    def initialize(credentials)
      
      #Retrieve gemspec details
      spec = Gem::Specification.find_by_name("Avatax_TaxService")
      #Set @def_locn to the Avatax-x.x.x gem install library. This enables the ruby programs to
      #find other objects that it needs.      
      gem_root = spec.gem_dir
      @def_locn = gem_root + "/lib"    

      #Extract data from hash
      username = credentials[:username]
      password = credentials[:password]
      if username.nil? and password.nil?   
        raise ArgumentError, "username and password are required"
      end
      name = credentials[:name]
      clientname = credentials[:clientname]
      adapter = credentials[:adapter]
      machine = credentials[:machine]
      use_production_account = credentials[:use_production_account]

      #Set credentials and Profile information
      @username = username == nil ? "" : username
      @password = password == nil ? "" : password
      @name = name == nil ? "" : name
      @clientname = (clientname == nil or clientname == "") ? "Avatax SDK for Ruby Default Client Name" : clientname
      @adapter = (adapter == nil or adapter == "") ? spec.summary + spec.version.to_s : adapter
      @machine = machine == nil ? "" : machine
      @use_production_account = (use_production_account != true) ? false : use_production_account


      #Header for response data
      @responsetime_hdr = "  (User)    (System)    (Total)    (Real)"

      #Open Avatax Error Log
      @log = File.new(@def_locn + '/tax_log.txt', "w")

      #Get service details from WSDL - control_array[2] contains the WSDL read from the address_control file
      #log :false turns off HTTP logging. Select either Dev or Prod depending on the value of the boolean value 'use_production_account'
      if @use_production_account
        @log.puts "#{Time.now}: Avalara Production Tax service started"
        @client = Savon.client(wsdl: @def_locn + '/taxservice_prd.wsdl', log: false)
      else
        @log.puts "#{Time.now}: Avalara Development Tax service started"
        @client = Savon.client(wsdl: @def_locn + '/taxservice_dev.wsdl', log: false)        
      end


      #Read in the SOAP template for Get tax
      begin
        @template_gettax = ERB.new(File.read(@def_locn + '/template_gettax.erb'))
      rescue
        @log.puts "#{Time.now}: Error loading the GetTax template"
      end

      #Read in the SOAP template for Adjust tax
      begin
        @template_adjust = ERB.new(File.read(@def_locn + '/template_adjusttax.erb'))
      rescue
        @log.puts "#{Time.now}: Error loading the AdjustTax template"
      end

      #Read in the SOAP template for Ping
      begin
        @template_ping = ERB.new(File.read(@def_locn + '/template_ping.erb'))
      rescue
        @log.puts "#{Time.now}: Error loading the Ping template"
      end

      #Read in the SOAP template for IsAuthorized
      begin
        @template_isauthorized = ERB.new(File.read(@def_locn + '/template_isauthorized.erb'))
      rescue
        @log.puts "#{Time.now}: Error loading the IsAuthorized template"
      end

      #Read in the SOAP template for Tax
      begin
        @template_post = ERB.new(File.read(@def_locn + '/template_posttax.erb'))
      rescue
        @log.puts "#{Time.now}: Error loading the Post template"
      end

      #Read in the SOAP template for Commit tax
      begin
        @template_commit = ERB.new(File.read(@def_locn + '/template_committax.erb'))
      rescue
        @log.puts "#{Time.now}: Error loading the CommitTax template"
      end

      #Read in the SOAP template for Cancel tax
      begin
        @template_cancel = ERB.new(File.read(@def_locn + '/template_canceltax.erb'))
      rescue
        @log.puts "#{Time.now}: Error loading the CancelTax template"
      end

      #Read in the SOAP template for GetTaxHistory tax
      begin
        @template_gettaxhistory = ERB.new(File.read(@def_locn + '/template_gettaxhistory.erb'))
      rescue
        @log.puts "#{Time.now}: Error loading the GetTaxHistory template"
      end

      #Read in the SOAP template for GetTaxHistory tax
      begin
        @template_reconciletaxhistory = ERB.new(File.read(@def_locn + '/template_reconciletaxhistory.erb'))
      rescue
        @log.puts "#{Time.now}: Error loading the ReconcileTaxHistory template"
      end

      # Create hash for validate result
      @response = Hash.new
    end

    ####################################################################################################
    # ping - Verifies connectivity to the web service and returns version information about the service.
    ####################################################################################################
    def ping(message = nil)
  
    @service = 'Ping'
  
    #Read in the SOAP template
    @message = message == nil ? "?" : message

      # Subsitute real vales for template place holders
      @soap = @template_ping.result(binding)
      if @debug
        @log.puts "#{Time.now}: SOAP request created:"
        @log.puts @soap
      end
        
      # Make the call to the Avalara service
      begin
      # Call using debug
        if @debug
          # Use Ruby built in Benchmark function to record response times
          @log.puts "#{Time.now}: Calling #{@service} Service"
          time = Benchmark.measure do
            # Call Ping Service
            @response = @client.call(:ping, xml: @soap).to_hash
          end
          @log.puts "Response times for Ping:"
          @log.puts @responsetime_hdr
          @log.puts time
        else
        # Call Ping Service
          @response = @client.call(:ping, xml: @soap).to_hash
        end
      
      #Strip off outer layer of the hash - not needed
      @response = messages_to_array(@response[:ping_response][:ping_result])
          
      return @response
    
      #Capture unexpected errors
      rescue Savon::Error => error
        abend(error)
      end
    
    end

    ####################################################################################################
    # gettax - Calls the Avatax GetTax Service
    ####################################################################################################
    def gettax(document)
      
      @service = 'GetTax'

      #create instance variables for each entry in input      
      document.each do |k,v|
        instance_variable_set("@#{k}",v)
      end
      #set required default values for missing required inputs
      @doctype ||= "SalesOrder"
      @discount ||= "0"
      @detaillevel ||= "Tax"
      @commit ||= false
      @servicemode ||= "Remote"
      @paymentdate ||= "1900-01-01"
      @exchangerate ||= "0"
      @exchangerateeffdate ||= "1900-01-01"
      @taxoverridetype ||= "None"
      @taxamount ||= "0"
      @taxdate ||= "1900-01-01"
      
      #set required values for some fields
      @hashcode = "0"
      @batchcode = ""

      
      #@addresses
      @addresses.each do |addr|
        addr[:taxregionid] ||= "0"
      end
      #@lines
      @lines.each do |line|
        line[:taxoverridetypeline] ||= "None"
        line[:taxamountline] ||= "0"
        line[:taxdateline] ||= "1900-01-01"
        line[:discounted] ||= false
        line[:taxincluded] ||= false
      end

      # Subsitute template place holders with real values
      @soap = @template_gettax.result(binding)
      # If in debug mode write SOAP request to log
      if @debug
        @log.puts "#{Time.now}: SOAP request created:"
        @log.puts @soap
      end

      # Make the call to the Avalara service
      begin
      # Call using debug
        if @debug
          # Use Ruby built in Benchmark function to record response times
          @log.puts "#{Time.now}: Calling GetTax Service for DocCode: #{@doccode}"
          time = Benchmark.measure do
            # Call GetTax Service
            @response = @client.call(:get_tax, xml: @soap).to_hash
          end
          @log.puts "Response times for GetTax:"
          @log.puts @responsetime_hdr
          @log.puts time
        else
        # Call GetTax Service
          @response = @client.call(:get_tax, xml: @soap).to_hash
        end

      #Strip off outer layer of the hash - not needed
      @response = messages_to_array(@response[:get_tax_response][:get_tax_result])

      #Return data to calling program
      return @response
      
      #Capture unexpected errors
      rescue Savon::Error => error
        abend(error)
      end
    end

    ####################################################################################################
    # adjusttax - Calls the Avatax AdjustTax Service
    ####################################################################################################
    def adjusttax(document)
      
      @service = 'AdjustTax'

      #create instance variables for each entry in input      
      document.each do |k,v|
        instance_variable_set("@#{k}",v)
      end
      #set required default values for missing required inputs
      @doctype ||= "SalesOrder"
      @discount ||= "0"
      @detaillevel ||= "Tax"
      @commit ||= false
      @servicemode ||= "Remote"
      @paymentdate ||= "1900-01-01"
      @exchangerate ||= "0"
      @exchangerateeffdate ||= "1900-01-01"
      @taxoverridetype ||= "None"
      @taxamount ||= "0"
      @taxdate ||= "1900-01-01"
      
      #set required values for some fields
      @hashcode = "0"
      @batchcode = ""

      
      #@addresses
      @addresses.each do |addr|
        addr[:taxregionid] ||= "0"
      end
      #@lines
      @lines.each do |line|
        line[:taxoverridetypeline] ||= "None"
        line[:taxamountline] ||= "0"
        line[:taxdateline] ||= "1900-01-01"
        line[:discounted] ||= false
        line[:taxincluded] ||= false
      end



      # Subsitute template place holders with real values
      @soap = @template_adjust.result(binding)
      if @debug
        @log.puts "#{Time.now}: SOAP request created:"
        @log.puts @soap
      end

      # Make the call to the Avalara service
      begin
      # Call using debug
        if @debug
          # Use Ruby built in Benchmark function to record response times
          @log.puts "#{Time.now}: Calling AdjustTax Service for DocCode: #{@doccode}"
          time = Benchmark.measure do
          # Call AdjustTax Service
            @response = @client.call(:adjust_tax, xml: @soap).to_hash
          end
          @log.puts "Response times for AdjustTax:"
          @log.puts @responsetime_hdr
          @log.puts time
        else
          # Call AdjustTax Service
          @response = @client.call(:adjust_tax, xml: @soap).to_hash
        end

      #Strip off outer layer of the hash - not needed
      return messages_to_array(@response[:adjust_tax_response][:adjust_tax_result])
      
      #Capture unexpected errors
      rescue Savon::Error => error
        abend(error)
      end
      
    end

    ####################################################################################################
    # posttax - Calls the Avatax PostTax Service
    ####################################################################################################
    def posttax(document)
      
      @service = 'PostTax'
      
      #create instance variables for each entry in input      
      document.each do |k,v|
        instance_variable_set("@#{k}",v)
      end
      #set required default values for missing required inputs
      @hashcode = "0"
      
      
      
      # Subsitute template place holders with real values
      @soap = @template_post.result(binding)
      if @debug
        @log.puts "#{Time.now}: SOAP request created:"
        @log.puts @soap
      end

      # Make the call to the Avalara service
      begin
      # Call using debug
        if @debug
          # Use Ruby built in Benchmark function to record response times
          @log.puts "#{Time.now}: Calling PostTax Service for DocCode: #{@doccode}"
          time = Benchmark.measure do
          # Call PostTax Service
            @response = @client.call(:post_tax, xml: @soap).to_hash
          end
          @log.puts "Response times for PostTax:"
          @log.puts @responsetime_hdr
          @log.puts time
        else
          # Call PostTax Service
          @response = @client.call(:post_tax, xml: @soap).to_hash
        end

      #Strip off outer layer of the hash - not needed
      #Return data to calling program
      return messages_to_array(@response[:post_tax_response][:post_tax_result])
      
      #Capture unexpected errors
      rescue Savon::Error => error
        abend(error)
      end
      
    end

    ####################################################################################################
    # committax - Calls the Avatax CommitTax Service
    ####################################################################################################
    def committax(document)
      
      @service = 'CommitTax'
        
      #create instance variables for each entry in input      
      document.each do |k,v|
        instance_variable_set("@#{k}",v)
      end
      #set required default values for missing required inputs
      #no required default values exist for committax

      # Subsitute template place holders with real values
      @soap = @template_commit.result(binding)
      if @debug
        @log.puts "#{Time.now}: SOAP request created:"
        @log.puts @soap
      end

      # Make the call to the Avalara service
      begin
      # Call using debug
        if @debug
          # Use Ruby built in Benchmark function to record response times
          @log.puts "#{Time.now}: Calling CommitTax Service for DocCode: #{@doccode}"
          time = Benchmark.measure do
          # Call CommitTax Service
            @response = @client.call(:commit_tax, xml: @soap).to_hash
          end
          @log.puts "Response times for CommitTax:"
        @log.puts @responsetime_hdr
        @log.puts time
        else
        # Call CommitTax Service
          @response = @client.call(:commit_tax, xml: @soap).to_hash
        end

      #Strip off outer layer of the hash - not needed
      #Return data to calling program
      return messages_to_array(@response[:commit_tax_response][:commit_tax_result])
      
      #Capture unexpected errors
      rescue Savon::Error => error
        abend(error)
      end
    end

    ####################################################################################################
    # canceltax - Calls the Avatax CancelTax Service
    ####################################################################################################
    def canceltax(document)
      
      @service = 'CancelTax'     
      
      #create instance variables for each entry in input      
      document.each do |k,v|
        instance_variable_set("@#{k}",v)
      end
      #set required default values for missing required inputs
      #no required default values exist for canceltax

      # Subsitute template place holders with real values
      @soap = @template_cancel.result(binding)
      if @debug
        @log.puts "#{Time.now}: SOAP request created:"
        @log.puts @soap
      end

      # Make the call to the Avalara service
      begin
      # Call using debug
        if @debug
          # Use Ruby built in Benchmark function to record response times
          @log.puts "#{Time.now}: Calling CancelTax Service for DocCode: #{@doccode}"
          time = Benchmark.measure do
          # Call CancelTax Service
            @response = @client.call(:cancel_tax, xml: @soap).to_hash
          end
          @log.puts "Response times for CancelTax:"
          @log.puts @responsetime_hdr
          @log.puts time
        else
          # Call CancelTax Service
          @response = @client.call(:cancel_tax, xml: @soap).to_hash
        end

      #Strip off outer layer of the hash - not needed
      return messages_to_array(@response[:cancel_tax_response][:cancel_tax_result])

      #Capture unexpected errors
      rescue Savon::Error => error
        abend(error)
      end
    end

    ####################################################################################################
    # gettaxhistory - Calls the Avatax GetTaxHistory Service
    ####################################################################################################
    def gettaxhistory(document)
      
      @service = 'GetTaxHistory'
      
      #create instance variables for each entry in input      
      document.each do |k,v|
        instance_variable_set("@#{k}",v)
      end
      #set required default values for missing required inputs
      @detaillevel ||= "Tax"

      # Subsitute template place holders with real values
      @soap = @template_gettaxhistory.result(binding)
      if @debug
        @log.puts "#{Time.now}: SOAP request created:"
        @log.puts @soap
      end

      # Make the call to the Avalara service
      begin
      # Call using debug
        if @debug
          # Use Ruby built in Benchmark function to record response times
          @log.puts "#{Time.now}: Calling GetTaxHistory Service"
          time = Benchmark.measure do
          # Call GetTaxHistory Service
            @response = @client.call(:get_tax_history, xml: @soap).to_hash
          end
          @log.puts "Response times for GetTaxHistory:"
          @log.puts @responsetime_hdr
          @log.puts time
        else
          # Call GetTaxHistory Service
          @response = @client.call(:get_tax_history, xml: @soap).to_hash
        end
        
      #Strip off outer layer of the hash - not needed
      return messages_to_array(@response[:get_tax_history_response][:get_tax_history_result])

      
      #Capture unexpected errors
      rescue Savon::Error => error
        abend(error)
      end
    end

    ####################################################################################################
    # reconciletaxhistory - Calls the Avatax ReconcileTaxHistory Service
    ####################################################################################################
    def reconciletaxhistory(document)
      
      
      @service = 'ReconcileTaxHistory'      
      
      #create instance variables for each entry in input      
      document.each do |k,v|
        instance_variable_set("@#{k}",v)
      end
      #set required default values for missing required inputs
      @pagesize ||= "100"
      @reconciled ||= false
      @doctype ||= "SalesInvoice"
      @docstatus ||= "Any"
      @lastdoccode ||= ''

           

      # Subsitute template place holders with real values
      @soap = @template_reconciletaxhistory.result(binding)
      if @debug
        @log.puts "#{Time.now}: SOAP request created:"
        @log.puts @soap
      end

      # Make the call to the Avalara service
      begin
      # Call using debug
        if @debug
          # Use Ruby built in Benchmark function to record response times
          @log.puts "#{Time.now}: Calling ReconcileTaxHistory Service"
          time = Benchmark.measure do
          # Call ReconcileTaxHistory Service
            @response = @client.call(:reconcile_tax_history, xml: @soap).to_hash
          end
          @log.puts "Response times for ReconcileTaxHistory:"
        @log.puts @responsetime_hdr
        @log.puts time
        else
        # Call ReconcileTaxHistory Service
          @response = @client.call(:reconcile_tax_history, xml: @soap).to_hash
        end

      #Strip off outer layer of the hash - not needed
      return messages_to_array(@response[:reconcile_tax_history_response][:reconcile_tax_history_result])

      #Capture unexpected errors
      rescue Savon::Error => error
        abend(error)
      end
    end

    ############################################################################################################
    # isauthorized - Verifies connectivity to the web service and returns expiry information about the service.
    ############################################################################################################
    def isauthorized(operation = nil)
      
      @service = 'IsAuthorized'      
      
      #Read in the SOAP template
      @operation = operation == nil ? "?" : operation

      # Subsitute real vales for template place holders
      @soap = @template_isauthorized.result(binding)
      if @debug
        @log.puts "#{Time.now}: SOAP request created:"
        @log.puts @soap
      end

      # Make the call to the Avalara service
      begin
        @response = @client.call(:is_authorized, xml: @soap).to_hash

      #Strip off outer layer of the hash - not needed
      return messages_to_array(@response[:is_authorized_response][:is_authorized_result])
      
      #Capture unexpected errors
      rescue Savon::Error => error
        abend(error)
      end
    end

    private
  
    ############################################################################################################
    # abend - Unexpected error handling
    ############################################################################################################
    def abend(error)
      @log.puts "An unexpected error occurred: Response from server = #{error}"   
      @log.puts "#{Time.now}: Error calling #{@service} service ... check that your account name and password are correct."
      @response = error.to_hash
      @response[:result_code] = 'Error'
      @response[:summary] = @response[:fault][:faultcode]
      @response[:details] = @response[:fault][:faultstring]   
      return messages_to_array(@response)
    end
    ############################################################################################################
    #standardizes error message format to an array of messages - nokogiri will collapse a single element array into the response hash.
    ############################################################################################################
    def messages_to_array(response)
      if not response[:messages].nil? 
        return response
      end
      # add the messages array to the response - if we got here, there was only one error.
      response[:messages] = [{
        :summary => response[:summary],
        :details => response[:details],
        :helplink => response[:helplink],
        :refersto => response[:refersto],
        :severity => response[:severity],
        :source => response[:source]
        }]
      #remove all the error information from the hash  
      response[:messages][0].each do |k,v|
        response.delete(k)
      end  
      return response
    end
  end
end  