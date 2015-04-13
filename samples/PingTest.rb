require_relative '../Avatax_TaxService/lib/avatax_taxservice.rb'
#require 'Avatax_TaxService'

accountNumber = "1234567890"
licenseKey = "A1B2C3D4E5F6G7H8"
useProductionURL = false

# Header Level Parameters
taxSvc = AvaTax::TaxService.new(

# Required Header Parameters
  :username => accountNumber, 
  :password => licenseKey,  
  :use_production_url => useProductionURL,
  :clientname => "AvaTaxSample",

# Optional Header Parameters  
  :name => "Development") 

pingResult = taxSvc.ping

#Display the result
puts "PingTest ResultCode: " + pingResult[:result_code]
if pingResult[:result_code] != "Success"
  pingResult[:messages].each { |message| puts message[:details] }
end