require_relative '../Avatax_AddressService/lib/avatax_addressservice.rb'
#require 'Avatax_AddressService'

accountNumber = "1234567890"
licenseKey = "A1B2C3D4E5F6G7H8"
useProductionURL = false

# Header Level Parameters
addressSvc = AvaTax::AddressService.new(

# Required Header Parameters
  :username => accountNumber, 
  :password => licenseKey,  
  :use_production_url => useProductionURL,
  :clientname => "AvaTaxSample",

# Optional Header Parameters  
  :name => "Development") 
  
validateRequest = {
  # Required Request Parameters
   :line1 => "118 N Clark St",
   :city => "Chicago",
   :region => "IL",
  # Optional Request Parameters
   :line2 => "Suite 100",
   :line3 => "ATTN Accounts Payable",
   :country => "US",
   :postalcode => "60602",
   :coordinates => true,
   :taxability => true,
   :textcase => "Upper"
}

# Call the service
validateResult = addressSvc.validate(validateRequest)

# Print Results
puts "ValidateAddressTest Result: "+validateResult[:result_code]
if validateResult[:result_code] != "Success"
  validateResult[:messages].each { |message| puts message[:details] }
else
  puts validateResult[:valid_addresses][:valid_address][:line1] + 
  " " + 
  validateResult[:valid_addresses][:valid_address][:city] + 
  ", " + 
  validateResult[:valid_addresses][:valid_address][:region] + 
  " " + 
  validateResult[:valid_addresses][:valid_address][:postal_code]
end